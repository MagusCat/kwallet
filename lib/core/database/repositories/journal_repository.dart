import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../features/bodega/models/finance_overview.dart';
import '../../../features/journal/models/journal_models.dart';
import '../reward_events.dart';
import '../database_context.dart';

mixin JournalRepository on DatabaseContext {
  Future<int> getExperience() async {
    final db = await database;
    return ((await db.rawQuery(
              'SELECT SUM(points) AS total FROM reward_events',
            )).first['total']
            as int?) ??
        0;
  }

  Future<void> awardAffection(int points) async {
    if (points <= 0) return;
    final db = await database;
    final now = DateTime.now();
    final key = 'affection:${now.millisecondsSinceEpoch}';
    await RewardEvents.award(db, key, points);
    notifyChanged();
  }

  Future<List<PersonalNote>> getNotes() async {
    final db = await database;
    return (await db.query(
      'personal_notes',
      orderBy: 'updated_at DESC',
    )).map(PersonalNote.fromMap).toList();
  }

  Future<void> saveNote(PersonalNote note) async {
    if (note.title.trim().isEmpty) throw ArgumentError('Escribe un título');
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'personal_notes',
        note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (note.kind == 'list' &&
          note.items.isNotEmpty &&
          note.items.every((i) => i.done)) {
        await RewardEvents.award(txn, 'note:${note.id}', 5);
      }
    });
    notifyChanged();
  }

  Future<void> setNoteItem(
    String noteId,
    int index,
    bool done, {
    required String expectedText,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'personal_notes',
        where: 'id = ?',
        whereArgs: [noteId],
      );
      if (rows.isEmpty) throw StateError('Esta lista ya no existe');
      final note = PersonalNote.fromMap(rows.single);
      if (index < 0 ||
          index >= note.items.length ||
          note.items[index].text != expectedText) {
        throw StateError('La lista cambió. Vuelve a abrirla');
      }
      final items = [...note.items];
      items[index] = NoteItem(items[index].text, done: done);
      final updated = PersonalNote(
        id: note.id,
        title: note.title,
        body: note.body,
        kind: note.kind,
        items: items,
        updatedAt: DateTime.now(),
      );
      await txn.update(
        'personal_notes',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [noteId],
      );
      if (items.isNotEmpty && items.every((item) => item.done)) {
        await RewardEvents.award(txn, 'note:$noteId', 5);
      }
    });
    notifyChanged();
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete('personal_notes', where: 'id = ?', whereArgs: [id]);
    notifyChanged();
  }

  Future<List<Habit>> getHabits() async {
    final db = await database;
    final habits = await db.query('habits', orderBy: 'created_at ASC');
    final logs = await db.query('habit_logs', orderBy: 'day DESC');
    final byHabit = <String, List<HabitLog>>{};
    for (final log in logs) {
      (byHabit[log['habit_id'] as String] ??= []).add(HabitLog.fromMap(log));
    }
    return habits
        .map(
          (habit) => Habit(
            id: habit['id'] as String,
            title: habit['title'] as String,
            iconKey: (habit['icon_key'] as String?) ?? 'spa_rounded',
            colorValue: (habit['color_value'] as int?) ?? 0xFF4CAF50,
            logs: byHabit[habit['id']] ?? const [],
          ),
        )
        .toList();
  }

  Future<void> saveHabit(
    String id,
    String title, {
    String iconKey = 'spa_rounded',
    int colorValue = 0xFF4CAF50,
  }) async {
    if (title.trim().isEmpty) throw ArgumentError('Escribe un hábito');
    final db = await database;
    final changed = await db.update(
      'habits',
      {
        'title': title.trim(),
        'icon_key': iconKey,
        'color_value': colorValue,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    if (changed == 0) {
      await db.insert('habits', {
        'id': id,
        'title': title.trim(),
        'icon_key': iconKey,
        'color_value': colorValue,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
    notifyChanged();
  }

  Future<void> deleteHabit(String id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('habit_logs', where: 'habit_id = ?', whereArgs: [id]);
      await txn.delete('habits', where: 'id = ?', whereArgs: [id]);
    });
    notifyChanged();
  }

  Future<void> logHabit(
    String habitId,
    DateTime date, {
    required bool completed,
    String mood = 'neutral',
    String reason = '',
  }) => logHabitDays(
    [habitId],
    [date],
    completed: completed,
    mood: mood,
    reason: reason,
  );

  Future<void> logHabitDays(
    Iterable<String> habitIds,
    Iterable<DateTime> dates, {
    required bool completed,
    String mood = 'neutral',
    String reason = '',
  }) async {
    if (!['happy', 'neutral', 'tired', 'sad', 'stressed'].contains(mood)) {
      throw ArgumentError('Ánimo inválido');
    }
    final today = dateOnly(DateTime.now());
    final ids = habitIds.toSet();
    final days = dates.map(dateOnly).toSet();
    if (ids.isEmpty || days.isEmpty) {
      throw ArgumentError('Elige al menos un hábito y un día');
    }
    if (days.any((day) => day.isAfter(today))) {
      throw ArgumentError('No se puede marcar un día futuro');
    }
    final db = await database;
    await db.transaction((txn) async {
      for (final id in ids) {
        if ((await txn.query(
          'habits',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [id],
        )).isEmpty) {
          throw StateError('Este hábito ya no existe');
        }
        for (final date in days) {
          final day = dayKey(date);
          await txn.insert('habit_logs', {
            'id': '$id:$day',
            'habit_id': id,
            'day': day,
            'completed': completed ? 1 : 0,
            'mood': mood,
            'reason': reason.trim(),
          }, conflictAlgorithm: ConflictAlgorithm.replace);
          if (completed) await RewardEvents.award(txn, 'habit:$id:$day', 10);
        }
      }
    });
    notifyChanged();
  }
}
