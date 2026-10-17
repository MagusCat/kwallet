import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import '../../features/bodega/models/category_model.dart';
import '../../features/journal/models/journal_models.dart';

class DatabaseSchema {
  static Future<void> create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL,
        minimum_balance REAL NOT NULL DEFAULT 0,
        opening_balance REAL NOT NULL DEFAULT 0,
        currency TEXT NOT NULL DEFAULT '\$',
        currencies TEXT NOT NULL DEFAULT '[]',
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
        weekly_limit REAL,
        daily_limit REAL,
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
        recurrence_day INTEGER,
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

    await _createV4Tables(db);

    final now = DateTime.now();

    // Default currency
    await db.insert('app_settings', {'key': 'currency', 'value': '\$'});

    // Seed default clean categories (No emojis, sleek Material Expressive icons)
    final defaultCategories = [
      CategoryModel(
        id: 'cat_food',
        name: 'Alimentación & Súper',
        type: 'expense',
        iconKey: 'food',
        colorValue: 0xFF10B981,
      ),
      CategoryModel(
        id: 'cat_home',
        name: 'Hogar & Servicios',
        type: 'expense',
        iconKey: 'home',
        colorValue: 0xFF715033,
      ),
      CategoryModel(
        id: 'cat_transport',
        name: 'Transporte',
        type: 'expense',
        iconKey: 'transport',
        colorValue: 0xFF6B703A,
      ),
      CategoryModel(
        id: 'cat_leisure',
        name: 'Ocio & Cafés',
        type: 'expense',
        iconKey: 'game',
        colorValue: 0xFF8C493F,
      ),
      CategoryModel(
        id: 'cat_health',
        name: 'Salud & Cuidado',
        type: 'expense',
        iconKey: 'potion',
        colorValue: 0xFFEC4899,
      ),
      CategoryModel(
        id: 'cat_shopping',
        name: 'Compras & Ropa',
        type: 'expense',
        iconKey: 'loot',
        colorValue: 0xFFF97316,
      ),
      CategoryModel(
        id: 'cat_bills',
        name: 'Suscripciones',
        type: 'expense',
        iconKey: 'energy',
        colorValue: 0xFF835800,
      ),
      CategoryModel(
        id: 'cat_other',
        name: 'Imprevistos',
        type: 'expense',
        iconKey: 'boss',
        colorValue: 0xFF625B52,
      ),
      // Incomes
      CategoryModel(
        id: 'cat_salary',
        name: 'Sueldo / Nómina',
        type: 'income',
        iconKey: 'quest',
        colorValue: 0xFF10B981,
      ),
      CategoryModel(
        id: 'cat_extra',
        name: 'Ingresos Extra',
        type: 'income',
        iconKey: 'gift',
        colorValue: 0xFFF59E0B,
      ),
      CategoryModel(
        id: 'cat_invest',
        name: 'Inversiones',
        type: 'income',
        iconKey: 'gem',
        colorValue: 0xFF14B8A6,
      ),
    ];

    for (final cat in defaultCategories) {
      await db.insert('categories', cat.toMap());
    }

