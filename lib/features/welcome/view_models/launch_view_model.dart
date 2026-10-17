import '../../../core/contracts/app_repositories.dart';
import '../../../core/mvvm/view_model.dart';

class LaunchViewModel extends ViewModel {
  final SettingsRepository repository;
  Map<String, String> settings = const {};
  bool ready = false;
  bool returning = false;
  LaunchViewModel(this.repository);
  Future<void> load() async {
    final request = beginRequest();
    error = null;
    changed();
    try {
      final data = await repository.getSettings();
      if (!isCurrent(request)) return;
      settings = Map.unmodifiable(data);
      ready = true;
      returning = data['welcome_seen'] == '1';
      changed();
    } catch (_) {
      if (isCurrent(request)) fail('No pudimos abrir tus datos.');
    }
  }

  Future<bool> enter({String? petStyle, String? petName}) => perform(() async {
        final updates = <String, String>{'welcome_seen': '1'};
        if (petStyle != null && petStyle.isNotEmpty) {
          updates['pet_style'] = petStyle;
        }
        if (petName != null && petName.trim().isNotEmpty) {
          updates['pet_name'] = petName.trim();
        }
        await repository.saveSettings(updates);
      });
}
