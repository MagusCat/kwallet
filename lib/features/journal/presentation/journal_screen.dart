import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/mvvm/view_model_state.dart';
import '../view_models/journal_view_model.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/finance_widgets.dart';
import 'habit_check_in.dart';
import 'journal_sheets.dart';

import '../models/journal_models.dart';
import '../../../core/widgets/pet_cameo_empty_state.dart';
import 'widgets/habit_time_block_filter.dart';

export 'journal_sheets.dart' show NoteSheet;

class JournalScreen extends StatefulWidget {
  final int initialTab;
  final VoidCallback? onSettings;
  const JournalScreen({
    super.key,
    this.initialTab = 0,
    this.onSettings,
  });
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState
    extends ViewModelState<JournalScreen, JournalViewModel> {
  @override
  JournalViewModel createViewModel(AppDependencies dependencies) =>
      dependencies.journalScreen();
  List<PersonalNote> get _notes => model.notes;
  List<Habit> get _habits => model.habits;
  Map<String, String> get _settings => model.settings;
  int get _xp => model.xp;
  late int _tab = widget.initialTab;
  String _activeTimeBlock = 'all';
  DateTime? _selectedDay;
  DateTime get _day => _selectedDay ?? DateTime.now();
  void _selectDay(DateTime date) => setState(
    () =>
        _selectedDay = DateUtils.isSameDay(date, DateTime.now()) ? null : date,
  );
  bool get _loading => model.loading;
  String? get _error => model.error;
  Future<void> _load() => model.load();
  void _editNote([PersonalNote? note]) => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => NoteSheet(note: note),
  );
  Future<void> _habit([Habit? habit]) => editHabit(context, habit: habit);

  @override
  Widget build(BuildContext _) {
    Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi espacio'),
        actions: [
          if (widget.onSettings != null)
            IconButton(
              tooltip: 'Ajustes',
              icon: const Icon(Icons.tune_rounded),
              onPressed: widget.onSettings,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ContentWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                children: [
                  SegmentedButton<int>(
            showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('Notas'),
                        icon: Icon(Icons.sticky_note_2_outlined),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('Hábitos'),
                        icon: Icon(Icons.local_fire_department_outlined),
                      ),
                    ],
                    selected: {_tab},
                    onSelectionChanged: (value) =>
                        setState(() => _tab = value.first),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    TextButton(onPressed: _load, child: Text(_error!)),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _tab == 0 ? 'Mis notas' : 'Mis hábitos',
                          style: KwallTheme.fontTitle.copyWith(fontSize: 20),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: _tab == 0
                            ? 'Nueva nota o lista'
                            : 'Nuevo hábito',
                        onPressed: () {
                          if (_tab == 0) {
                            _editNote();
                          } else {
                            _habit();
                          }
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  if (_tab == 0) ...[
                    if (_notes.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Text('Una idea, una lista, lo que necesites.'),
                      ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = (constraints.maxWidth - 10) / 2;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final note in _notes)
                              SizedBox(
                                width: itemWidth,
                                child: _buildCompactNoteCard(note),
                              ),
                          ],
                        );
                      },
                    ),
                  ] else ...[
                    _dayPicker(),
                    const SizedBox(height: 16),
                    if (_habits.isEmpty)
                      const PetCameoEmptyState(
                        label: 'Tu primer hábito empieza aquí.',
                        iconBadge: Icons.auto_awesome_rounded,
                      ),
                    HabitDaySummary(
                      habits: _habits,
                      day: _day,
                      settings: _settings,
                      reward: _xp,
                    ),
                    if (_habits.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      HabitTimeBlockFilter(
                        activeBlock: _activeTimeBlock,
                        onChanged: (block) => setState(() => _activeTimeBlock = block),
                      ),
                    ],
                    const SizedBox(height: 12),
                    for (final habit in HabitTimeBlockFilter.filter(_habits, _activeTimeBlock))
                      HabitCard(
                        key: ValueKey(habit.id),
                        habit: habit,
                        day: _day,
                        hideStreak: _settings['disable_streaks'] == 'true',
                        onEdit: () => _habit(habit),
                      ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _dayPicker() => Column(
    children: [
      TextButton.icon(
        icon: const Icon(Icons.event_outlined),
        label: Text(DateFormat('EEE d MMM y', 'es').format(_day)),
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _day,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (date != null && mounted) _selectDay(date);
        },
      ),
      Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Builder(
                builder: (_) {
                  final day = DateTime(
                    _day.year,
                    _day.month,
                    _day.day - _day.weekday + 1 + i,
                  );
                  final future = DateUtils.dateOnly(day)
                      .isAfter(DateUtils.dateOnly(DateTime.now()));
                  final selected = dayKey(day) == dayKey(_day);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Material(
                      color: selected
                          ? KwallTheme.accent
                          : KwallTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: future ? null : () => _selectDay(day),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            children: [
                              Text(
                                DateFormat('EE', 'es').format(day),
                                style: TextStyle(
                                  color: selected
                                      ? KwallTheme.onAccent
                                      : KwallTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: selected
                                      ? KwallTheme.onAccent
                                      : future
                                      ? KwallTheme.textSecondary.withValues(
                                          alpha: .45,
                                        )
                                      : KwallTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    ],
  );

  Widget _buildCompactNoteCard(PersonalNote note) {
    final noteColor =
        note.colorValue != 0 ? Color(note.colorValue) : KwallTheme.accent;
    final bgTint = note.colorValue != 0
        ? noteColor.withValues(alpha: 0.08)
        : KwallTheme.surface;
    final borderTint = note.colorValue != 0
        ? noteColor.withValues(alpha: 0.35)
        : KwallTheme.border.withValues(alpha: 0.65);

    return Material(
      color: bgTint,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: borderTint,
          width: note.colorValue != 0 ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _editNote(note),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: noteColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      getNoteIcon(note.iconKey),
                      color: noteColor,
                      size: 16,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    iconSize: 18,
                    tooltip: 'Acciones',
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _editNote(note);
                      } else {
                        final removed = await model.deleteNote(note);
                        if (!mounted) return;
                        if (!removed) {
                          showFailure(
                            context,
                            model.error ?? 'No se pudo eliminar la nota.',
                          );
                        }
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                note.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (note.body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  note.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: KwallTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
              if (note.kind == 'list' && note.items.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 13,
                      color: noteColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${note.items.where((i) => i.done).length}/${note.items.length} hechas',
                        style: TextStyle(
                          fontSize: 11,
                          color: KwallTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Text(
                DateFormat('d MMM', 'es').format(note.updatedAt),
                style: TextStyle(
                  fontSize: 10,
                  color: KwallTheme.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
