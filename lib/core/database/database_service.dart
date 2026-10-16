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
import '../../features/bodega/models/planned_expense.dart';

class DailySpend {
  final DateTime date;
  final String dayLabel;
  final double amount;

  DailySpend({
    required this.date,
    required this.dayLabel,
    required this.amount,
  });
}

class CategoryBreakdown {
  final CategoryModel category;
  final double amount;
  final double percentage;

  CategoryBreakdown({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

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
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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
        coat_color TEXT NOT NULL DEFAULT 'orange',
        personality TEXT NOT NULL DEFAULT 'curious',
        last_interacted TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE planned_expenses (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        due_date TEXT NOT NULL,
        recurrence TEXT NOT NULL,
        category_id TEXT NOT NULL,
        account_id TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        note TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    final now = DateTime.now();

    // Default currency
    await db.insert('app_settings', {'key': 'currency', 'value': '\$'});

    // Seed default accounts
    final defaultAccounts = [
      Account(
        id: const Uuid().v4(),
        name: 'Bolsillo',
        type: 'cash',
        balance: 140.0,
        currency: '\$',
        iconKey: 'wallet',
        colorValue: 0xFF10B981,
        createdAt: now,
      ),
      Account(
        id: const Uuid().v4(),
        name: 'Banco Principal',
        type: 'bank',
        balance: 1850.0,
        currency: '\$',
        iconKey: 'bank',
        colorValue: 0xFF3B82F6,
        createdAt: now,
      ),
      Account(
        id: const Uuid().v4(),
        name: 'Hucha / Ahorro',
        type: 'vault',
        balance: 950.0,
        currency: '\$',
        iconKey: 'vault',
        colorValue: 0xFFF59E0B,
        createdAt: now,
      ),
      Account(
        id: const Uuid().v4(),
        name: 'Tarjeta de Crédito',
        type: 'credit',
        balance: -120.0,
        currency: '\$',
        iconKey: 'credit',
        colorValue: 0xFFEF4444,
        createdAt: now,
      ),
    ];

    for (final acc in defaultAccounts) {
      await db.insert('accounts', acc.toMap());
    }

    // Seed default clean categories (No emojis, sleek Material Expressive icons)
    final defaultCategories = [
      CategoryModel(id: 'cat_food', name: 'Alimentación & Súper', type: 'expense', iconKey: 'food', colorValue: 0xFF10B981),
      CategoryModel(id: 'cat_home', name: 'Hogar & Servicios', type: 'expense', iconKey: 'home', colorValue: 0xFF3B82F6),
      CategoryModel(id: 'cat_transport', name: 'Transporte', type: 'expense', iconKey: 'transport', colorValue: 0xFF06B6D4),
      CategoryModel(id: 'cat_leisure', name: 'Ocio & Cafés', type: 'expense', iconKey: 'game', colorValue: 0xFF8B5CF6),
      CategoryModel(id: 'cat_health', name: 'Salud & Cuidado', type: 'expense', iconKey: 'potion', colorValue: 0xFFEC4899),
      CategoryModel(id: 'cat_shopping', name: 'Compras & Ropa', type: 'expense', iconKey: 'loot', colorValue: 0xFFF97316),
      CategoryModel(id: 'cat_bills', name: 'Suscripciones', type: 'expense', iconKey: 'energy', colorValue: 0xFF6366F1),
      CategoryModel(id: 'cat_other', name: 'Imprevistos', type: 'expense', iconKey: 'boss', colorValue: 0xFF64748B),
      // Incomes
      CategoryModel(id: 'cat_salary', name: 'Sueldo / Nómina', type: 'income', iconKey: 'quest', colorValue: 0xFF10B981),
      CategoryModel(id: 'cat_extra', name: 'Ingresos Extra', type: 'income', iconKey: 'gift', colorValue: 0xFFF59E0B),
      CategoryModel(id: 'cat_invest', name: 'Inversiones', type: 'income', iconKey: 'gem', colorValue: 0xFF14B8A6),
    ];

    for (final cat in defaultCategories) {
      await db.insert('categories', cat.toMap());
    }

    // Seed monthly budget
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
      'name': 'Mishi',
      'level': 1,
      'exp': 45,
      'mood': 'happy',
      'happiness': 85,
      'coat_color': 'orange',
      'personality': 'curious',
      'last_interacted': now.toIso8601String(),
    });

    // Seed sample transactions for last days
    await db.insert('transactions', {
      'id': const Uuid().v4(),
      'account_id': defaultAccounts[0].id,
      'category_id': 'cat_food',
      'amount': 18.50,
      'type': 'expense',
      'note': 'Almuerzo y café',
      'date': now.subtract(const Duration(hours: 3)).toIso8601String(),
      'created_at': now.toIso8601String(),
    });
    await db.insert('transactions', {
      'id': const Uuid().v4(),
      'account_id': defaultAccounts[1].id,
      'category_id': 'cat_bills',
      'amount': 9.99,
      'type': 'expense',
      'note': 'Suscripción mensual',
      'date': now.subtract(const Duration(days: 1, hours: 2)).toIso8601String(),
      'created_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    });
    await db.insert('transactions', {
      'id': const Uuid().v4(),
      'account_id': defaultAccounts[0].id,
      'category_id': 'cat_transport',
      'amount': 12.00,
      'type': 'expense',
      'note': 'Recarga transporte',
      'date': now.subtract(const Duration(days: 2)).toIso8601String(),
      'created_at': now.subtract(const Duration(days: 2)).toIso8601String(),
    });

    // Seed sample planned expense
    await db.insert('planned_expenses', {
      'id': const Uuid().v4(),
      'title': 'Alquiler / Hipoteca',
      'amount': 450.0,
      'due_date': DateTime(now.year, now.month, 28).toIso8601String(),
      'recurrence': 'monthly',
      'category_id': 'cat_home',
      'account_id': defaultAccounts[1].id,
      'is_completed': 0,
      'note': 'Pago fijo fin de mes',
      'created_at': now.toIso8601String(),
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS planned_expenses (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          due_date TEXT NOT NULL,
          recurrence TEXT NOT NULL,
          category_id TEXT NOT NULL,
          account_id TEXT,
          is_completed INTEGER NOT NULL DEFAULT 0,
          note TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');

      try {
        await db.execute("ALTER TABLE kitty_profile ADD COLUMN coat_color TEXT NOT NULL DEFAULT 'orange'");
      } catch (_) {}
      try {
        await db.execute("ALTER TABLE kitty_profile ADD COLUMN personality TEXT NOT NULL DEFAULT 'curious'");
      } catch (_) {}

      await db.insert('app_settings', {'key': 'currency', 'value': '\$'},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  // ================= APP SETTINGS =================
  Future<String> getCurrency() async {
    final db = await database;
    final res = await db.query('app_settings', where: 'key = ?', whereArgs: ['currency'], limit: 1);
    if (res.isNotEmpty) {
      return res.first['value'] as String;
    }
    return '\$';
  }

  Future<void> setCurrency(String newCurrency) async {
    final db = await database;
    await db.insert(
      'app_settings',
      {'key': 'currency', 'value': newCurrency},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notify();
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
    final maps = await db.query('categories', where: where, whereArgs: whereArgs, orderBy: 'name ASC');
    return maps.map((m) => CategoryModel.fromMap(m)).toList();
  }

  Future<void> createCategory(CategoryModel category) async {
    final db = await database;
    await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    _notify();
  }

  Future<void> deleteCategory(String categoryId) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
    _notify();
  }

  // ================= TRANSACTIONS =================
  Future<List<TransactionRecord>> getTransactions({String? accountId, int limit = 100}) async {
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

  // ================= PLANNED EXPENSES =================
  Future<List<PlannedExpense>> getPlannedExpenses({bool includeCompleted = true}) async {
    final db = await database;
    final where = includeCompleted ? null : 'is_completed = 0';
    final maps = await db.query('planned_expenses', where: where, orderBy: 'due_date ASC');
    return maps.map((m) => PlannedExpense.fromMap(m)).toList();
  }

  Future<void> addPlannedExpense(PlannedExpense expense) async {
    final db = await database;
    await db.insert('planned_expenses', expense.toMap());
    _notify();
  }

  Future<void> updatePlannedExpense(PlannedExpense expense) async {
    final db = await database;
    await db.update('planned_expenses', expense.toMap(), where: 'id = ?', whereArgs: [expense.id]);
    _notify();
  }

  Future<void> deletePlannedExpense(String id) async {
    final db = await database;
    await db.delete('planned_expenses', where: 'id = ?', whereArgs: [id]);
    _notify();
  }

  Future<void> togglePlannedExpenseCompleted(String id, bool completed) async {
    final db = await database;
    await db.update(
      'planned_expenses',
      {'is_completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
    _notify();
  }

  // ================= ANALYTICS & CHARTS =================
  Future<List<DailySpend>> getDailySpendingLast7Days() async {
    final db = await database;
    final now = DateTime.now();
    final List<DailySpend> result = [];

    const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      final start = DateTime(targetDate.year, targetDate.month, targetDate.day, 0, 0, 0).toIso8601String();
      final end = DateTime(targetDate.year, targetDate.month, targetDate.day, 23, 59, 59).toIso8601String();

      final rows = await db.rawQuery(
        "SELECT SUM(amount) as total FROM transactions WHERE type = 'expense' AND date BETWEEN ? AND ?",
        [start, end],
      );

      final total = (rows.first['total'] as num?)?.toDouble() ?? 0.0;
      final dayLabel = weekdays[targetDate.weekday - 1];

      result.add(DailySpend(
        date: targetDate,
        dayLabel: i == 0 ? 'Hoy' : dayLabel,
        amount: total,
      ));
    }

    return result;
  }

  Future<List<CategoryBreakdown>> getCategorySpendingBreakdown(int month, int year) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final totalSpentResult = await db.rawQuery(
      "SELECT SUM(amount) as grand_total FROM transactions WHERE type = 'expense' AND date BETWEEN ? AND ?",
      [start, end],
    );
    final grandTotal = (totalSpentResult.first['grand_total'] as num?)?.toDouble() ?? 0.0;
    if (grandTotal <= 0) return [];

    final rows = await db.rawQuery(
      "SELECT category_id, SUM(amount) as total FROM transactions WHERE type = 'expense' AND date BETWEEN ? AND ? GROUP BY category_id ORDER BY total DESC",
      [start, end],
    );

    final categories = await getCategories();
    final catMap = {for (var c in categories) c.id: c};

    final List<CategoryBreakdown> breakdown = [];
    for (final r in rows) {
      final catId = r['category_id'] as String;
      final total = (r['total'] as num).toDouble();
      final cat = catMap[catId] ??
          CategoryModel(id: catId, name: 'Varios', type: 'expense', iconKey: 'tag', colorValue: 0xFF64748B);

      breakdown.add(CategoryBreakdown(
        category: cat,
        amount: total,
        percentage: (total / grandTotal) * 100,
      ));
    }
    return breakdown;
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
      monthlyLimit: 1200.0,
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

  // ================= KITTY PROFILE =================
  Future<Map<String, dynamic>> getKittyProfile() async {
    final db = await database;
    final maps = await db.query('kitty_profile', where: 'id = ?', whereArgs: ['main_kitty']);
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

  Future<void> updateKittyConfig({String? name, String? coatColor, String? personality}) async {
    final db = await database;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (coatColor != null) updates['coat_color'] = coatColor;
    if (personality != null) updates['personality'] = personality;

    if (updates.isNotEmpty) {
      await db.update('kitty_profile', updates, where: 'id = ?', whereArgs: ['main_kitty']);
      _notify();
    }
  }

  Future<void> updateKittyMood(String mood, {int? happinessDelta, int? expDelta}) async {
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
    final planned = await db.query('planned_expenses');
    final settings = await db.query('app_settings');

    final backup = {
      'version': 2,
      'exported_at': DateTime.now().toIso8601String(),
      'app': 'kwall',
      'data': {
        'accounts': accounts,
        'categories': categories,
        'transactions': transactions,
        'budgets': budgets,
        'kitty_profile': kitty,
        'planned_expenses': planned,
        'app_settings': settings,
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
      await txn.delete('planned_expenses');
      await txn.delete('app_settings');

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
      if (data['planned_expenses'] != null) {
        for (final row in (data['planned_expenses'] as List)) {
          await txn.insert('planned_expenses', Map<String, dynamic>.from(row as Map));
        }
      }
      if (data['app_settings'] != null) {
        for (final row in (data['app_settings'] as List)) {
          await txn.insert('app_settings', Map<String, dynamic>.from(row as Map));
        }
      }
    });
    _notify();
  }
}
