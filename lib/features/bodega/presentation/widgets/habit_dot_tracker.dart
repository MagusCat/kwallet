import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../../journal/models/journal_models.dart';
import '../../view_models/home_view_model.dart';

class HabitDotTracker extends StatelessWidget {
  final HomeViewModel controller;
  final VoidCallback onAddHabit;
  final VoidCallback onOpenHabits;

  const HabitDotTracker({
    super.key,
    required this.controller,
    required this.onAddHabit,
    required this.onOpenHabits,
  });

  @override
  Widget build(BuildContext context) {
    final habits = controller.habits;
    final today = DateTime.now();
    final completedCount = controller.completedHabitsToday;
    final totalCount = controller.totalHabitsToday;

    return LedgerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: KwallTheme.accentLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: KwallTheme.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hábitos diarios',
                      style: KwallTheme.fontTitle.copyWith(fontSize: 18),
                    ),
                    Text(
                      totalCount == 0
                          ? 'Crea tu primera rutina diaria'
                          : '$completedCount de $totalCount completados hoy',
                      style: TextStyle(
                        fontSize: 12,
                        color: KwallTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (habits.isNotEmpty)
                IconButton.filledTonal(
                  tooltip: 'Nuevo hábito',
                  onPressed: onAddHabit,
                  icon: const Icon(Icons.add_rounded, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (habits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: OutlinedButton.icon(
                onPressed: onAddHabit,
                icon: const Icon(Icons.add_task_rounded),
                label: const Text('Comenzar un hábito (+10 XP)'),
              ),
            )
          else ...[
            for (final habit in habits.take(3)) ...[
              _buildHabitRow(context, habit, today),
              const SizedBox(height: 14),
            ],
            if (habits.length > 3)
              TextButton.icon(
                onPressed: onOpenHabits,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text('Ver todos (${habits.length} hábitos)'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildHabitRow(BuildContext context, Habit habit, DateTime today) {
    final streak = habit.streak(today);
    final isDoneToday = habit.logFor(today)?.completed == true;

    // Last 7 days ending today
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KwallTheme.surfaceContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDoneToday
              ? KwallTheme.accent.withValues(alpha: 0.3)
              : KwallTheme.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  habit.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: KwallTheme.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: KwallTheme.accent,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$streak ${streak == 1 ? "día" : "días"}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: KwallTheme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Gráfico de puntos de los últimos 7 días
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in days) _buildDayDot(context, habit, day, today),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayDot(
    BuildContext context,
    Habit habit,
    DateTime day,
    DateTime today,
  ) {
    final isToday = DateUtils.isSameDay(day, today);
    final log = habit.logFor(day);
    final isDone = log?.completed == true;
    final dayLabel = DateFormat('E', 'es').format(day).substring(0, 1).toUpperCase();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          dayLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
            color: isToday ? KwallTheme.accent : KwallTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isToday && !isDone
              ? () {
                  HapticFeedback.lightImpact();
                  controller.completeHabit(habit);
                }
              : null,
          child: Tooltip(
            message: isToday
                ? (isDone ? 'Completado hoy' : 'Toca para marcar hoy')
                : (isDone ? 'Completado' : 'Sin registro'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isToday ? 32 : 24,
              height: isToday ? 32 : 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? KwallTheme.accent
                    : (isToday
                        ? KwallTheme.accentLight
                        : KwallTheme.border.withValues(alpha: 0.2)),
                border: Border.all(
                  color: isToday
                      ? KwallTheme.accent
                      : (isDone ? KwallTheme.accent : Colors.transparent),
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : (isToday
                        ? Icon(
                            Icons.touch_app_rounded,
                            size: 14,
                            color: KwallTheme.accent,
                          )
                        : const SizedBox.shrink()),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
