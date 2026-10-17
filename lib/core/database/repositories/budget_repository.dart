import '../currency_snapshot.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../../features/bodega/models/budget_model.dart';
import '../../../features/bodega/models/finance_overview.dart';
import '../../../features/journal/models/journal_models.dart';
import '../database_context.dart';

mixin BudgetRepository on DatabaseContext {
  Future<void> saveBudget({
    required double monthly,
    double? weekly,
    double? daily,
  }) async {
    final budget = await getCurrentBudget();
    final db = await database;
    await db.update(
      'budgets',
      {'monthly_limit': monthly, 'weekly_limit': weekly, 'daily_limit': daily},
      where: 'id = ?',
      whereArgs: [budget.id],
    );
    notifyChanged();
  }

  Future<double> getSpentBetween(DateTime start, DateTime end) async {
    final db = await database;
    return CurrencySnapshot.sum(db, "type = 'expense' AND date >= ? AND date < ?", [dayKey(start), dayKey(end)]);
  }

  Future<Map<BudgetPeriod, double>> getPeriodSpending(DateTime date) async {
    final result = <BudgetPeriod, double>{};
    for (final period in BudgetPeriod.values) {
      final range = periodRange(period, date);
      result[period] = await getSpentBetween(range.start, range.end);
    }
    return result;
  }

  Future<BudgetModel> getCurrentBudget() async {
    final db = await database;
    final now = DateTime.now();
    final maps = await db.query(
      'budgets',
      where: 'month = ? AND year = ?',
      whereArgs: [now.month, now.year],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return BudgetModel.fromMap(maps.first);
    }

    final previous = await db.query(
      'budgets',
      orderBy: 'year DESC, month DESC',
      limit: 1,
    );
    final prior = previous.isEmpty ? null : BudgetModel.fromMap(previous.first);
    final newBudget = BudgetModel(
      id: const Uuid().v4(),
      month: now.month,
      year: now.year,
      monthlyLimit: prior?.monthlyLimit ?? 0,
      weeklyLimit: prior?.weeklyLimit,
      dailyLimit: prior?.dailyLimit,
      createdAt: now,
    );
    await db.insert('budgets', newBudget.toMap());
    return newBudget;
  }

  Future<void> setMonthlyBudget(double limit) async {
    final db = await database;
    final now = DateTime.now();
    final existing = await db.query(
      'budgets',
      where: 'month = ? AND year = ?',
      whereArgs: [now.month, now.year],
    );

    if (existing.isNotEmpty) {
      await db.update(
        'budgets',
        {'monthly_limit': limit},
        where: 'month = ? AND year = ?',
        whereArgs: [now.month, now.year],
      );
    } else {
      await db.insert('budgets', {
        'id': const Uuid().v4(),
        'month': now.month,
        'year': now.year,
        'monthly_limit': limit,
        'created_at': now.toIso8601String(),
      });
    }
    notifyChanged();
  }

  Future<double> getMonthlySpentTotal(int month, int year) async {
    final db = await database;
    return CurrencySnapshot.sum(db, "type = 'expense' AND date >= ? AND date < ?", [DateTime(year, month).toIso8601String(), DateTime(year, month + 1).toIso8601String()]);
  }

  Future<Map<BudgetPeriod, double>> getBudgetAllocations(DateTime date) async {
    final db = await database;
    final result = <BudgetPeriod, double>{};
    for (final period in BudgetPeriod.values) {
      final rows = await db.query(
        'budget_allocations',
        where: 'period_key = ?',
        whereArgs: [
          '${period.name}:${dayKey(periodRange(period, date).start)}',
        ],
      );
      if (rows.isNotEmpty) {
        result[period] = (rows.first['amount'] as num).toDouble();
      }
    }
    return result;
  }

  Future<void> allocateBudget(
    BudgetPeriod period,
    DateTime date,
    double? amount, {
    String? mode,
    double? share,
  }) async {
    if (amount != null && (!amount.isFinite || amount < 0)) {
      throw ArgumentError('Monto inválido');
    }
    if (mode != null && !['assigned', 'available'].contains(mode)) {
      throw ArgumentError('Modo inválido');
    }
    if (share != null && (!share.isFinite || share < 1 || share > 100)) {
      throw ArgumentError('Porcentaje inválido');
    }
    final db = await database;
    final start = dayKey(periodRange(period, date).start);
    final key = '${period.name}:$start';
    await db.transaction((txn) async {
      if (amount == null) {
        await txn.delete(
          'budget_allocations',
          where: 'period_key = ?',
          whereArgs: [key],
        );
      } else {
        await txn.insert('budget_allocations', {
          'period_key': key,
          'period': period.name,
          'period_start': start,
          'amount': amount,
          'updated_at': DateTime.now().toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final settings = <String, String>{
        'budget_mode': ?mode,
        if (share != null) 'budget_share': share.toString(),
      };
      for (final entry in settings.entries) {
        await txn.insert('app_settings', {
          'key': entry.key,
          'value': entry.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    notifyChanged();
  }
}
