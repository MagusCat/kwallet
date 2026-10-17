import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
    await db.insert('accounts', account.toMap());
    notifyChanged();
  }

  Future<void> updateAccount(Account account) async {
    final db = await database;
    await db.update(
      'accounts',
      {
        'name': account.name,
        'type': account.type,
        'minimum_balance': account.minimumBalance,
        'color_value': account.colorValue,
        'icon_key': account.iconKey,
      },
      where: 'id = ?',
      whereArgs: [account.id],
    );
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
