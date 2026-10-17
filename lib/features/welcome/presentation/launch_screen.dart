import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/mvvm/view_model_state.dart';
import '../view_models/launch_view_model.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/finance_widgets.dart';
import '../../../core/widgets/kitty_companion.dart';
import '../../../core/widgets/pet_loading_screen.dart';
import '../../bodega/presentation/bodega_screen.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});
  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends ViewModelState<LaunchScreen, LaunchViewModel> {
  @override
  LaunchViewModel createViewModel(AppDependencies dependencies) =>
      dependencies.launch();
  Map<String, String> get _settings => model.settings;
  bool get _ready => model.ready;
  bool get _entering => model.busy;
  bool get _failed => model.error != null;
  int? _page;
  Future<void> _open() => model.load();
  Future<void> _enter(int page) async {
    if (await model.enter()) {
      if (mounted) setState(() => _page = page);
    } else if (mounted) {
      showFailure(context, model.error ?? 'No pudimos abrir tu inicio.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_page != null || model.returning) {
      return BodegaScreen(initialPage: _page ?? 0);
    }
    if (!_ready || _failed) {
      return PetLoadingScreen(
        settings: _settings,
        failed: _failed,
        onRetry: _open,
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ContentWidth(
            width: 460,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'kwall',
                    textAlign: TextAlign.center,
                    style: KwallTheme.fontTitle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 30),
                  KittyCompanionWidget(
                    settings: _settings,
                    size: 180,
                    activity: PetActivity.curious,
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'Tu dinero.\nTu ritmo.',
                    textAlign: TextAlign.center,
                    style: KwallTheme.fontDisplay.copyWith(fontSize: 38),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 20,
                    runSpacing: 16,
                    children: [
                      _feature(
                        Icons.account_balance_wallet_outlined,
                        'Cuentas',
                      ),
                      _feature(Icons.edit_note_rounded, 'Notas'),
                      _feature(Icons.spa_outlined, 'Hábitos'),
                    ],
                  ),
                  const SizedBox(height: 36),
                  FilledButton.icon(
                    onPressed: _entering ? null : () => _enter(0),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(_entering ? 'Un momento…' : 'Empezar'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _entering ? null : () => _enter(3),
                    child: const Text('Tengo un respaldo'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String label) => Column(
    children: [
      Icon(icon, color: KwallTheme.accent),
      const SizedBox(height: 8),
      Text(label),
    ],
  );
}
