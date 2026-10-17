import 'dart:convert';

String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class NoteItem {
  final String text;
  final bool done;
  const NoteItem(this.text, {this.done = false});
  Map<String, Object> toMap() => {'text': text, 'done': done};
}

class PersonalNote {
  final String id;
  final String title;
  final String body;
  final String kind;
  final List<NoteItem> items;
  final DateTime updatedAt;
  const PersonalNote({
    required this.id,
    required this.title,
    this.body = '',
    this.kind = 'note',
    this.items = const [],
    required this.updatedAt,
  });
  Map<String, Object> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'kind': kind,
    'items': jsonEncode(items.map((e) => e.toMap()).toList()),
    'updated_at': updatedAt.toIso8601String(),
  };
  factory PersonalNote.fromMap(Map<String, Object?> map) => PersonalNote(
    id: map['id'] as String,
    title: map['title'] as String,
    body: map['body'] as String,
    kind: map['kind'] as String,
    updatedAt: DateTime.parse(map['updated_at'] as String),
    items: (jsonDecode(map['items'] as String) as List)
        .map((e) => NoteItem(e['text'] as String, done: e['done'] as bool))
        .toList(),
  );
}

class HabitLog {
  final String day;
  final bool completed;
  final String mood;
  final String reason;
  const HabitLog({
    required this.day,
    required this.completed,
    this.mood = 'neutral',
    this.reason = '',
  });
  factory HabitLog.fromMap(Map<String, Object?> map) => HabitLog(
    day: map['day'] as String,
    completed: map['completed'] == 1,
    mood: map['mood'] as String,
    reason: map['reason'] as String,
  );
}

class Habit {
  final String id;
  final String title;
  final List<HabitLog> logs;
  const Habit({required this.id, required this.title, this.logs = const []});
  HabitLog? logFor(DateTime date) =>
      logs.where((l) => l.day == dayKey(date)).firstOrNull;
  int streak(DateTime date) {
    var cursor = DateTime.utc(date.year, date.month, date.day);
    final completed = {
      for (final log in logs.where((l) => l.completed)) log.day,
    };
    if (!completed.contains(dayKey(cursor))) {
      if (logFor(date) != null) return 0;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (completed.contains(dayKey(cursor))) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return count;
  }
}
