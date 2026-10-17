import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class CurrencyRatesRepository {
  final Database db;
  static const _uuid = Uuid();

  CurrencyRatesRepository(this.db);

  Future<Map<String, double>> getRates() async {
    final rows = await db.query('global_currency_rates');
    final result = <String, double>{};
    for (final row in rows) {
      final cur = row['currency'] as String;
      final rate = (row['rate'] as num?)?.toDouble() ?? 1.0;
      result[cur] = rate;
    }
    return result;
  }

  Future<void> setRate({
    required String currency,
    required double rate,
    String notes = '',
  }) async {
    final trimmed = currency.trim().toUpperCase();
    if (trimmed.isEmpty) return;

    final existing = await db.query(
      'global_currency_rates',
      where: 'currency = ?',
      whereArgs: [trimmed],
    );

    double? prevRate;
    if (existing.isNotEmpty) {
      prevRate = (existing.first['rate'] as num?)?.toDouble();
    }

    final now = DateTime.now().toIso8601String();

    await db.insert(
      'global_currency_rates',
      {
        'currency': trimmed,
        'rate': rate,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await db.insert('global_currency_history', {
      'id': _uuid.v4(),
      'currency': trimmed,
      'previous_rate': prevRate,
      'new_rate': rate,
      'notes': notes,
      'created_at': now,
    });
  }

  Future<void> removeRate(String currency) async {
    final trimmed = currency.trim().toUpperCase();
    await db.delete(
      'global_currency_rates',
      where: 'currency = ?',
      whereArgs: [trimmed],
    );
  }

  Future<List<Map<String, dynamic>>> getHistory({String? currency}) async {
    if (currency != null && currency.isNotEmpty) {
      return db.query(
        'global_currency_history',
        where: 'currency = ?',
        whereArgs: [currency.trim().toUpperCase()],
        orderBy: 'created_at DESC',
        limit: 50,
      );
    }
    return db.query(
      'global_currency_history',
      orderBy: 'created_at DESC',
      limit: 50,
    );
  }

  static double convert(
    double amount, {
    required String from,
    required String to,
    required Map<String, double> rates,
    required String dominantCurrency,
  }) {
    if (from.toUpperCase() == to.toUpperCase()) return amount;

    // Convert from origin to dominant
    double inDominant = amount;
    if (from.toUpperCase() != dominantCurrency.toUpperCase()) {
      final rateFrom = rates[from.toUpperCase()] ?? 1.0;
      inDominant = amount * rateFrom;
    }

    // Convert from dominant to destination
    if (to.toUpperCase() == dominantCurrency.toUpperCase()) {
      return inDominant;
    }

    final rateTo = rates[to.toUpperCase()] ?? 1.0;
    if (rateTo == 0) return inDominant;
    return inDominant / rateTo;
  }
}
