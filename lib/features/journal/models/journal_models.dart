import 'dart:convert';
import 'package:flutter/material.dart';

String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class NoteItem {
  final String text;
  final bool done;
  final DateTime? dueDate;
  const NoteItem(this.text, {this.done = false, this.dueDate});
  Map<String, Object?> toMap() => {
    'text': text,
    'done': done,
    if (dueDate != null) 'due_date': dayKey(dueDate!),
  };
}

class PersonalNote {
  final String id;
  final String title;
  final String body;
  final String kind;
  final List<NoteItem> items;
  final String iconKey;
  final int colorValue;
  final DateTime updatedAt;
  const PersonalNote({
    required this.id,
    required this.title,
    this.body = '',
    this.kind = 'note',
    this.items = const [],
    this.iconKey = 'note',
    this.colorValue = 0,
    required this.updatedAt,
  });
  Map<String, Object> toMap() => {
    'id': id,
    'title': title,
    'body': body,
    'kind': kind,
    'items': jsonEncode(items.map((e) => e.toMap()).toList()),
    'icon_key': iconKey,
    'color_value': colorValue,
    'updated_at': updatedAt.toIso8601String(),
  };
  factory PersonalNote.fromMap(Map<String, Object?> map) => PersonalNote(
    id: map['id'] as String,
    title: map['title'] as String,
    body: (map['body'] as String?) ?? '',
    kind: (map['kind'] as String?) ?? 'note',
    iconKey: (map['icon_key'] as String?) ?? 'note',
    colorValue: (map['color_value'] as int?) ?? 0,
    updatedAt: DateTime.parse(map['updated_at'] as String),
    items: (jsonDecode((map['items'] as String?) ?? '[]') as List).map((e) {
      final item = e as Map<String, dynamic>;
      final due = item['due_date'] as String?;
      return NoteItem(
        item['text'] as String,
        done: item['done'] as bool,
        dueDate: due != null && due.isNotEmpty ? DateTime.tryParse(due) : null,
      );
    }).toList(),
  );
}

IconData getNoteIcon(String? key) => switch (key) {
  'list' => Icons.checklist_rounded,
  'idea' => Icons.lightbulb_outline_rounded,
  'work' => Icons.work_outline_rounded,
  'study' => Icons.school_outlined,
  'personal' => Icons.person_outline_rounded,
  'star' => Icons.star_outline_rounded,
  'heart' => Icons.favorite_border_rounded,
  'shopping' => Icons.shopping_cart_outlined,
  'book' => Icons.menu_book_rounded,
  'note' || _ => Icons.edit_note_rounded,
};

const noteIcons = [
  ('note', Icons.edit_note_rounded, 'Nota'),
  ('list', Icons.checklist_rounded, 'Lista'),
  ('idea', Icons.lightbulb_outline_rounded, 'Idea'),
  ('work', Icons.work_outline_rounded, 'Trabajo'),
  ('study', Icons.school_outlined, 'Estudio'),
  ('personal', Icons.person_outline_rounded, 'Personal'),
  ('star', Icons.star_outline_rounded, 'Destacado'),
  ('heart', Icons.favorite_border_rounded, 'Favorito'),
  ('shopping', Icons.shopping_cart_outlined, 'Compras'),
  ('book', Icons.menu_book_rounded, 'Lectura'),
];

const noteColors = [
  (0, 'Predeterminado'),
  (0xFF10B981, 'Verde'),
  (0xFF3B82F6, 'Azul'),
  (0xFF8B5CF6, 'Púrpura'),
  (0xFFEC4899, 'Rosa'),
  (0xFFF59E0B, 'Ámbar'),
  (0xFFEF4444, 'Rojo'),
  (0xFF14B8A6, 'Turquesa'),
  (0xFF6366F1, 'Índigo'),
];

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
    category: 'Salud y Naturaleza',
    icons: [
      ('spa_rounded', 'Salud'),
      ('directions_run_rounded', 'Ejercicio'),
      ('fitness_center_rounded', 'Gimnasio'),
      ('self_improvement_rounded', 'Meditación'),
      ('water_drop_rounded', 'Agua'),
      ('bedtime_rounded', 'Descanso'),
    ],
    colors: [
      (0xFF466539, 'Bosque profundo'),
      (0xFF5F854F, 'Verde oliva'),
      (0xFF7EA86C, 'Salvia viva'),
      (0xFFB2D39C, 'Brote claro'),
    ],
  ),
  HabitPalette(
    category: 'Productividad y Mente',
    icons: [
      ('book_rounded', 'Lectura'),
      ('laptop_chromebook_rounded', 'Trabajo'),
      ('menu_book_rounded', 'Estudio'),
      ('alarm_rounded', 'Puntualidad'),
      ('code_rounded', 'Programar'),
      ('school_rounded', 'Aprendizaje'),
    ],
    colors: [
      (0xFF735085, 'Ciruela intenso'),
      (0xFF8E66A3, 'Mora silvestre'),
      (0xFFA980BE, 'Amatista suave'),
      (0xFFD9B7ED, 'Lila empolvado'),
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
      ('mic_rounded', 'Canto y Voz'),
    ],
    colors: [
      (0xFFA14665, 'Palo de rosa'),
      (0xFFBD5E7F, 'Terracota cálido'),
      (0xFFD77B9B, 'Rosa arcilla'),
      (0xFFF1B3C7, 'Rosa amanecer'),
    ],
  ),
  HabitPalette(
    category: 'Energía y Finanzas',
    icons: [
      ('local_fire_department_rounded', 'Racha y Energía'),
      ('savings_rounded', 'Ahorro'),
      ('bolt_rounded', 'Vitalidad'),
      ('emoji_events_rounded', 'Logros'),
      ('coffee_rounded', 'Café matutino'),
      ('eco_rounded', 'Naturaleza'),
    ],
    colors: [
      (0xFF806015, 'Miel profunda'),
      (0xFF9E771E, 'Ámbar tostado'),
      (0xFFBE932D, 'Oro cálido'),
      (0xFFE9CB81, 'Mostaza dorada'),
    ],
  ),
  HabitPalette(
    category: 'Equilibrio y Calma',
    icons: [
      ('spa_rounded', 'Armonía'),
      ('check_circle_rounded', 'Constancia'),
      ('favorite_rounded', 'Cuidado'),
      ('psychology_rounded', 'Reflexión'),
      ('wb_sunny_rounded', 'Despertar'),
      ('nights_stay_rounded', 'Rutina noche'),
    ],
    colors: [
      (0xFF3D4B3F, 'Pizarra bosque'),
      (0xFF555E50, 'Musgo neutro'),
      (0xFF758572, 'Salvia terrosa'),
      (0xFF8D9C8F, 'Verde ceniza'),
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
  final String timeBlock;
  final List<HabitLog> logs;

  const Habit({
    required this.id,
    required this.title,
    this.iconKey = 'spa_rounded',
    this.colorValue = 0xFF4CAF50,
    this.timeBlock = 'anytime',
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
