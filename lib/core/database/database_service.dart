import 'dart:io';
import '../services/credential_store.dart';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart' as mobile;

import '../contracts/app_repositories.dart' as contracts;
import 'database_backup.dart';
import 'database_context.dart';
import 'database_schema.dart';
import 'repositories/preferences_repository.dart';
import 'repositories/accounts_repository.dart';
import 'repositories/budget_repository.dart';
import 'repositories/ledger_repository.dart';
import 'repositories/planning_repository.dart';
import 'repositories/insights_repository.dart';
import 'repositories/journal_repository.dart';
import 'repositories/backup_repository.dart';

export '../../features/bodega/models/spending_summary.dart'
    show DailySpend, CategoryBreakdown;

class DatabaseService extends DatabaseContext
    with
        PreferencesRepository,
        AccountsRepository,
        BudgetRepository,
        LedgerRepository,
        PlanningRepository,
        InsightsRepository,
        JournalRepository,
        BackupRepository
    implements
        contracts.FinanceRepository,
        contracts.JournalRepository,
        contracts.SettingsRepository {
  static DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal() : _path = null, factory = null, credentials = const SecureCredentialStore();
  DatabaseService.atPath(this._path, {this.factory, CredentialStore? credentials}) : credentials = credentials ?? const SecureCredentialStore();
  @override
  final CredentialStore credentials;
  final String? _path;
  final DatabaseFactory? factory;
  Future<Database>? _opening;

  Database? _database;
  final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  @override
  Listenable get changes => changeNotifier;

  @override
  void notifyChanged() {
    changeNotifier.value++;
  }

  @override
  Future<Database> get database async {
    if (_database != null) return _database!;
    try {
      _database = await (_opening ??= _initDatabase());
      return _database!;
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  Future<Database> _initDatabase() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
    }

    final dbPath =
        _path ??
        p.join(
          (await getApplicationDocumentsDirectory()).path,
          'kwall',
          'kwall.db',
        );
    final dir = Directory(p.dirname(dbPath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final dbFactory =
        factory ??
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS
            ? databaseFactoryFfi
            : mobile.databaseFactorySqflitePlugin);
    if (dbPath != inMemoryDatabasePath && await File(dbPath).exists()) {
      final previous = await dbFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(readOnly: true),
      );
      try {
        final version = await previous.getVersion();
        if (version > DatabaseBackup.version) {
          throw StateError('Actualiza kwall para abrir esta base de datos.');
        }
        if (version < DatabaseBackup.version) {
          final backup = await previous.transaction(
            (txn) => DatabaseBackup.encode(txn, version),
          );
          await DatabaseBackup.writeRecovery(
            dbPath,
            backup,
            'before-v${DatabaseBackup.version}',
          );
        }
      } finally {
        await previous.close();
      }
    }
    return dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: DatabaseBackup.version,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
          await db.execute('PRAGMA synchronous = FULL');
          await db.execute('PRAGMA secure_delete = ON');
          await db.execute('PRAGMA busy_timeout = 5000');
          if (dbPath != inMemoryDatabasePath) {
            await db.rawQuery('PRAGMA journal_mode = WAL');
          }
        },
        onCreate: DatabaseSchema.create,
        onUpgrade: DatabaseSchema.upgrade,

      ),
    );
  }
}
