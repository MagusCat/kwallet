import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kwall/core/database/database_service.dart';
import 'package:kwall/features/bodega/models/budget_model.dart';
import 'package:kwall/features/bodega/models/finance_overview.dart';
import 'package:kwall/features/bodega/models/planned_expense.dart';
import 'package:kwall/features/bodega/models/transaction_record.dart';
import 'package:kwall/main.dart';
import 'package:kwall/core/database/database_backup.dart';
import 'package:kwall/features/journal/models/journal_models.dart';
import 'package:kwall/features/bodega/models/account.dart';
import 'package:kwall/features/bodega/models/transaction_filter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

PlannedExpense plan({String recurrence = 'monthly', DateTime? date}) =>
    PlannedExpense(
      id: 'rent',
      title: 'Alquiler',
      amount: 100,
      categoryId: 'cat_home',
      dueDate: date ?? DateTime(2026, 1, 31),
      recurrence: recurrence,
      createdAt: DateTime(2026),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  test(
    'Recurring projections preserve month ends and respect period boundaries',
    () {
      final rent = plan();
      final feb = rent.nextDate(rent.dueDate)!;
      expect(feb, DateTime(2026, 2, 28));
      expect(rent.nextDate(feb), DateTime(2026, 3, 31));
      expect(
        plannedTotal([rent], DateTime(2026, 2), DateTime(2026, 3, 31)),
        200,
      );
      expect(
        plannedTotal(
          [rent],
          DateTime(2026, 2),
          DateTime(2026, 2, 28),
          includeOverdue: true,
        ),
        200,
      );
      final weekly = plan(recurrence: 'weekly', date: DateTime(2026, 10, 5));
      expect(
        plannedTotal([weekly], DateTime(2026, 10, 5), DateTime(2026, 10, 11)),
        100,
      );
      final week = periodRange(BudgetPeriod.weekly, DateTime(2026, 10, 18));
      expect(week.start, DateTime(2026, 10, 12));
      expect(week.end, DateTime(2026, 10, 19));
      final budget = BudgetModel(
        id: 'b',
        month: 2,
        year: 2026,
        monthlyLimit: 280,
        weeklyLimit: 80,
        createdAt: DateTime(2026),
      );
      expect(budgetLimit(budget, BudgetPeriod.daily), 10);
      expect(budgetLimit(budget, BudgetPeriod.weekly), 80);
    },
  );

  test('Batch writes roll back together and recurring payment cannot be applied twice', () async {
    final service = DatabaseService.atPath(
      inMemoryDatabasePath,
      factory: databaseFactoryFfiNoIsolate,
    );
    final db = await service.database;
    addTearDown(db.close);
    await db.insert('accounts', {
      'id': 'cash',
      'name': 'Efectivo',
      'type': 'cash',
      'balance': 500,
      'opening_balance': 500,
      'currency': 'C\$',
      'icon_key': 'wallet',
      'color_value': 0xFF49453F,
      'created_at': DateTime(2026).toIso8601String(),
    });
    TransactionRecord tx(String id, double amount, {String account = 'cash'}) =>
        TransactionRecord(
          id: id,
          accountId: account,
          categoryId: 'cat_food',
          amount: amount,
          type: 'expense',
          date: DateTime(2026, 10, 16),
          createdAt: DateTime(2026),
        );
    await expectLater(
      service.addTransactions([
        tx('valid', 20),
        tx('bad', 30, account: 'missing'),
      ]),
      throwsStateError,
    );
    expect((await service.getAccounts()).single.balance, 500);
    expect(await service.getTransactions(), isEmpty);
    await service.addTransactions([tx('one', 20), tx('two', 30)]);
    expect((await service.getAccounts()).single.balance, 450);
    final spending = await service.getPeriodSpending(DateTime(2026, 10, 16));
    expect(spending.values, everyElement(50));
    final rent = plan();
    await service.addPlannedExpense(rent);
    await service.payPlannedExpense(
      rent.id,
      'cash',
      expectedDueDate: rent.dueDate,
    );
    await expectLater(
      service.payPlannedExpense(rent.id, 'cash', expectedDueDate: rent.dueDate),
      throwsStateError,
    );
    expect((await service.getAccounts()).single.balance, 350);
    expect(
      (await service.getPlannedExpenses()).single.dueDate,
      DateTime(2026, 2, 28),
    );
    await service.saveSettings({
      'currency': 'C\$',
      'mirror_currency': 'USD',
      'mirror_rate': '0.027',
    });
    expect((await service.getSettings())['mirror_currency'], 'USD');
  });

  test('Versions 2 and 3 survive the version 4 migration', () async {
    final directory = await Directory.systemTemp.createTemp('kwall-migration-');
    addTearDown(() => directory.delete(recursive: true));
    for (final legacyVersion in [2, 3]) {
      final path = '${directory.path}/legacy-$legacyVersion.db';
      final legacyService = DatabaseService.atPath(
        path,
        factory: databaseFactoryFfiNoIsolate,
      );
      final legacy = await legacyService.database;
      await legacy.insert('budgets', {
        'id': 'legacy',
        'month': 10,
        'year': 2025,
        'monthly_limit': 900,
        'created_at': '2025-10-01',
      });
      await legacyService.addPlannedExpense(plan());
      await legacyService.createAccount(
        Account(
          id: 'cash',
          name: 'Efectivo',
          type: 'cash',
          balance: 123,
          createdAt: DateTime(2025),
        ),
      );
      await legacyService.saveSettings({'quick_notes': 'No olvidar mi recibo'});
      for (final column
          in legacyVersion == 2
              ? ['weekly_limit', 'daily_limit']
              : <String>[]) {
        await legacy.execute('ALTER TABLE budgets DROP COLUMN $column');
      }
      for (final column in ['minimum_balance', 'opening_balance']) {
        await legacy.execute('ALTER TABLE accounts DROP COLUMN $column');
      }
      if (legacyVersion == 2) {
        await legacy.execute(
          'ALTER TABLE planned_expenses DROP COLUMN recurrence_day',
        );
      }
      for (final table in [
        'habit_logs',
        'reward_events',
        'habits',
        'personal_notes',
        'budget_allocations',
        'transaction_archive',
      ]) {
        await legacy.execute('DROP TABLE $table');
      }
      await legacy.setVersion(legacyVersion);
      await legacy.close();
      final service = DatabaseService.atPath(path);
      final db = await service.database;
      addTearDown(db.close);
      expect(
        (await db.query(
          'budgets',
          where: 'id = ?',
          whereArgs: ['legacy'],
        )).single['monthly_limit'],
        900,
      );
      expect((await service.getAccounts()).single.openingBalance, 123);
      expect((await service.getNotes()).single.body, 'No olvidar mi recibo');
      expect(await service.getRecoveryFiles(), hasLength(1));
      await service.verifyDataIntegrity();
      expect((await service.getPlannedExpenses()).single.recurrenceDay, 31);
      expect(
        (await db.rawQuery('PRAGMA table_info(budgets)'))
            .map((row) => row['name']),
        containsAll(['daily_limit', 'weekly_limit']),
      );
    }
  });

  test('Portable backups preserve all features and failed restores leave data intact', () async {
    final directory = await Directory.systemTemp.createTemp('kwall-backup-');
    addTearDown(() => directory.delete(recursive: true));
    final service = DatabaseService.atPath(
      '${directory.path}/data.db',
      factory: databaseFactoryFfiNoIsolate,
    );
    final db = await service.database;
    addTearDown(db.close);
    await service.createAccount(
      Account(
        id: 'cash',
        name: 'Efectivo',
        type: 'cash',
        balance: 1000,
        minimumBalance: 200,
        createdAt: DateTime.now(),
      ),
    );
    await service.saveSettings({
      'palette': 'plum',
      'currency': 'C\$',
      'pet_style': 'custom',
      'pet_image_data': base64Encode(await File('cat.png').readAsBytes()),
    });
    final day = DateTime.now();
    await service.allocateBudget(
      BudgetPeriod.weekly,
      day,
      125,
      mode: 'assigned',
    );
    await service.saveNote(
      PersonalNote(
        id: 'n',
        title: 'Mis pendientes',
        kind: 'list',
        items: const [NoteItem('Recibo', done: true)],
        updatedAt: day,
      ),
    );
    await service.saveHabit('h', 'Caminar');
    await service.logHabit('h', day, completed: true, mood: 'happy');
    await service.logHabit('h', day, completed: true, mood: 'happy');
    expect(await service.getExperience(), 15);
    final habit = (await service.getHabits()).single;
    expect(habit.streak(day), 1);
    await service.logHabit(
      'h',
      day.subtract(const Duration(days: 1)),
      completed: false,
      mood: 'tired',
      reason: 'Dormí poco',
    );
    final previousDays = [
      DateTime(day.year, day.month, day.day - 2),
      DateTime(day.year, day.month, day.day - 3),
    ];
    await expectLater(
      service.logHabitDays(['h', 'missing'], previousDays, completed: true),
      throwsStateError,
    );
    expect((await service.getHabits()).single.logs.length, 2);
    expect(await service.getExperience(), 15);
    await service.logHabitDays(['h'], previousDays, completed: true);
    await service.logHabitDays(['h'], previousDays, completed: true);
    expect((await service.getHabits()).single.logs.length, 4);
    expect(await service.getExperience(), 35);
    await expectLater(
      service.logHabitDays(
        ['h'],
        [day, DateTime(day.year, day.month, day.day + 1)],
        completed: true,
      ),
      throwsArgumentError,
    );
    await expectLater(
      service.setNoteItem('n', 0, false, expectedText: 'Stale item'),
      throwsStateError,
    );
    expect((await service.getNotes()).single.items.single.done, true);
    final source = await service.exportFullDataAsJson();
    expect(jsonDecode(source)['version'], DatabaseBackup.version);
    final broken = jsonDecode(source) as Map<String, dynamic>;
    broken['data']['accounts'][0]['balance'] = 1;
    await expectLater(
      service.importFullDataFromJson(jsonEncode(broken)),
      throwsFormatException,
    );
    final future = jsonDecode(source) as Map<String, dynamic>;
    future['version'] = 999;
    await expectLater(
      service.importFullDataFromJson(jsonEncode(future)),
      throwsFormatException,
    );
    await service.deleteNote('n');
    await service.importFullDataFromJson(source);
    expect((await service.getNotes()).single.items.single.done, true);
    expect(
      (await service.getHabits()).single.logs
          .firstWhere((l) => !l.completed)
          .reason,
      'Dormí poco',
    );
    expect((await service.getBudgetAllocations(day))[BudgetPeriod.weekly], 125);
    expect((await service.getAccounts()).single.minimumBalance, 200);
    expect((await service.getSettings())['palette'], 'plum');
    expect(
      (await service.getSettings())['pet_image_data'],
      base64Encode(await File('cat.png').readAsBytes()),
    );
    await service.verifyDataIntegrity();
    expect(await service.getRecoveryFiles(), isNotEmpty);
    await db.execute(
      "CREATE TRIGGER reject_restore BEFORE INSERT ON habits BEGIN SELECT RAISE(ABORT, 'simulated interruption'); END",
    );
    await expectLater(
      service.importFullDataFromJson(source),
      throwsA(isA<DatabaseException>()),
    );
    expect((await service.getAccounts()).single.balance, 1000);
    expect((await service.getNotes()).single.id, 'n');
    expect((await service.getHabits()).single.id, 'h');
    await db.execute('DROP TRIGGER reject_restore');
    final legacy = jsonDecode(source) as Map<String, dynamic>;
    legacy['version'] = 3;
    legacy.remove('checksum');
    for (final table in [
      'personal_notes',
      'habits',
      'habit_logs',
      'reward_events',
      'budget_allocations',
    ]) {
      legacy['data'].remove(table);
    }
    legacy['data']['accounts'][0].remove('opening_balance');
    legacy['data']['accounts'][0].remove('minimum_balance');
    legacy['data']['app_settings'].add({
      'key': 'quick_notes',
      'value': 'Nota de una versión anterior',
    });
    await service.importFullDataFromJson(jsonEncode(legacy));
    expect(
      (await service.getNotes()).single.body,
      'Nota de una versión anterior',
    );
    await service.verifyDataIntegrity();
  });

  test(
    'Long histories page without gaps and totals include every matching record',
    () async {
      final service = DatabaseService.atPath(
        inMemoryDatabasePath,
        factory: databaseFactoryFfiNoIsolate,
      );
      final db = await service.database;
      addTearDown(db.close);
      await service.createAccount(
        Account(
          id: 'a',
          name: 'A',
          type: 'cash',
          balance: 1000,
          createdAt: DateTime(2020),
        ),
      );
      final records = [
        for (var i = 0; i < 130; i++)
          TransactionRecord(
            id: 't$i',
            accountId: 'a',
            categoryId: 'cat_food',
            amount: .1,
            type: 'expense',
            note: i == 0 ? '100% real' : 'Registro $i',
            date: DateTime(2020 + (i % 6), 1, 10),
            createdAt: DateTime.now(),
          ),
      ];
      await service.addTransactions(records);
      await db.update(
        'transactions',
        {'date': '2020-01-10'},
        where: 'id = ?',
        whereArgs: ['t0'],
      );
      const filter = TransactionFilter();
      final all = <String>[];
      TransactionRecord? before;
      while (true) {
        final page = await service.getTransactionPage(filter, before: before);
        if (page.isEmpty) break;
        all.addAll(page.map((r) => r.id));
        before = page.last;
      }
      expect(
        (await service.getTransactionTotals(
          TransactionFilter(
            start: DateTime(2020, 1, 10),
            end: DateTime(2020, 1, 10),
          ),
        )).count,
        22,
      );
      expect(all.length, 130);
      expect(all.toSet().length, 130);
      final totals = await service.getTransactionTotals(filter);
      expect(totals.count, 130);
      expect(totals.expense, closeTo(13, .000001));
      expect(
        (await service.getTransactionTotals(
          const TransactionFilter(search: '100%'),
        )).count,
        1,
      );
      expect(await service.getMonthlyHistory(filter), hasLength(6));
      await service.verifyDataIntegrity();
      expect(
        flexibleBudget(
          spent: 20,
          balance: 980,
          reserves: 200,
          commitments: 100,
          share: 50,
        ),
        360,
      );
    },
  );

  testWidgets('Main flows render on compact and wide screens', (tester) async {
    if (const bool.fromEnvironment('KWALL_CAPTURE')) {
      await tester.runAsync(() async {
        final config = File('.dart_tool/package_config.json').absolute;
        final packages =
            (jsonDecode(await config.readAsString()) as Map)['packages']
                as List;
        final flutter =
            packages.firstWhere((p) => p['name'] == 'flutter') as Map;
        final root = Directory.fromUri(
          config.uri.resolve(flutter['rootUri'] as String),
        ).parent.parent.path;
        final fontDir = '$root/bin/cache/artifacts/material_fonts';
        for (final entry in {
          'Roboto': ['Roboto-Regular.ttf', 'Roboto-Bold.ttf'],
          'MaterialIcons': ['MaterialIcons-Regular.otf'],
        }.entries) {
          final loader = FontLoader(entry.key);
          for (final file in entry.value) {
            loader.addFont(
              File('$fontDir/$file')
                  .readAsBytes()
                  .then((bytes) => ByteData.sublistView(bytes)),
            );
          }
          await loader.load();
        }
      });
    }
    final service = DatabaseService.atPath(
      inMemoryDatabasePath,
      factory: databaseFactoryFfiNoIsolate,
    );
    DatabaseService.instance = service;
    await tester.runAsync(() async {
      final db = await service.database;
      final now = DateTime.now();
      await db.insert('accounts', {
        'id': 'cash',
        'name': 'Efectivo',
        'type': 'cash',
        'balance': 800,
        'opening_balance': 800,
        'minimum_balance': 150,
        'currency': 'C\$',
        'icon_key': 'wallet',
        'color_value': 0xFF49453F,
        'created_at': now.toIso8601String(),
      });
      await service.addPlannedExpense(
        plan(date: DateTime(now.year, now.month, now.day + 1)),
      );
      await service.addPlannedExpense(
        PlannedExpense(
          id: 'birthday',
          title: 'Cumpleaños',
          amount: 0,
          dueDate: DateTime(now.year, now.month, now.day + 3),
          recurrence: 'yearly',
          categoryId: 'cat_other',
          createdAt: now,
        ),
      );
      await service.saveBudget(monthly: 1200, weekly: 300, daily: 40);
      await service.saveSettings({
        'currency': 'C\$',
        'mirror_currency': 'USD',
        'mirror_rate': '0.027',
        'pet_image': '',
        'welcome_seen': '1',
        'plan_range_start': DateTime(
          now.year,
          now.month,
          now.day,
        ).toIso8601String(),
        'plan_range_end': DateTime(
          now.year,
          now.month,
          now.day + 6,
        ).toIso8601String(),
      });
      await service.saveNote(
        PersonalNote(
          id: 'demo-note',
          title: 'Antes del fin de semana',
          kind: 'list',
          items: const [
            NoteItem('Guardar recibos'),
            NoteItem('Revisar mi presupuesto', done: true),
          ],
          updatedAt: now,
        ),
      );
      await service.saveHabit('demo-habit', 'Caminar 15 minutos');
    });
    addTearDown(() async => (await service.database).close());
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final captureKey = GlobalKey();
    Future<void> capture(String name) async {
      if (!const bool.fromEnvironment('KWALL_CAPTURE')) return;
      final boundary =
          captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('.impeccable/review/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    for (final size in [const Size(390, 844), const Size(1024, 900)]) {
      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.physicalSize = size;
      await tester.runAsync(() async {
        await tester.pumpWidget(
          RepaintBoundary(key: captureKey, child: const KwallApp()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      for (
        var i = 0;
        i < 30 && find.text('Bienvenido').evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(find.text('Bienvenido'), findsOneWidget);
      expect(tester.takeException(), isNull);
      final name = size.width < 600 ? 'phone' : 'tablet';
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 150)),
      );
      await tester.pump();
      await capture('$name-home');
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();
      await capture('$name-accounts');
      await tester.ensureVisible(find.text('Notas').first);
      await tester.tap(find.text('Notas').first);
      await tester.pumpAndSettle();
      expect(
        find.text('Antes del fin de semana').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await capture('$name-home-notes');
      await tester.tap(find.text('Hábitos').first);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Marcar como hecho').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture('$name-home-habits');
      await tester.tap(find.text('Cuentas').first);
      await tester.pumpAndSettle();
      if (size.width < 600) {
        await tester.tap(find.text('Efectivo').first);
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final backup = jsonDecode(
            await service.exportFullDataAsJson(),
          ) as Map<String, dynamic>;
          backup['version'] = 3;
          backup.remove('checksum');
          backup['data']['accounts'][0]['id'] = 'restored-cash';
          await service.importFullDataFromJson(jsonEncode(backup));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
      }
      await tester.drag(find.byType(ListView).first, const Offset(0, 1000));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byTooltip('Finanzas'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Ingreso'));
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('Nuevo movimiento'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture('$name-income');
      await tester.tap(find.byTooltip('Cerrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Agenda'));
      await tester.pumpAndSettle();
      expect(find.text('Rango'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture('$name-planning');
      await tester.tap(find.byTooltip('Mi espacio'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Antes del fin de semana').hitTestable(),
        findsOneWidget,
      );
      await capture('$name-notes');
      await tester.tap(find.text('Hábitos').hitTestable());
      await tester.pumpAndSettle();
      expect(find.text('Caminar 15 minutos').hitTestable(), findsOneWidget);
      await capture('$name-habits');
      await tester.tap(find.byTooltip('Ajustes'));
      await tester.pumpAndSettle();
      expect(find.text('Monedas'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture('$name-settings');
      await tester.runAsync(() async {
        await tester.tap(find.text('Oscuro'));
        await Future<void>.delayed(const Duration(milliseconds: 120));
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture('$name-dark-settings');
      await tester.tap(find.byTooltip('Inicio'));
      await tester.pumpAndSettle();
      await capture('$name-dark-home');
      await tester.runAsync(() async {
        await service.saveSettings({'theme_mode': 'light'});
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Inicio'));
      await tester.pumpAndSettle();
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
