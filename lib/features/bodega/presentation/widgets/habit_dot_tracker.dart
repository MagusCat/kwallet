import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../../journal/models/journal_models.dart';
import '../../view_models/home_view_model.dart';

class HabitDotTracker extends StatefulWidget {
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
  State<HabitDotTracker> createState() => _HabitDotTrackerState();
}

class _HabitDotTrackerState extends State<HabitDotTracker> {
  bool _isMonthly = false;

  @override
  Widget build(BuildContext context) {
    final habits = widget.controller.habits;
    final today = DateTime.now();
    final completedCount = widget.controller.completedHabitsToday;
    final totalCount = widget.controller.totalHabitsToday;

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
              if (habits.isNotEmpty) ...[
                // Switcher Semanal / Mensual
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: KwallTheme.surfaceContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModeButton('Semana', !_isMonthly, () {
                        if (_isMonthly) setState(() => _isMonthly = false);
                      }),
                      _buildModeButton('Mes', _isMonthly, () {
                        if (!_isMonthly) setState(() => _isMonthly = true);
                      }),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                IconButton.filledTonal(
                  tooltip: 'Nuevo hábito',
                  onPressed: widget.onAddHabit,
                  icon: const Icon(Icons.add_rounded, size: 20),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (habits.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: OutlinedButton.icon(
                onPressed: widget.onAddHabit,
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
                onPressed: widget.onOpenHabits,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text('Ver todos (${habits.length} hábitos)'),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeButton(String label, bool active, VoidCallback onTap) =>
      InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active ? KwallTheme.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              color: active ? Colors.white : KwallTheme.textSecondary,
            ),
          ),
        ),
      );

  Widget _buildHabitRow(BuildContext context, Habit habit, DateTime today) {
    final streak = habit.streak(today);
    final isDoneToday = habit.logFor(today)?.completed == true;
    final habitColor = habit.color;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KwallTheme.surfaceContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDoneToday
              ? habitColor.withValues(alpha: 0.45)
              : KwallTheme.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: habitColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(habit.icon, size: 16, color: habitColor),
              ),
              const SizedBox(width: 8),
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
                    color: habitColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: habitColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$streak ${streak == 1 ? "día" : "días"}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: habitColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _isMonthly
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: _buildWeeklyDots(context, habit, today, habitColor),
            secondChild: _buildMonthlyDots(context, habit, today, habitColor),
          ),
        ],
      ),
    );
  }

  // Vista Semanal: 7 días con círculos grandes interactivos
  Widget _buildWeeklyDots(
    BuildContext context,
    Habit habit,
    DateTime today,
    Color habitColor,
  ) {
    final days = List.generate(7, (i) => today.subtract(Duration(days: 6 - i)));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final day in days)
          _buildDayDot(context, habit, day, today, habitColor),
      ],
    );
  }

  Widget _buildDayDot(
    BuildContext context,
    Habit habit,
    DateTime day,
    DateTime today,
    Color habitColor,
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
            color: isToday ? habitColor : KwallTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isToday && !isDone
              ? () {
                  HapticFeedback.lightImpact();
                  widget.controller.completeHabit(habit);
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
                    ? habitColor
                    : (isToday
                        ? habitColor.withValues(alpha: 0.15)
                        : KwallTheme.border.withValues(alpha: 0.2)),
                border: Border.all(
                  color: isToday
                      ? habitColor
                      : (isDone ? habitColor : Colors.transparent),
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
                            color: habitColor,
                          )
                        : const SizedBox.shrink()),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Vista Mensual: cuadrícula compacta de los últimos 28 días (4 semanas exactas)
  Widget _buildMonthlyDots(
    BuildContext context,
    Habit habit,
    DateTime today,
    Color habitColor,
  ) {
    const totalDays = 28;
    final days = List.generate(
      totalDays,
      (i) => today.subtract(Duration(days: totalDays - 1 - i)),
    );
    final completedCount = days.where((d) => habit.logFor(d)?.completed == true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cuadrícula 7 columnas x 4 filas
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.2,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final isToday = DateUtils.isSameDay(day, today);
            final log = habit.logFor(day);
            final isDone = log?.completed == true;

            return Tooltip(
              message: '${DateFormat('d MMM', 'es').format(day)}: ${isDone ? "Completado" : "Sin registro"}',
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: isToday && !isDone
                    ? () {
                        HapticFeedback.lightImpact();
                        widget.controller.completeHabit(habit);
                      }
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isDone
                        ? habitColor
                        : (isToday
                            ? habitColor.withValues(alpha: 0.2)
                            : KwallTheme.border.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(6),
                    border: isToday
                        ? Border.all(color: habitColor, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isDone
                            ? Colors.white
                            : (isToday ? habitColor : KwallTheme.textSecondary),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$completedCount de $totalDays días activos',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: habitColor,
              ),
            ),
            Text(
              '${(completedCount / totalDays * 100).round()}% constancia',
              style: TextStyle(
                fontSize: 11,
                color: KwallTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