    // Seed monthly budget
    await db.insert('budgets', {
      'id': const Uuid().v4(),
      'month': now.month,
      'year': now.year,
      'monthly_limit': 0.0,
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
  }

  static Future<void> _createV4Tables(DatabaseExecutor db) async {
    await db.execute(
      'CREATE TABLE IF NOT EXISTS budget_allocations (period_key TEXT PRIMARY KEY, period TEXT NOT NULL, period_start TEXT NOT NULL, amount REAL NOT NULL CHECK(amount >= 0), updated_at TEXT NOT NULL)',
    );
    await db.execute(
      "CREATE TABLE IF NOT EXISTS personal_notes (id TEXT PRIMARY KEY, title TEXT NOT NULL, body TEXT NOT NULL DEFAULT '', kind TEXT NOT NULL DEFAULT 'note', items TEXT NOT NULL DEFAULT '[]', updated_at TEXT NOT NULL)",
    );
    await db.execute(
      "CREATE TABLE IF NOT EXISTS habits (id TEXT PRIMARY KEY, title TEXT NOT NULL, icon_key TEXT NOT NULL DEFAULT 'spa_rounded', color_value INTEGER NOT NULL DEFAULT 4283226960, time_block TEXT NOT NULL DEFAULT 'anytime', created_at TEXT NOT NULL)",
    );
    await db.execute(
      "CREATE TABLE IF NOT EXISTS habit_logs (id TEXT PRIMARY KEY, habit_id TEXT NOT NULL REFERENCES habits(id) ON DELETE CASCADE, day TEXT NOT NULL, completed INTEGER NOT NULL CHECK(completed IN (0,1)), mood TEXT NOT NULL DEFAULT 'neutral', reason TEXT NOT NULL DEFAULT '', UNIQUE(habit_id,day))",
    );
    await db.execute(
      'CREATE TABLE IF NOT EXISTS reward_events (id TEXT PRIMARY KEY, points INTEGER NOT NULL CHECK(points >= 0), created_at TEXT NOT NULL)',
    );
    await db.execute(
      "CREATE TABLE IF NOT EXISTS transaction_archive (id TEXT PRIMARY KEY, account_id TEXT NOT NULL, to_account_id TEXT, category_id TEXT NOT NULL, amount REAL NOT NULL, type TEXT NOT NULL, note TEXT NOT NULL DEFAULT '', date TEXT NOT NULL, created_at TEXT NOT NULL, voided_at TEXT NOT NULL)",
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transaction_archive_date ON transaction_archive(date DESC,id DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC, id DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_account ON transactions(account_id,date DESC,id DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_destination ON transactions(to_account_id,date DESC,id DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_type_date ON transactions(type,date DESC,id DESC)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS front_pending_items (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        subtitle TEXT NOT NULL DEFAULT '',
        due_date TEXT,
        source_id TEXT NOT NULL,
        source_index INTEGER,
        is_completed INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_front_pending_cat ON front_pending_items(category, is_completed)',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS account_currency_history (
        id TEXT PRIMARY KEY,
        account_id TEXT NOT NULL,
        base_currency TEXT NOT NULL,
        currency TEXT NOT NULL,
        conversion_rate REAL NOT NULL DEFAULT 1.0,
        previous_rate REAL,
        change_type TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_acc_curr_hist ON account_currency_history(account_id, created_at DESC)',
    );
  }

  static Future<void> backfillOpeningBalances(
    DatabaseExecutor db, {
    String? accountId,
  }) async {
    await db.rawUpdate(
      """UPDATE accounts SET opening_balance = balance - COALESCE((
      SELECT SUM(CASE WHEN t.account_id = accounts.id AND t.type = 'income' THEN t.amount
        WHEN t.account_id = accounts.id AND t.type IN ('expense','transfer') THEN -t.amount ELSE 0 END
        + CASE WHEN t.to_account_id = accounts.id AND t.type = 'transfer' THEN t.amount ELSE 0 END)
      FROM transactions t WHERE t.account_id = accounts.id OR t.to_account_id = accounts.id),0)
      ${accountId == null ? '' : 'WHERE id = ?'}""",
      accountId == null ? [] : [accountId],
    );
  }

  static Future<void> upgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE budgets ADD COLUMN weekly_limit REAL');
      await db.execute('ALTER TABLE budgets ADD COLUMN daily_limit REAL');
    }
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

      final kittyColumns = (await db.rawQuery(
        'PRAGMA table_info(kitty_profile)',
      )).map((row) => row['name']).toSet();
      if (!kittyColumns.contains('coat_color')) {
        await db.execute(
          "ALTER TABLE kitty_profile ADD COLUMN coat_color TEXT NOT NULL DEFAULT 'orange'",
        );
      }
      if (!kittyColumns.contains('personality')) {
        await db.execute(
          "ALTER TABLE kitty_profile ADD COLUMN personality TEXT NOT NULL DEFAULT 'curious'",
        );
      }

      await db.insert('app_settings', {
        'key': 'currency',
        'value': '\$',
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE planned_expenses ADD COLUMN recurrence_day INTEGER',
      );
    }
    if (oldVersion < 4) {
      await db.execute(
        'ALTER TABLE accounts ADD COLUMN minimum_balance REAL NOT NULL DEFAULT 0',
      );
      await db.execute(
        'ALTER TABLE accounts ADD COLUMN opening_balance REAL NOT NULL DEFAULT 0',
      );
      await backfillOpeningBalances(db);
      await _createV4Tables(db);
      final oldNotes = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['quick_notes'],
      );
      if (oldNotes.isNotEmpty &&
          (oldNotes.first['value'] as String).trim().isNotEmpty) {
        await db.insert(
          'personal_notes',
          PersonalNote(
            id: 'legacy-quick-notes',
            title: 'Mis notas',
            body: oldNotes.first['value'] as String,
            updatedAt: DateTime.now(),
          ).toMap(),
        );
      }
    }
  }

  static Future<void> ensureHabitColumns(DatabaseExecutor db) async {
    final tables = (await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    )).map((r) => r['name']).toSet();

    if (tables.contains('habits')) {
      final columns = (await db.rawQuery('PRAGMA table_info(habits)'))
          .map((r) => r['name'])
          .toSet();
      if (!columns.contains('icon_key')) {
        await db.execute(
          "ALTER TABLE habits ADD COLUMN icon_key TEXT NOT NULL DEFAULT 'spa_rounded'",
        );
      }
      if (!columns.contains('color_value')) {
        await db.execute(
          'ALTER TABLE habits ADD COLUMN color_value INTEGER NOT NULL DEFAULT 4283226960',
        );
      }
      if (!columns.contains('time_block')) {
        await db.execute(
          "ALTER TABLE habits ADD COLUMN time_block TEXT NOT NULL DEFAULT 'anytime'",
        );
      }
    }

    if (tables.contains('accounts')) {
      final accountCols = (await db.rawQuery('PRAGMA table_info(accounts)'))
          .map((r) => r['name'])
          .toSet();
      if (!accountCols.contains('currencies')) {
        await db.execute(
          "ALTER TABLE accounts ADD COLUMN currencies TEXT NOT NULL DEFAULT '[]'",
        );
      }
    }

    if (!tables.contains('front_pending_items')) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS front_pending_items (
          id TEXT PRIMARY KEY,
          category TEXT NOT NULL,
          title TEXT NOT NULL,
          subtitle TEXT NOT NULL DEFAULT '',
          due_date TEXT,
          source_id TEXT NOT NULL,
          source_index INTEGER,
          is_completed INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_front_pending_cat ON front_pending_items(category, is_completed)',
      );
    }

    if (!tables.contains('account_currency_history')) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS account_currency_history (
          id TEXT PRIMARY KEY,
          account_id TEXT NOT NULL,
          base_currency TEXT NOT NULL,
          currency TEXT NOT NULL,
          conversion_rate REAL NOT NULL DEFAULT 1.0,
          previous_rate REAL,
          change_type TEXT NOT NULL,
          notes TEXT NOT NULL DEFAULT '',
          created_at TEXT NOT NULL,
          FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_acc_curr_hist ON account_currency_history(account_id, created_at DESC)',
      );
    }
  }
}
