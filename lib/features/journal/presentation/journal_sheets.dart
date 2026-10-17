import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/mvvm/view_model_state.dart';
import '../view_models/journal_actions_view_model.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/finance_widgets.dart';
import '../models/journal_models.dart';
import 'widgets/habit_time_block_selector.dart';

class NoteSheet extends StatefulWidget {
  final PersonalNote? note;
  final String? initialKind;
  const NoteSheet({super.key, this.note, this.initialKind});
  @override
  State<NoteSheet> createState() => _NoteSheetState();
}

class _EditableItem {
  final TextEditingController text;
  bool done;
  DateTime? dueDate;
  _EditableItem(String value, this.done, {this.dueDate})
    : text = TextEditingController(text: value);
}

class _NoteSheetState
    extends ViewModelState<NoteSheet, JournalActionsViewModel> {
  @override
  JournalActionsViewModel createViewModel(AppDependencies dependencies) =>
      dependencies.journalActions();
  late final _title = TextEditingController(text: widget.note?.title ?? '');
  late final _body = TextEditingController(text: widget.note?.body ?? '');
  late String _kind = widget.note?.kind ?? widget.initialKind ?? 'note';
  late final _items = [
    for (final item in widget.note?.items ?? <NoteItem>[])
      _EditableItem(item.text, item.done, dueDate: item.dueDate),
  ];
  final _removed = <_EditableItem>[];
  bool get _saving => model.busy;
  String? get _error => model.error;
  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    for (final item in [..._items, ..._removed]) {
      item.text.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await model.saveNote(
      original: widget.note,
      title: _title.text,
      body: _body.text,
      kind: _kind,
      items: _items.map(
        (item) => NoteItem(
          item.text.text,
          done: item.done,
          dueDate: item.dueDate,
        ),
      ),
    );
    if (saved && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => SheetBody(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Un espacio para ti',
          style: KwallTheme.fontTitle.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'note',
              label: Text('Nota libre'),
              icon: Icon(Icons.edit_note),
            ),
            ButtonSegment(
              value: 'list',
              label: Text('Lista'),
              icon: Icon(Icons.checklist),
            ),
          ],
          selected: {_kind},
          onSelectionChanged: (value) => setState(() {
            _kind = value.first;
            if (_kind == 'list' && _items.isEmpty) {
              _items.add(_EditableItem('', false));
            }
          }),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Título'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _body,
          minLines: 3,
          maxLines: 8,
          decoration: const InputDecoration(
            labelText: 'Lo que quieras escribir',
          ),
        ),
        if (_kind == 'list') ...[
          const SizedBox(height: 14),
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: item.done,
                    onChanged: (value) => setState(() => item.done = value!),
                  ),
                  Expanded(
                    child: TextField(
                      controller: item.text,
                      decoration: const InputDecoration(
                        hintText: 'Un pendiente…',
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: item.dueDate == null
                        ? 'Fecha límite'
                        : DateFormat('d MMM', 'es').format(item.dueDate!),
                    icon: Icon(
                      Icons.event_outlined,
                      size: 20,
                      color: item.dueDate == null
                          ? KwallTheme.textSecondary
                          : KwallTheme.accent,
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: item.dueDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => item.dueDate = picked);
                      }
                    },
                  ),
                  IconButton(
                    tooltip: 'Quitar pendiente',
                    onPressed: () => setState(() {
                      _items.remove(item);
                      _removed.add(item);
                    }),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          TextButton.icon(
            onPressed: () =>
                setState(() => _items.add(_EditableItem('', false))),
            icon: const Icon(Icons.add),
            label: const Text('Otro pendiente'),
          ),
        ],
        if (_error != null)
          Text(_error!, style: TextStyle(color: KwallTheme.expenseRed)),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.check),
          label: Text(_saving ? 'Guardando…' : 'Guardar'),
        ),
      ],
    ),
  );
}

class HabitSheet extends StatefulWidget {
  final String initial;
  final Habit? habit;
  const HabitSheet({super.key, required this.initial, this.habit});
  @override
  State<HabitSheet> createState() => _HabitSheetState();
}

