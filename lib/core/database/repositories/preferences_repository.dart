import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database_context.dart';

mixin PreferencesRepository on DatabaseContext {
  Future<String> getCurrency() async {
    final db = await database;
    final res = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['currency'],
      limit: 1,
    );
    if (res.isNotEmpty) {
      return res.first['value'] as String;
    }
    return '\$';
  }

  Future<void> setCurrency(String newCurrency) async {
    final db = await database;
    await db.insert('app_settings', {
      'key': 'currency',
      'value': newCurrency,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    notifyChanged();
  }

  Future<Map<String, String>> getSettings() async {
    final db = await database;
    final rows = await db.query('app_settings');
    return {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
  }

  Future<void> saveSettings(Map<String, String> values) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final entry in values.entries) {
        await txn.insert('app_settings', {
          'key': entry.key,
          'value': entry.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    notifyChanged();
  }

  Future<Map<String, dynamic>> getKittyProfile() async {
    final db = await database;
    final maps = await db.query(
      'kitty_profile',
      where: 'id = ?',
      whereArgs: ['main_kitty'],
    );
    if (maps.isNotEmpty) {
      return Map<String, dynamic>.from(maps.first);
    }
    return {
      'id': 'main_kitty',
      'name': 'Mishi',
      'level': 1,
      'exp': 45,
      'mood': 'happy',
      'happiness': 85,
      'coat_color': 'orange',
      'personality': 'curious',
    };
  }

  Future<void> updateKittyConfig({
    String? name,
    String? coatColor,
    String? personality,
  }) async {
    final db = await database;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (coatColor != null) updates['coat_color'] = coatColor;
    if (personality != null) updates['personality'] = personality;

    if (updates.isNotEmpty) {
      await db.update(
        'kitty_profile',
        updates,
        where: 'id = ?',
        whereArgs: ['main_kitty'],
      );
      notifyChanged();
    }
  }

  Future<void> updateKittyMood(
    String mood, {
    int? happinessDelta,
    int? expDelta,
  }) async {
    final db = await database;
    final profile = await getKittyProfile();
    int currentHappiness = (profile['happiness'] as int?) ?? 85;
    int currentExp = (profile['exp'] as int?) ?? 45;
    int currentLevel = (profile['level'] as int?) ?? 1;

    if (happinessDelta != null) {
      currentHappiness = (currentHappiness + happinessDelta).clamp(0, 100);
    }
    if (expDelta != null) {
      currentExp += expDelta;
      if (currentExp >= 100) {
        currentLevel += currentExp ~/ 100;
        currentExp = currentExp % 100;
      }
    }

    await db.update(
      'kitty_profile',
      {
        'mood': mood,
        'happiness': currentHappiness,
        'exp': currentExp,
        'level': currentLevel,
        'last_interacted': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: ['main_kitty'],
    );
    notifyChanged();
  }
}
