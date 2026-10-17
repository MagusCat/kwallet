import 'package:uuid/uuid.dart';
import '../currency_snapshot.dart';
import '../../models/currency_conversion.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../database_context.dart';
import 'currency_rates_repository.dart';

mixin PreferencesRepository on DatabaseContext {
  Future<String?> getGitHubToken() async {
    final db = await database;
    final legacy = await db.query('app_settings', where: 'key = ?', whereArgs: ['github_token']);
    if (legacy.isNotEmpty) {
      final token = legacy.first['value'] as String;
      if (token.isNotEmpty) {
        await credentials.write(token);
        if (await credentials.read() != token) throw StateError('No se pudo proteger la credencial');
      }
      await db.transaction((txn) async {
        await txn.delete('app_settings', where: 'key = ?', whereArgs: ['github_token']);
        await txn.insert('app_settings', {'key': 'github_connected', 'value': token.isNotEmpty ? 'true' : 'false'}, conflictAlgorithm: ConflictAlgorithm.replace);
      });
      return token.isEmpty ? null : token;
    }
    return credentials.read();
  }

  Future<void> saveGitHubToken(String? token) async {
    await credentials.write(token);
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('app_settings', where: 'key = ?', whereArgs: ['github_token']);
      await txn.insert('app_settings', {'key': 'github_connected', 'value': token != null && token.isNotEmpty ? 'true' : 'false'}, conflictAlgorithm: ConflictAlgorithm.replace);
    });
    notifyChanged();
  }

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
    final legacy = await db.query('app_settings', where: 'key = ?', whereArgs: ['github_token']);
    if (legacy.isNotEmpty) await getGitHubToken();
    final rows = await db.query('app_settings', where: 'key != ?', whereArgs: ['github_token']);
    return {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
  }

  Future<void> saveSettings(Map<String, String> values) async {
    if (values.containsKey('github_token')) throw ArgumentError('Usa almacenamiento seguro');
    final db = await database;
    await db.transaction((txn) async {
      if (values.containsKey('currency')) {
        final snapshot = await CurrencySnapshot.read(txn);
        final next = values['currency']!;
        if (CurrencyConversion.code(next) != CurrencyConversion.code(snapshot.base)) {
          final hasAccounts = (await txn.query('accounts', limit: 1)).isNotEmpty;
          final factor = !hasAccounts && snapshot.rates.isEmpty ? 1.0 : snapshot.convert(1, snapshot.base, next);
          final rates = {...snapshot.rates, snapshot.base: 1.0};
          await txn.delete('global_currency_rates');
          for (final entry in rates.entries) {
            if (CurrencyConversion.code(entry.key) == CurrencyConversion.code(next)) continue;
            await txn.insert('global_currency_history', {'id': const Uuid().v4(), 'currency': CurrencyConversion.code(entry.key), 'base_currency': next, 'previous_rate': entry.value, 'new_rate': entry.value * factor, 'notes': 'Cambio de moneda principal', 'created_at': DateTime.now().toIso8601String()});
            await txn.insert('global_currency_rates', {'currency': CurrencyConversion.code(entry.key), 'rate': entry.value * factor, 'updated_at': DateTime.now().toIso8601String()}, conflictAlgorithm: ConflictAlgorithm.replace);
          }
          await txn.rawUpdate('UPDATE budgets SET monthly_limit = monthly_limit * ?, weekly_limit = weekly_limit * ?, daily_limit = daily_limit * ?', [factor, factor, factor]);
          await txn.rawUpdate('UPDATE budget_allocations SET amount = amount * ?', [factor]);
          await txn.rawUpdate('UPDATE planned_expenses SET amount = amount * ? WHERE account_id IS NULL', [factor]);
        }
      }
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

  Future<Map<String, double>> getCurrencyRates() async {
    final db = await database;
    return CurrencyRatesRepository(db).getRates();
  }

  Future<void> setCurrencyRate({
    required String currency,
    required double rate,
    String notes = '',
  }) async {
    final db = await database;
    await CurrencyRatesRepository(db).setRate(
      currency: currency,
      rate: rate,
      notes: notes,
    );
    notifyChanged();
  }

  Future<void> removeCurrencyRate(String currency) async {
    final db = await database;
    await CurrencyRatesRepository(db).removeRate(currency);
    notifyChanged();
  }

  Future<List<Map<String, dynamic>>> getCurrencyRateHistory({String? currency}) async {
    final db = await database;
    return CurrencyRatesRepository(db).getHistory(currency: currency);
  }
}
