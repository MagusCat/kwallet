import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kwall/core/database/database_backup.dart';
import 'package:kwall/core/database/database_schema.dart';
import 'package:kwall/core/database/repositories/currency_rates_repository.dart';
import 'package:kwall/core/services/notification_service.dart';

void main() {
  setUpAll(() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
    }
  });

  group('CurrencyRatesRepository Conversion Logic', () {
    const dominant = 'C\$';
    final rates = <String, double>{
      'USD': 36.80,
      'EUR': 40.00,
    };

    test('Same currency returns exact amount', () {
      final res = CurrencyRatesRepository.convert(
        100.0,
        from: 'USD',
        to: 'USD',
        rates: rates,
        dominantCurrency: dominant,
      );
      expect(res, 100.0);
    });

    test('Converts from alternative currency to dominant currency', () {
      final res = CurrencyRatesRepository.convert(
        100.0,
        from: 'USD',
        to: dominant,
        rates: rates,
        dominantCurrency: dominant,
      );
      expect(res, closeTo(3680.0, 0.001));
    });

    test('Converts from dominant currency to alternative currency', () {
      final res = CurrencyRatesRepository.convert(
        3680.0,
        from: dominant,
        to: 'USD',
        rates: rates,
        dominantCurrency: dominant,
      );
      expect(res, closeTo(100.0, 0.001));
    });

    test('Converts between two alternative currencies through dominant currency', () {
      // 100 EUR = 4000 C$ = 4000 / 36.80 USD = 108.6956 USD
      final res = CurrencyRatesRepository.convert(
        100.0,
        from: 'EUR',
        to: 'USD',
        rates: rates,
        dominantCurrency: dominant,
      );
      expect(res, closeTo(108.6956, 0.01));
    });
  });

  group('CurrencyRatesRepository Database and Traceability', () {
    late Database db;
    late CurrencyRatesRepository repo;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      await DatabaseSchema.create(db, DatabaseBackup.version);
      repo = CurrencyRatesRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('setRate inserts and records initial history entry', () async {
      await repo.setRate(currency: 'USD', rate: 36.80, notes: 'Initial rate');
      final rates = await repo.getRates();
      expect(rates['USD'], 36.80);

      final history = await repo.getHistory(currency: 'USD');
      expect(history.length, 1);
      expect(history.first['previous_rate'], isNull);
      expect(history.first['new_rate'], 36.80);
      expect(history.first['notes'], 'Initial rate');
    });

    test('setRate records update traceability with previous rate', () async {
      await repo.setRate(currency: 'USD', rate: 36.50, notes: 'Day 1');
      await repo.setRate(currency: 'USD', rate: 36.80, notes: 'Day 2 update');

      final rates = await repo.getRates();
      expect(rates['USD'], 36.80);

      final history = await repo.getHistory(currency: 'USD');
      expect(history.length, 2);
      expect(history.first['previous_rate'], 36.50);
      expect(history.first['new_rate'], 36.80);
      expect(history.first['notes'], 'Day 2 update');
    });

    test('removeRate deletes rate from current rates', () async {
      await repo.setRate(currency: 'EUR', rate: 40.0);
      expect((await repo.getRates()).containsKey('EUR'), isTrue);

      await repo.removeRate('EUR');
      expect((await repo.getRates()).containsKey('EUR'), isFalse);
    });
  });

  group('NotificationService Permissions & Settings Checks', () {
    test('showNotification returns false when notifications_enabled is false', () async {
      final res = await NotificationService.showNotification(
        id: 1,
        title: 'Test',
        body: 'Body',
        type: 'habits',
        settings: {'notifications_enabled': 'false'},
      );
      expect(res, isFalse);
    });

    test('showNotification returns false when category is disabled', () async {
      final resHabits = await NotificationService.showNotification(
        id: 1,
        title: 'Test',
        body: 'Body',
        type: 'habits',
        settings: {'notifications_enabled': 'true', 'notify_habits': 'false'},
      );
      expect(resHabits, isFalse);

      final resFinances = await NotificationService.showNotification(
        id: 2,
        title: 'Test',
        body: 'Body',
        type: 'finances',
        settings: {'notifications_enabled': 'true', 'notify_finances': 'false'},
      );
      expect(resFinances, isFalse);

      final resPet = await NotificationService.showPetVisualNotification(
        petName: 'Mishi',
        visualIcon: '[♥]',
        settings: {'notifications_enabled': 'true', 'notify_pet': 'false'},
      );
      expect(resPet, isFalse);
    });
  });
}
