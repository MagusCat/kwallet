import 'package:uuid/uuid.dart';

import '../../../core/contracts/app_repositories.dart';
import '../../../core/mvvm/view_model.dart';
import '../models/journal_models.dart';

class JournalActionsViewModel extends ViewModel {
  final JournalRepository repository;
  JournalActionsViewModel(this.repository);

  Future<bool> saveHabit(
    String title, {
    Habit? habit,
    String iconKey = 'spa_rounded',
    int colorValue = 0xFF4CAF50,
  }) {
    if (title.trim().isEmpty) return Future.value(fail('Escribe un hábito.'));
    return perform(
      () => repository.saveHabit(
        habit?.id ?? const Uuid().v4(),
        title.trim(),
        iconKey: iconKey,
        colorValue: colorValue,
      ),
    );
  }

  Future<bool> deleteHabit(Habit habit) =>
      perform(() => repository.deleteHabit(habit.id));
  Future<bool> deleteNote(PersonalNote note) =>
      perform(() => repository.deleteNote(note.id));
  Future<bool> checkNote(PersonalNote note, int index, bool done) => perform(
    () => repository.setNoteItem(
      note.id,
      index,
      done,
      expectedText: note.items[index].text,
    ),
  );
  Future<bool> saveNote({
    PersonalNote? original,
    required String title,
    required String body,
    required String kind,
    required Iterable<NoteItem> items,
  }) {
    if (title.trim().isEmpty) return Future.value(fail('Ponle un título.'));
    final note = PersonalNote(
      id: original?.id ?? const Uuid().v4(),
      title: title.trim(),
      body: body.trim(),
      kind: kind,
      items: kind == 'list'
          ? items
                .where((i) => i.text.trim().isNotEmpty)
                .map((i) => NoteItem(i.text.trim(), done: i.done))
                .toList()
          : [],
      updatedAt: DateTime.now(),
    );
    return perform(() => repository.saveNote(note));
  }

  Future<bool> markDays(
    Iterable<String> ids,
    Iterable<DateTime> dates, {
    required bool completed,
    String mood = 'neutral',
    String reason = '',
  }) => perform(
    () => repository.logHabitDays(
      ids,
      dates,
      completed: completed,
      mood: mood,
      reason: reason,
    ),
  );
  Future<bool> completeHabit(Habit habit, DateTime date) =>
      markDays([habit.id], [date], completed: true, mood: 'happy');
  Future<bool> completePending(List<Habit> habits, DateTime day) => markDays(
    habits.where((h) => h.logFor(day) == null).map((h) => h.id),
    [day],
    completed: true,
    mood: 'happy',
  );
}
