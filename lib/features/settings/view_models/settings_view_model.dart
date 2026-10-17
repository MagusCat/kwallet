import '../../../core/contracts/app_repositories.dart';
import '../../../core/models/amount.dart';
import '../../../core/models/backup_preview.dart';
import '../../../core/models/recovery_copy.dart';
import '../../../core/mvvm/view_model.dart';
import '../../../core/services/device_files.dart';

class SettingsViewModel extends ViewModel {
  final SettingsRepository repository;
  final DeviceFiles files;
  Map<String, String> settings = const {};
  List<RecoveryCopy> recoveries = const [];
  bool loading = true;
  bool _backupOperation = false;
  bool get backupBusy => busy && _backupOperation;
  String? _pendingRestore;
  SettingsViewModel(this.repository, this.files);
  Future<void> load() async {
    final request = beginRequest();
    try {
      final data = await repository.getSettings();
      if (!isCurrent(request)) return;
      settings = Map.unmodifiable(data);
      loading = false;
      error = null;
      changed();
    } catch (_) {
      if (isCurrent(request)) {
        loading = false;
        fail('No se pudieron cargar tus ajustes.');
      }
    }
  }

  Future<void> _write(Map<String, String> values) async {
    await repository.saveSettings(values);
    if (!disposed) settings = Map.unmodifiable({...settings, ...values});
  }

  Future<bool> appearance(String key, String value) async {
    if (disposed) return false;
    settings = Map.unmodifiable({...settings, key: value});
    changed();
    try {
      await repository.saveSettings({key: value});
      return true;
    } catch (_) {
      if (!disposed) {
        error = 'No se pudo guardar la preferencia.';
        changed();
      }
      return false;
    }
  }
  Future<bool> save({
    required String currency,
    required bool mirrorEnabled,
    required String mirror,
    required String rateText,
    required String petName,
  }) {
    final rate = parseAmount(rateText);
    if (currency.trim().isEmpty ||
        (mirrorEnabled &&
            (mirror.trim().isEmpty || rate == null || rate <= 0))) {
      return Future.value(fail('Revisa el símbolo y la tasa de conversión.'));
    }
    return perform(
      () => _write({
        'currency': currency.trim(),
        'mirror_currency': mirrorEnabled ? mirror.trim() : '',
        'mirror_rate': mirrorEnabled ? rate.toString() : '',
        'pet_name': petName.trim().isEmpty ? 'Mishi' : petName.trim(),
      }),
    );
  }

  Future<bool> _backup(
    Future<void> Function() action, {
    required String failure,
  }) async {
    if (busy) return false;
    _backupOperation = true;
    try {
      return await perform(action, failure: failure);
    } finally {
      _backupOperation = false;
    }
  }

  Future<bool> export() async {
    var saved = false;
    final ok = await _backup(() async {
      final content = await repository.exportFullDataAsJson();
      saved = await files.saveBackup(
        content,
        'kwall-${DateTime.now().toIso8601String().substring(0, 10)}.json',
      );
    }, failure: 'No se pudo guardar el respaldo. Reintenta.');
    return ok && saved;
  }

  Future<BackupPreview?> prepareRestore({String? recovery}) async {
    BackupPreview? preview;
    _pendingRestore = null;
    await _backup(() async {
      final content = recovery == null
          ? await files.pickBackup()
          : await repository.readRecoveryCopy(recovery);
      if (content == null) return;
      preview = BackupPreview.fromCounts(
        await repository.inspectBackup(content),
      );
      _pendingRestore = content;
    }, failure: 'No pudimos leer ese respaldo. Elige otro archivo.');
    return preview;
  }

  void discardRestore() {
    _pendingRestore = null;
  }

  Future<bool> restore() async {
    final content = _pendingRestore;
    if (content == null) return false;
    final restored = await _backup(
      () => repository.importFullDataFromJson(content),
      failure:
          'No pudimos restaurar el respaldo. Tus datos actuales se conservan.',
    );
    if (restored) {
      _pendingRestore = null;
      await load();
    }
    return restored;
  }

  Future<bool> loadRecoveries() => _backup(() async {
    final data = await repository.getRecoveryCopies();
    if (!disposed) recoveries = List.unmodifiable(data);
  }, failure: 'No se pudieron abrir las copias de recuperación.');
  Future<bool> choosePet(String style) async {
    if (disposed) return false;
    settings =
        Map.unmodifiable({...settings, 'pet_style': style, 'pet_image': ''});
    changed();
    try {
      await repository.saveSettings({'pet_style': style, 'pet_image': ''});
      return true;
    } catch (_) {
      if (!disposed) {
        error = 'No se pudo guardar la mascota.';
        changed();
      }
      return false;
    }
  }
  Future<bool> uploadPet() async {
    var selected = false;
    final ok = await perform(
      () async {
        final data = await files.pickPetImage();
        if (data == null) return;
        await _write({
          'pet_style': 'custom',
          'pet_image_data': data,
          'pet_image': '',
        });
        selected = true;
      },
      failure: 'No pudimos abrir esa imagen. Usa una imagen fija de hasta 4 MB y 2048 × 2048.',
    );
    return ok && selected;
  }

  @override
  void dispose() {
    _pendingRestore = null;
    super.dispose();
  }
}
