import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kwall/core/database/database_backup.dart';
import 'package:kwall/core/database/database_service.dart';
import 'package:kwall/core/widgets/pet_loading_screen.dart';
import 'package:kwall/features/bodega/models/account.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  group('DatabaseService Defensive PRAGMA and Integrity Tests', () {
    late Directory tempDir;
    late String dbPath;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('kwall_db_test_');
      dbPath = '${tempDir.path}/test_kwall.db';
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('initializes database with defensive pragmas and passes integrity check', () async {
      final service = DatabaseService.atPath(dbPath, factory: databaseFactoryFfi);
      final db = await service.database;
      expect(db.isOpen, isTrue);

      final integrity = await service.checkDatabaseIntegrity();
      expect(integrity, 'ok');

      await service.closeAndReset();
    });

    test('repairOrResetDatabase moves damaged database to .corrupted and creates clean DB', () async {
      final service = DatabaseService.atPath(dbPath, factory: databaseFactoryFfi);
      final db = await service.database;
      await db.execute("INSERT INTO app_settings (key, value) VALUES ('test_key', 'test_value')");
      
      final savedValue = await service.getSettings();
      expect(savedValue['test_key'], 'test_value');

      await service.repairOrResetDatabase();

      // Corrupted file should exist in directory
      final files = await tempDir.list().toList();
      final hasCorrupted = files.any((f) => f.path.contains('.corrupted-'));
      expect(hasCorrupted, isTrue);

      // New database should be fresh and empty of test_key
      final newSettings = await service.getSettings();
      expect(newSettings['test_key'], isNull);

      await service.closeAndReset();
    });

    test('hasRecoveryCopies detects pre-migration backup and restoreLatestRecoveryCopy restores it', () async {
      final service = DatabaseService.atPath(dbPath, factory: databaseFactoryFfi);
      await service.database;

      // Seed an account
      await service.createAccount(Account(
        id: 'acc-1',
        name: 'Billetera Principal',
        type: 'cash',
        balance: 150.0,
        currency: 'USD',
        createdAt: DateTime.now(),
      ));

      // Encode backup and write recovery snapshot
      final backup = await service.exportFullDataAsJson();
      await DatabaseBackup.writeRecovery(dbPath, backup, 'before-v5');

      expect(await service.hasRecoveryCopies(), isTrue);

      // Now wipe the current DB
      await service.repairOrResetDatabase();
      final wipedAccounts = await service.getAccounts();
      expect(wipedAccounts.isEmpty, isTrue);

      // Restore from recovery snapshot
      final restored = await service.restoreLatestRecoveryCopy();
      expect(restored, isTrue);

      final restoredAccounts = await service.getAccounts();
      expect(restoredAccounts.length, 1);
      expect(restoredAccounts.first.name, 'Billetera Principal');

      await service.closeAndReset();
    });
  });

  group('PetLoadingScreen Failure & Diagnostic UI Tests', () {
    testWidgets('renders recovery and repair buttons when failed with recovery available', (tester) async {
      var retryCalled = false;
      var restoreCalled = false;
      var repairCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: PetLoadingScreen(
            failed: true,
            hasRecovery: true,
            diagnosticInfo: 'DatabaseException: Mock database lock',
            onRetry: () => retryCalled = true,
            onRestoreRecovery: () => restoreCalled = true,
            onRepairDatabase: () => repairCalled = true,
          ),
        ),
      );

      expect(find.text('No pudimos abrir tus datos'), findsOneWidget);
      expect(find.text('Reintentar conexión'), findsOneWidget);
      expect(find.text('Restaurar copia previa'), findsOneWidget);
      expect(find.text('Reparar base de datos'), findsOneWidget);
      expect(find.text('Ver detalle técnico'), findsOneWidget);

      // Tap Retry
      await tester.tap(find.text('Reintentar conexión'));
      expect(retryCalled, isTrue);

      // Tap Ver detalle técnico
      await tester.tap(find.text('Ver detalle técnico'));
      await tester.pumpAndSettle();
      expect(find.text('Detalle técnico del error'), findsOneWidget);
      expect(find.textContaining('Mock database lock'), findsOneWidget);

      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      // Tap Restaurar copia previa -> opens confirmation dialog
      await tester.tap(find.text('Restaurar copia previa'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Se creará un respaldo del archivo actual'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Restaurar'));
      await tester.pumpAndSettle();
      expect(restoreCalled, isTrue);

      // Tap Reparar base de datos -> opens confirmation dialog
      await tester.tap(find.text('Reparar base de datos'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Se guardará tu base actual dañada'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Reparar'));
      await tester.pumpAndSettle();
      expect(repairCalled, isTrue);
    });
  });
}
