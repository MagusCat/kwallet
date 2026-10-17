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
  });
}
