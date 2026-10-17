import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/mvvm/view_model_state.dart';
import '../view_models/journal_view_model.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/finance_widgets.dart';
import 'habit_check_in.dart';
import 'journal_sheets.dart';

import '../models/journal_models.dart';

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

  Future<void> _check(PersonalNote note, int index, bool done) async {
    if (await model.checkNote(note, index, done)) {
      HapticFeedback.selectionClick();
    } else if (mounted) {
      showFailure(context, model.error ?? 'No se pudo actualizar la lista.');
    }
  }

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
                    for (final note in _notes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: LedgerPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    note.kind == 'list'
                                        ? Icons.checklist_rounded
                                        : Icons.edit_note_rounded,
                                    color: KwallTheme.accent,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      note.title,
                                      style: KwallTheme.fontTitle.copyWith(
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: 'Acciones de la nota',
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        _editNote(note);
                                      } else {
                                        final removed = await model.deleteNote(
                                          note,
                                        );
                                        if (!mounted) return;
                                        if (!removed) {
                                          showFailure(
                                            context,
                                            model.error ??
                                                'No se pudo eliminar la nota.',
                                          );
                                        }
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Editar'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (note.body.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    note.body,
                                    maxLines: 8,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              for (var i = 0; i < note.items.length; i++)
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  title: Text(
                                    note.items[i].text,
                                    style: TextStyle(
                                      decoration: note.items[i].done
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  value: note.items[i].done,
                                  onChanged: model.busy
                                      ? null
                                      : (value) => _check(note, i, value!),
                                ),
                              if (note.kind == 'list' && note.items.isNotEmpty)
                                Text(
                                  '${note.items.where((item) => item.done).length}/${note.items.length} completados',
                                  style: TextStyle(
                                    color: KwallTheme.textSecondary,
                                  ),
                                ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => _editNote(note),
                                  child: const Text('Abrir'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ] else ...[
                    _dayPicker(),
                    const SizedBox(height: 16),
                    if (_habits.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Text('Tu primer hábito empieza aquí.'),
                      ),
                    HabitDaySummary(
                      habits: _habits,
                      day: _day,
                      settings: _settings,
                      reward: _xp,
                    ),
                    const SizedBox(height: 12),
                    for (final habit in _habits)
                      HabitCard(
                        key: ValueKey(habit.id),
                        habit: habit,
                        day: _day,
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
}
