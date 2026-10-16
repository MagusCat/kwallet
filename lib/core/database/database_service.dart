import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../features/bodega/models/account.dart';
import '../../features/bodega/models/category_model.dart';
import '../../features/bodega/models/transaction_record.dart';
import '../../features/bodega/models/budget_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _database;
  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  void _notify() {
    changeNotifier.value++;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'kwall', 'kwall.db');
    final dir = Directory(p.dirname(dbPath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL,
        currency TEXT NOT NULL DEFAULT '\$',
        icon_key TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        icon_key TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        to_account_id TEXT,
        category_id TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT '',
        date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        monthly_limit REAL NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE kitty_profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        level INTEGER NOT NULL,
        exp INTEGER NOT NULL,
        mood TEXT NOT NULL,
        happiness INTEGER NOT NULL,
        last_interacted TEXT NOT NULL
      )
    ''');

    // Seed default accounts
    final now = DateTime.now();
    final defaultAccounts = [
      Account(
        id: const Uuid().v4(),
        name: 'Bolsillo',
        type: 'cash',
        balance: 140.0,
        currency: '\$',
        iconKey: 'wallet',
        colorValue: 0xFF00FF9D,
        createdAt: now,
      ),
      Account(
        id: const Uuid().v4(),
        name: 'Banco Utama',
        type: 'bank',
        balance: 1850.0,
        currency: '\$',
        iconKey: 'bank',
        colorValue: 0xFF00D2FF,
        createdAt: now,
      ),
      Account(
        id: const Uuid().v4(),
        name: 'Hucha Secreta',
        type: 'vault',
        balance: 950.0,
        currency: '\$',
        iconKey: 'vault',
        colorValue: 0xFFFFB800,
        createdAt: now,
      ),
      Account(
        id: const Uuid().v4(),
        name: 'Tarjeta Lunar',
        type: 'credit',
        balance: -120.0,
        currency: '\$',
        iconKey: 'credit',
        colorValue: 0xFFFF3366,
        createdAt: now,
      ),
    ];

    for (final acc in defaultAccounts) {
      await db.insert('accounts', acc.toMap());
    }

    // Seed default categories (NO EMOJIS, pure game aesthetics)
    final defaultCategories = [
      CategoryModel(id: 'cat_fish', name: 'Pescado & Víveres', type: 'expense', iconKey: 'fish', colorValue: 0xFF00FF9D),
      CategoryModel(id: 'cat_home', name: 'Refugio & Cuartel', type: 'expense', iconKey: 'home', colorValue: 0xFF00D2FF),
      CategoryModel(id: 'cat_arcade', name: 'Arcade & Ocio', type: 'expense', iconKey: 'game', colorValue: 0xFFFF3366),
      CategoryModel(id: 'cat_potion', name: 'Pociones & Salud', type: 'expense', iconKey: 'potion', colorValue: 0xFF9D4EDD),
      CategoryModel(id: 'cat_boss', name: 'Boss Fight / Imprevisto', type: 'expense', iconKey: 'boss', colorValue: 0xFFFFB800),
      CategoryModel(id: 'cat_energy', name: 'Maná & Servicios', type: 'expense', iconKey: 'energy', colorValue: 0xFF00E5FF),
      CategoryModel(id: 'cat_loot', name: 'Loot & Caprichos', type: 'expense', iconKey: 'loot', colorValue: 0xFFFF70A6),
      CategoryModel(id: 'cat_transport', name: 'Warp & Movilidad', type: 'expense', iconKey: 'transport', colorValue: 0xFF70D6FF),
      // Incomes
      CategoryModel(id: 'cat_quest', name: 'Quest Principal (Salario)', type: 'income', iconKey: 'quest', colorValue: 0xFF00FF9D),
      CategoryModel(id: 'cat_gift', name: 'Loot Extra / Recompensa', type: 'income', iconKey: 'gift', colorValue: 0xFFFFD166),
      CategoryModel(id: 'cat_gem', name: 'Tesoro / Rendimientos', type: 'income', iconKey: 'gem', colorValue: 0xFF06D6A0),
    ];

    for (final cat in defaultCategories) {
      await db.insert('categories', cat.toMap());
    }

    // Seed default budget for current month
    await db.insert('budgets', {
      'id': const Uuid().v4(),
      'month': now.month,
      'year': now.year,
      'monthly_limit': 1200.0,
      'created_at': now.toIso8601String(),
    });

    // Seed Kitty profile
    await db.insert('kitty_profile', {
      'id': 'main_kitty',
      'name': 'Kwall',
      'level': 1,
      'exp': 35,
      'mood': 'happy',
      'happiness': 80,
      'last_interacted': now.toIso8601String(),
    });

    // Seed initial welcome transaction note
    await db.insert('transactions', {
      'id': const Uuid().v4(),
      'account_id': defaultAccounts[0].id,
      'category_id': 'cat_fish',
      'amount': 15.50,
      'type': 'expense',
      'note': 'Lata de atún y provisiones para el cuartel',
      'date': now.subtract(const Duration(hours: 3)).toIso8601String(),
      'created_at': now.toIso8601String(),
    });
  }

  // ================= ACCOUNTS =================
  Future<List<Account>> getAccounts() async {
    final db = await database;
    final maps = await db.query('accounts', where: 'is_archived = 0', orderBy: 'created_at ASC');
    return maps.map((m) => Account.fromMap(m)).toList();
  }

  Future<void> createAccount(Account account) async {
    final db = await database;
    await db.insert('accounts', account.toMap());
    _notify();
  }

  Future<void> updateAccount(Account account) async {
    final db = await database;
    await db.update('accounts', account.toMap(), where: 'id = ?', whereArgs: [account.id]);
    _notify();
  }

  Future<void> deleteAccount(String accountId) async {
    final db = await database;
    await db.delete('accounts', where: 'id = ?', whereArgs: [accountId]);
    _notify();
  }

  // ================= CATEGORIES =================
  Future<List<CategoryModel>> getCategories({String? type}) async {
    final db = await database;
    final where = type != null ? 'type = ?' : null;
    final whereArgs = type != null ? [type] : null;
    final maps = await db.query('categories', where: where, whereArgs: whereArgs, orderBy: 'id ASC');
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  // ================= TRANSACTIONS =================
  Future<List<TransactionRecord>> getTransactions({String? accountId, int limit = 50}) async {
    final db = await database;
    String? where;
    List<dynamic>? whereArgs;

    if (accountId != null) {
      where = 'account_id = ? OR to_account_id = ?';
      whereArgs = [accountId, accountId];
    }

    final maps = await db.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
      limit: limit,
    );
    return maps.map((m) => TransactionRecord.fromMap(m)).toList();
  }

  Future<void> addTransaction(TransactionRecord tx) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('transactions', tx.toMap());

      if (tx.type == 'expense') {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
      } else if (tx.type == 'income') {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
      } else if (tx.type == 'transfer' && tx.toAccountId != null) {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [tx.amount, tx.toAccountId],
        );
      }
    });
    _notify();
  }

  Future<void> deleteTransaction(TransactionRecord tx) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions', where: 'id = ?', whereArgs: [tx.id]);

      // Revert balances
      if (tx.type == 'expense') {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
      } else if (tx.type == 'income') {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
      } else if (tx.type == 'transfer' && tx.toAccountId != null) {
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance + ? WHERE id = ?',
          [tx.amount, tx.accountId],
        );
        await txn.rawUpdate(
          'UPDATE accounts SET balance = balance - ? WHERE id = ?',
          [tx.amount, tx.toAccountId],
        );
      }
    });
    _notify();
  }

  // ================= BUDGETS =================
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

    final newBudget = BudgetModel(
      id: const Uuid().v4(),
      month: now.month,
      year: now.year,
      monthlyLimit: 1000.0,
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
    _notify();
  }

  Future<double> getMonthlySpentTotal(int month, int year) async {
    final db = await database;
    final startStr = DateTime(year, month, 1).toIso8601String();
    final endStr = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final result = await db.rawQuery(
      "SELECT SUM(amount) as total FROM transactions WHERE type = 'expense' AND date BETWEEN ? AND ?",
      [startStr, endStr],
    );

    final total = result.first['total'];
    if (total == null) return 0.0;
    return (total as num).toDouble();
  }

  // ================= KITTY PROFILE & MOOD =================
  Future<Map<String, dynamic>> getKittyProfile() async {
    final db = await database;
    final maps = await db.query('kitty_profile', where: 'id = ?', whereArgs: ['main_kitty']);
    if (maps.isNotEmpty) {
      return Map<String, dynamic>.from(maps.first);
    }
    return {
      'id': 'main_kitty',
      'name': 'Kwall',
      'level': 1,
      'exp': 35,
      'mood': 'happy',
      'happiness': 80,
    };
  }

  Future<void> updateKittyMood(String mood, {int? happinessDelta, int? expDelta}) async {
    final db = await database;
    final profile = await getKittyProfile();
    int currentHappiness = (profile['happiness'] as int?) ?? 80;
    int currentExp = (profile['exp'] as int?) ?? 0;
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
    _notify();
  }

  // ================= BACKUP / RESILIENCE =================
  Future<String> exportFullDataAsJson() async {
    final db = await database;
    final accounts = await db.query('accounts');
    final categories = await db.query('categories');
    final transactions = await db.query('transactions');
    final budgets = await db.query('budgets');
    final kitty = await db.query('kitty_profile');

    final backup = {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'kwall',
      'data': {
        'accounts': accounts,
        'categories': categories,
        'transactions': transactions,
        'budgets': budgets,
        'kitty_profile': kitty,
      }
    };
    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  Future<void> importFullDataFromJson(String jsonContent) async {
    final map = jsonDecode(jsonContent) as Map<String, dynamic>;
    final data = map['data'] as Map<String, dynamic>;
    final db = await database;

    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('accounts');
      await txn.delete('categories');
      await txn.delete('budgets');
      await txn.delete('kitty_profile');

      if (data['accounts'] != null) {
        for (final row in (data['accounts'] as List)) {
          await txn.insert('accounts', Map<String, dynamic>.from(row as Map));
        }
      }
      if (data['categories'] != null) {
        for (final row in (data['categories'] as List)) {
          await txn.insert('categories', Map<String, dynamic>.from(row as Map));
        }
      }
      if (data['transactions'] != null) {
        for (final row in (data['transactions'] as List)) {
          await txn.insert('transactions', Map<String, dynamic>.from(row as Map));
        }
      }
      if (data['budgets'] != null) {
        for (final row in (data['budgets'] as List)) {
          await txn.insert('budgets', Map<String, dynamic>.from(row as Map));
        }
      }
      if (data['kitty_profile'] != null) {
        for (final row in (data['kitty_profile'] as List)) {
          await txn.insert('kitty_profile', Map<String, dynamic>.from(row as Map));
        }
      }
    });
    _notify();
  }
}