class _HabitSheetState
    extends ViewModelState<HabitSheet, JournalActionsViewModel> {
  @override
  JournalActionsViewModel createViewModel(AppDependencies dependencies) =>
      dependencies.journalActions();
  late final _title = TextEditingController(text: widget.initial);
  late String _iconKey = widget.habit?.iconKey ?? 'spa_rounded';
  late int _colorValue = widget.habit?.colorValue ?? 0xFF4CAF50;
  late String _timeBlock = widget.habit?.timeBlock ?? 'anytime';
  int _selectedCategoryIndex = 0;

  @override
  void initState() {
    super.initState();
    // Match initial category if editing
    for (var i = 0; i < habitPalettes.length; i++) {
      if (habitPalettes[i].icons.any((ic) => ic.$1 == _iconKey) ||
          habitPalettes[i].colors.any((c) => c.$1 == _colorValue)) {
        _selectedCategoryIndex = i;
        break;
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPalette = habitPalettes[_selectedCategoryIndex];
    return SheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Color(_colorValue).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(_colorValue), width: 2),
                ),
                child: Icon(
                  getHabitIcon(_iconKey),
                  color: Color(_colorValue),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.habit == null ? 'Nuevo hábito' : 'Editar hábito',
                  style: KwallTheme.fontTitle.copyWith(fontSize: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: '¿Qué quieres hacer cada día?',
              hintText: 'Caminar 15 minutos',
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Temática y estilo',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: KwallTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < habitPalettes.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(habitPalettes[i].category),
                      selected: _selectedCategoryIndex == i,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedCategoryIndex = i;
                            _iconKey = habitPalettes[i].icons.first.$1;
                            _colorValue = habitPalettes[i].colors.first.$1;
                          });
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (iconKey, label) in currentPalette.icons)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _iconKey = iconKey),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _iconKey == iconKey
                          ? Color(_colorValue).withValues(alpha: 0.2)
                          : KwallTheme.surfaceContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _iconKey == iconKey
                            ? Color(_colorValue)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Tooltip(
                      message: label,
                      child: Icon(
                        getHabitIcon(iconKey),
                        color: _iconKey == iconKey
                            ? Color(_colorValue)
                            : KwallTheme.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final (colorVal, name) in currentPalette.colors)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _colorValue = colorVal),
                    child: Tooltip(
                      message: name,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(colorVal),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _colorValue == colorVal
                                ? Colors.white
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: _colorValue == colorVal
                              ? [
                                  BoxShadow(
                                    color:
                                        Color(colorVal).withValues(alpha: 0.5),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                        child: _colorValue == colorVal
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          HabitTimeBlockSelector(
            selected: _timeBlock,
            onChanged: (val) => setState(() => _timeBlock = val),
          ),
          if (model.error != null) ...[
            const SizedBox(height: 8),
            Text(model.error!, style: TextStyle(color: KwallTheme.expenseRed)),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: model.busy
                ? null
                : () async {
                    final saved = await model.saveHabit(
                      _title.text,
                      habit: widget.habit,
                      iconKey: _iconKey,
                      colorValue: _colorValue,
                      timeBlock: _timeBlock,
                    );
                    if (saved && context.mounted) Navigator.pop(context, true);
                  },
            child: const Text('Guardar hábito'),
          ),
        ],
      ),
    );
  }
}

const moodLabels = {
  'happy': 'Bien',
  'neutral': 'Neutral',
  'tired': 'Con cansancio',
  'sad': 'Triste',
  'stressed': 'Con estrés',
};
const moodIcons = {
  'happy': Icons.sentiment_satisfied_alt,
  'neutral': Icons.sentiment_neutral,
  'tired': Icons.bedtime_outlined,
  'sad': Icons.sentiment_dissatisfied,
  'stressed': Icons.bolt_outlined,
};

class MoodSheet extends StatefulWidget {
  final Habit habit;
  final DateTime day;
  const MoodSheet({super.key, required this.habit, required this.day});
  @override
  State<MoodSheet> createState() => _MoodSheetState();
}

class _MoodSheetState
    extends ViewModelState<MoodSheet, JournalActionsViewModel> {
  @override
  JournalActionsViewModel createViewModel(AppDependencies dependencies) =>
      dependencies.journalActions();
  late final _reason = TextEditingController(
    text: widget.habit.logFor(widget.day)?.reason ?? '',
  );
  late String _mood = widget.habit.logFor(widget.day)?.mood ?? 'neutral';
  bool get _saving => model.busy;
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SheetBody(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Cada día cuenta',
          style: KwallTheme.fontTitle.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.habit.title} · ${DateFormat('d MMM y', 'es').format(widget.day)}',
        ),
        const SizedBox(height: 18),
        const Text('¿Cómo te sientes?'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in moodLabels.entries)
              ChoiceChip(
                avatar: Icon(moodIcons[entry.key], size: 18),
                label: Text(entry.value),
                selected: _mood == entry.key,
                onSelected: (_) => setState(() => _mood = entry.key),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _reason,
          minLines: 2,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: '¿Qué se te hizo difícil? (opcional)',
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _saving
              ? null
              : () async {
                  final saved = await model.markDays(
                    [widget.habit.id],
                    [widget.day],
                    completed: false,
                    mood: _mood,
                    reason: _reason.text,
                  );
                  if (!context.mounted) return;
                  if (saved) {
                    Navigator.pop(context, true);
                  } else {
                    showFailure(
                      context,
                      model.error ?? 'No se pudo guardar cómo te fue.',
                    );
                  }
                },
          child: Text(_saving ? 'Guardando…' : 'Guardar cómo me fue'),
        ),
      ],
    ),
  );
}
