import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kwall/core/contracts/app_repositories.dart';
import 'package:kwall/core/models/recovery_copy.dart';
import 'package:kwall/features/welcome/view_models/launch_view_model.dart';

class FakeSettingsRepository implements SettingsRepository {
  String? _token;
  @override
  Future<String?> getGitHubToken() async => _token;
  @override
  Future<void> saveGitHubToken(String? token) async { _token = token; }

  final Map<String, String> data = {};
  final ValueNotifier<int> _changes = ValueNotifier<int>(0);
  @override
  Listenable get changes => _changes;

  @override
  Future<Map<String, String>> getSettings() async => Map.from(data);

  @override
  Future<void> saveSettings(Map<String, String> values) async {
    data.addAll(values);
    _changes.value++;
  }

  @override
  Future<String> exportFullDataAsJson() async => '{}';

  @override
  Future<Map<String, int>> inspectBackup(String content) async => {};

  @override
  Future<void> importFullDataFromJson(String content) async {}

  @override
  Future<List<RecoveryCopy>> getRecoveryCopies() async => [];

  @override
  Future<String> readRecoveryCopy(String id) async => '{}';

  @override
  Future<Map<String, double>> getCurrencyRates() async => {};

  @override
  Future<void> setCurrencyRate({
    required String currency,
    required double rate,
    String notes = '',
  }) async {}

  @override
  Future<void> removeCurrencyRate(String currency) async {}

  @override
  Future<List<Map<String, dynamic>>> getCurrencyRateHistory({String? currency}) async => [];

  @override
  Future<bool> hasRecoveryCopies() async => false;

  @override
  Future<bool> restoreLatestRecoveryCopy() async => true;

  @override
  Future<void> repairOrResetDatabase() async {}

  @override
  Future<String> checkDatabaseIntegrity() async => 'ok';
}

void main() {
  group('LaunchViewModel Start Flow Tests', () {
    test('enter saves selected petStyle, petName, currency, and referenceCurrencies', () async {
      final repo = FakeSettingsRepository();
      final vm = LaunchViewModel(repo);

      await vm.load();
      expect(vm.returning, false);

      final entered = await vm.enter(
        petStyle: 'calico',
        petName: 'Manchitas',
        currency: 'USD',
        referenceCurrencies: 'EUR,NIO',
      );
      expect(entered, true);
      expect(repo.data['welcome_seen'], '1');
      expect(repo.data['pet_style'], 'calico');
      expect(repo.data['pet_name'], 'Manchitas');
      expect(repo.data['currency'], 'USD');
      expect(repo.data['reference_currencies'], 'EUR,NIO');
    });

    test('enter defaults gracefully when parameters are omitted', () async {
      final repo = FakeSettingsRepository();
      final vm = LaunchViewModel(repo);

      await vm.load();
      final entered = await vm.enter();
      expect(entered, true);
      expect(repo.data['welcome_seen'], '1');
    });

    test('load failure sets error, diagnosticInfo, and checks recovery copies', () async {
      final repo = FailingSettingsRepository();
      final vm = LaunchViewModel(repo);

      await vm.load();
      expect(vm.ready, isFalse);
      expect(vm.error, 'No pudimos abrir tus datos.');
      expect(vm.diagnosticInfo, contains('Simulated database disk failure'));
      expect(vm.hasRecovery, isTrue);
    });

    test('restoreRecovery calls repository.restoreLatestRecoveryCopy and reloads', () async {
      final repo = RecoverableSettingsRepository();
      final vm = LaunchViewModel(repo);

      await vm.load();
      expect(vm.ready, isFalse);

      final restored = await vm.restoreRecovery();
      expect(restored, isTrue);
      expect(vm.ready, isTrue);
      expect(repo.restoredCalled, isTrue);
    });

    test('repairDatabase calls repository.repairOrResetDatabase and reloads', () async {
      final repo = RecoverableSettingsRepository();
      final vm = LaunchViewModel(repo);

      await vm.load();
      expect(vm.ready, isFalse);

      final repaired = await vm.repairDatabase();
      expect(repaired, isTrue);
      expect(vm.ready, isTrue);
      expect(repo.repairCalled, isTrue);
    });
  });
}

class FailingSettingsRepository extends FakeSettingsRepository {
  @override
  Future<Map<String, String>> getSettings() async {
    throw StateError('Simulated database disk failure');
  }

  @override
  Future<bool> hasRecoveryCopies() async => true;
}

class RecoverableSettingsRepository extends FakeSettingsRepository {
  bool failNext = true;
  bool restoredCalled = false;
  bool repairCalled = false;

  @override
  Future<Map<String, String>> getSettings() async {
    if (failNext) {
      throw StateError('Database opening failed');
    }
    return {'welcome_seen': '1'};
  }

  @override
  Future<bool> hasRecoveryCopies() async => true;

  @override
  Future<bool> restoreLatestRecoveryCopy() async {
    restoredCalled = true;
    failNext = false;
    return true;
  }

  @override
  Future<void> repairOrResetDatabase() async {
    repairCalled = true;
    failNext = false;
  }
}
