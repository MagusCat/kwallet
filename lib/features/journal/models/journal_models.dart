import 'dart:convert';
import 'package:flutter/material.dart';

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

class HabitPalette {
  final String category;
  final List<(String, String)> icons;
  final List<(int, String)> colors;

  const HabitPalette({
    required this.category,
    required this.icons,
    required this.colors,
  });
}

const habitPalettes = [
  HabitPalette(
    category: 'Salud y Bienestar',
    icons: [
      ('spa_rounded', 'Salud'),
      ('directions_run_rounded', 'Ejercicio'),
      ('fitness_center_rounded', 'Gimnasio'),
      ('self_improvement_rounded', 'Meditación'),
      ('water_drop_rounded', 'Agua'),
      ('bedtime_rounded', 'Descanso'),
    ],
    colors: [
      (0xFF4CAF50, 'Verde Hoja'),
      (0xFF10B981, 'Esmeralda'),
      (0xFF059669, 'Menta'),
      (0xFF84CC16, 'Lima'),
    ],
  ),
  HabitPalette(
    category: 'Productividad y Estudio',
    icons: [
      ('book_rounded', 'Lectura'),
      ('laptop_chromebook_rounded', 'Trabajo'),
      ('menu_book_rounded', 'Estudio'),
      ('alarm_rounded', 'Puntualidad'),
      ('code_rounded', 'Programar'),
      ('school_rounded', 'Aprendizaje'),
    ],
    colors: [
      (0xFF3B82F6, 'Azul Eléctrico'),
      (0xFF06B6D4, 'Cian Océano'),
      (0xFF6366F1, 'Índigo'),
      (0xFF0284C7, 'Celeste Cielo'),
    ],
  ),
  HabitPalette(
    category: 'Creatividad y Pasión',
    icons: [
      ('palette_rounded', 'Arte'),
      ('music_note_rounded', 'Música'),
      ('camera_alt_rounded', 'Fotografía'),
      ('brush_rounded', 'Dibujo'),
      ('draw_rounded', 'Escritura'),
      ('mic_rounded', 'Canto / Voz'),
    ],
    colors: [
      (0xFF8B5CF6, 'Violeta'),
      (0xFFEC4899, 'Rosa Vivo'),
      (0xFFD946EF, 'Fucsia'),
      (0xFFA855F7, 'Lavanda'),
    ],
  ),
  HabitPalette(
    category: 'Energía y Finanzas',
    icons: [
      ('local_fire_department_rounded', 'Racha / Energía'),
      ('savings_rounded', 'Ahorro'),
      ('bolt_rounded', 'Vitalidad'),
      ('emoji_events_rounded', 'Logros'),
      ('coffee_rounded', 'Café / Mañana'),
      ('eco_rounded', 'Naturaleza'),
    ],
    colors: [
      (0xFFF59E0B, 'Ámbar'),
      (0xFFF97316, 'Naranja Cálido'),
      (0xFFEF4444, 'Rojo Pasión'),
      (0xFFEAB308, 'Oro Solar'),
    ],
  ),
];

IconData getHabitIcon(String? key) {
  return switch (key) {
    'spa_rounded' || 'spa_outlined' => Icons.spa_rounded,
    'directions_run_rounded' => Icons.directions_run_rounded,
    'fitness_center_rounded' => Icons.fitness_center_rounded,
    'self_improvement_rounded' => Icons.self_improvement_rounded,
    'water_drop_rounded' => Icons.water_drop_rounded,
    'bedtime_rounded' => Icons.bedtime_rounded,
    'book_rounded' => Icons.book_rounded,
    'laptop_chromebook_rounded' => Icons.laptop_chromebook_rounded,
    'menu_book_rounded' => Icons.menu_book_rounded,
    'alarm_rounded' => Icons.alarm_rounded,
    'code_rounded' => Icons.code_rounded,
    'school_rounded' => Icons.school_rounded,
    'palette_rounded' => Icons.palette_rounded,
    'music_note_rounded' => Icons.music_note_rounded,
    'camera_alt_rounded' => Icons.camera_alt_rounded,
    'brush_rounded' => Icons.brush_rounded,
    'draw_rounded' => Icons.draw_rounded,
    'mic_rounded' => Icons.mic_rounded,
    'local_fire_department_rounded' => Icons.local_fire_department_rounded,
    'savings_rounded' => Icons.savings_rounded,
    'bolt_rounded' => Icons.bolt_rounded,
    'emoji_events_rounded' => Icons.emoji_events_rounded,
    'coffee_rounded' => Icons.coffee_rounded,
    'eco_rounded' => Icons.eco_rounded,
    _ => Icons.spa_rounded,
  };
}

class Habit {
  final String id;
  final String title;
  final String iconKey;
  final int colorValue;
  final List<HabitLog> logs;

  const Habit({
    required this.id,
    required this.title,
    this.iconKey = 'spa_rounded',
    this.colorValue = 0xFF4CAF50,
    this.logs = const [],
  });

  IconData get icon => getHabitIcon(iconKey);
  Color get color => Color(colorValue);

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
