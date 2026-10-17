import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../models/recovery_copy.dart';
import '../database_backup.dart';
import '../database_schema.dart';
import '../database_context.dart';

mixin BackupRepository on DatabaseContext {
  Future<List<File>> getRecoveryFiles() async {
    final db = await database;
    if (db.path == inMemoryDatabasePath) return [];
    final directory = Directory(p.dirname(db.path));
    final files = await directory
        .list()
        .where(
          (file) =>
              file is File &&
              file.path.startsWith('${db.path}.before-') &&
              file.path.endsWith('.json'),
        )
        .cast<File>()
        .toList();
    files.sort((a, b) => b.path.compareTo(a.path));
    return files;
  }

  Future<List<RecoveryCopy>> getRecoveryCopies() async => [
    for (final file in await getRecoveryFiles())
      RecoveryCopy(
        id: file.path,
        createdAt: DateTime.fromMicrosecondsSinceEpoch(
          int.parse(file.path.split('-').last.split('.').first),
        ).toLocal(),
        beforeUpdate: file.path.contains('before-v'),
      ),
  ];

  Future<String> readRecoveryCopy(String id) async {
    final files = await getRecoveryFiles();
    final file = files.where((file) => file.path == id).firstOrNull;
    if (file == null) throw StateError('La copia ya no está disponible');
    return file.readAsString();
  }

  String? lastRecoveryPath;

  Future<String> exportFullDataAsJson() async {
    final db = await database;
    return db.transaction(
      (txn) => DatabaseBackup.encode(txn, DatabaseBackup.version),
    );
  }

  Future<Map<String, int>> inspectBackup(String content) async {
    final data = DatabaseBackup.decode(content);
    final db = await database;
    await DatabaseBackup.validateColumns(db, data);
    return data.map((key, rows) => MapEntry(key, rows.length));
  }

  Future<void> importFullDataFromJson(String jsonContent) async {
    final data = DatabaseBackup.decode(jsonContent);
    final db = await database;
    await db.transaction((txn) async {
      await DatabaseBackup.validateColumns(txn, data);
      if (db.path != inMemoryDatabasePath) {
        final recovery = await DatabaseBackup.encode(
          txn,
          DatabaseBackup.version,
        );
        lastRecoveryPath = await DatabaseBackup.writeRecovery(
          db.path,
          recovery,
          'before-restore',
        );
      }
      final localConnection = await txn.query('app_settings', where: "key LIKE 'github_%' AND key != 'github_token'");
      for (final table in DatabaseBackup.deleteOrder) {
        await txn.delete(table);
      }
      for (final table in DatabaseBackup.tables) {
        for (final row in data[table]!) {
          await txn.insert(table, row);
        }
      }
      for (final row in localConnection) { await txn.insert('app_settings', row); }
      for (final row in data['accounts']!.where(
        (row) => !row.containsKey('opening_balance'),
      )) {
        await DatabaseSchema.backfillOpeningBalances(
          txn,
          accountId: row['id'] as String,
        );
      }
      if ((await txn.rawQuery('PRAGMA foreign_key_check')).isNotEmpty) {
        throw const FormatException(
          'El respaldo contiene referencias incompletas.',
        );
      }
    });
    notifyChanged();
  }
}
