import '../../models/currency_conversion.dart';
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../../features/bodega/models/account.dart';
import '../../../features/bodega/models/category_model.dart';
import '../database_context.dart';

mixin AccountsRepository on DatabaseContext {
  Future<List<Account>> getAccounts({bool includeArchived = false}) async {
    final db = await database;
    final maps = await db.query(
      'accounts',
      where: includeArchived ? null : 'is_archived = 0',
      orderBy: 'created_at ASC',
    );
    return maps.map((m) => Account.fromMap(m)).toList();
  }

  Future<void> createAccount(Account account) async {
    final db = await database;
    if (!account.balance.isFinite ||
        !account.minimumBalance.isFinite ||
        account.minimumBalance < 0) {
      throw ArgumentError('Saldo inválido');
    }
    await db.transaction((txn) async {
    await txn.insert('accounts', account.toMap());

    // Registrar historial de moneda base y secundarias con conversión 1 a 1
    final now = DateTime.now().toIso8601String();
    for (final c in account.currencies) {
      await txn.insert('account_currency_history', {
        'id': const Uuid().v4(),
        'account_id': account.id,
        'base_currency': account.currency,
        'currency': c,
        'conversion_rate': 1.0,
        'previous_rate': null,
        'change_type': c == account.currency ? 'initial_base' : 'initial_secondary',
        'notes': c == account.currency
            ? 'Moneda base configurada'
            : 'Moneda secundaria añadida con conversión 1 a 1',
        'created_at': now,
      });
    }
    });
    notifyChanged();
  }

  Future<void> updateAccount(Account account) async {
    final db = await database;
    if (!account.minimumBalance.isFinite || account.minimumBalance < 0) throw ArgumentError('Reserva inválida');
    await db.transaction((txn) async {
    final oldRows = await txn.query('accounts', where: 'id = ?', whereArgs: [account.id]);
    if (oldRows.isEmpty) throw StateError('La cuenta ya no existe');
    if (CurrencyConversion.code(oldRows.single['currency'] as String) != CurrencyConversion.code(account.currency)) {
      throw StateError('Crea otra cuenta para usar otra moneda');
    }
    final oldAccount = Account.fromMap(oldRows.single);
    for (final currency in {...oldAccount.currencies, ...account.currencies}) {
      if (oldAccount.currencies.contains(currency) == account.currencies.contains(currency)) continue;
      await txn.insert('account_currency_history', {
        'id': const Uuid().v4(), 'account_id': account.id, 'base_currency': account.currency,
        'currency': currency, 'conversion_rate': 1.0, 'change_type': account.currencies.contains(currency) ? 'currency_added' : 'currency_removed',
        'notes': '', 'created_at': DateTime.now().toIso8601String(),
      });
    }
    await txn.update(
      'accounts',
      {
        'name': account.name,
        'type': account.type,
        'minimum_balance': account.minimumBalance,
        'color_value': account.colorValue,
        'icon_key': account.iconKey,
        'currency': account.currency,
        'currencies': jsonEncode(account.currencies),
      },
      where: 'id = ?',
      whereArgs: [account.id],
    );
    });
    notifyChanged();
  }

  Future<List<Map<String, dynamic>>> getAccountCurrencyHistory(String accountId) async {
    final db = await database;
    return await db.query(
      'account_currency_history',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> recordCurrencyChange({
    required String accountId,
    required String baseCurrency,
    required String currency,
    required double rate,
    double? previousRate,
    required String changeType,
    String notes = '',
  }) async {
    final db = await database;
    await db.insert('account_currency_history', {
      'id': const Uuid().v4(),
      'account_id': accountId,
      'base_currency': baseCurrency,
      'currency': currency,
      'conversion_rate': rate,
      'previous_rate': previousRate,
      'change_type': changeType,
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    });
    notifyChanged();
  }

  Future<void> deleteAccount(String accountId) async {
    final db = await database;
    await db.update(
      'accounts',
      {'is_archived': 1},
      where: 'id = ?',
      whereArgs: [accountId],
    );
    notifyChanged();
  }

  Future<List<CategoryModel>> getCategories({String? type}) async {
    final db = await database;
    final where = type != null ? 'type = ?' : null;
    final whereArgs = type != null ? [type] : null;
    final maps = await db.query(
      'categories',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
    );
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  Future<void> createCategory(CategoryModel category) async {
    final db = await database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    notifyChanged();
  }

  Future<void> deleteCategory(String categoryId) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
    notifyChanged();
  }
}
