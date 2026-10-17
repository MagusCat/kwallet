import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/mvvm/view_model_state.dart';
import '../view_models/journal_actions_view_model.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/finance_widgets.dart';
import '../models/journal_models.dart';
import 'journal_sheets.dart';

import 'habit_actions.dart';
import 'habit_days_sheet.dart';

class HabitCard extends StatefulWidget {
  final Habit habit;
  final DateTime day;
  final VoidCallback? onEdit;
  final bool compact;
  final bool hideStreak;
  const HabitCard({
    super.key,
    required this.habit,
    required this.day,
    this.onEdit,
    this.compact = false,
    this.hideStreak = false,
  });
  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState
    extends ViewModelState<HabitCard, JournalActionsViewModel> {
  @override
  JournalActionsViewModel createViewModel(AppDependencies dependencies) =>
      dependencies.journalActions();
  bool get _busy => model.busy;
  Future<void> _complete() async {
    if (await model.completeHabit(widget.habit, widget.day)) {
      HapticFeedback.lightImpact();
    } else if (mounted) {
      showFailure(context, model.error ?? 'No se pudo marcar el hábito.');
    }
  }

  void _days() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => HabitDaysSheet(habit: widget.habit, initialDay: widget.day),
  );
  void _missed() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => MoodSheet(habit: widget.habit, day: widget.day),
  );

  @override
  Widget build(BuildContext context) {
    final log = widget.habit.logFor(widget.day);
    final done = log?.completed == true;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LedgerPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Semantics(
                  checked: done,
                  label: 'Marcar ${widget.habit.title}',
                  child: IconButton.filledTonal(
                    tooltip: done ? 'Completado' : 'Marcar como hecho',
                    onPressed: _busy || done ? null : _complete,
                    icon: AnimatedSwitcher(
                      duration: Duration(milliseconds: reduced ? 0 : 180),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: _busy
                          ? const SizedBox.square(
                              key: ValueKey('busy'),
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              done
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              key: ValueKey(done),
                              color: KwallTheme.accent,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habit.title,
                        style: KwallTheme.fontTitle.copyWith(fontSize: 17),
                      ),
                      if (!widget.hideStreak) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.local_fire_department_outlined,
                              size: 16,
                              color: KwallTheme.accent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.habit.streak(widget.day)} días',
                              style: TextStyle(color: KwallTheme.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Opciones de ${widget.habit.title}',
                  onSelected: (value) async {
                    if (value == 'days') {
                      _days();
                    } else if (value == 'edit') {
                      if (widget.onEdit != null) {
                        widget.onEdit!();
                      } else {
                        editHabit(context, habit: widget.habit);
                      }
                    } else {
                      final remove = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('¿Eliminar hábito?'),
                          content: const Text(
                            'También se borrarán sus días registrados.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancelar'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Eliminar'),
                            ),
                          ],
                        ),
                      );
                      if (remove == true) {
                        if (!await model.deleteHabit(widget.habit) &&
                            context.mounted) {
                          showFailure(
                            context,
                            model.error ?? 'No se pudo eliminar el hábito.',
                          );
                        }
                      }
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'days',
                      child: Text('Marcar varios días'),
                    ),
                    PopupMenuItem(value: 'edit', child: Text('Editar')),
                    PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                  ],
                ),
              ],
            ),
            if (!widget.compact || log?.completed != true)
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: _busy ? null : _missed,
                    icon: const Icon(
                      Icons.sentiment_neutral_outlined,
                      size: 18,
                    ),
                    label: const Text('No pude'),
                  ),
                  TextButton.icon(
                    onPressed: _busy ? null : _days,
                    icon: const Icon(Icons.date_range_outlined, size: 18),
                    label: const Text('Varios días'),
                  ),
                ],
              ),
            if (log != null && !done)
              Text(
                '${moodLabels[log.mood] ?? 'Neutral'}${log.reason.isEmpty ? '' : ' · ${log.reason}'}',
                style: TextStyle(color: KwallTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
