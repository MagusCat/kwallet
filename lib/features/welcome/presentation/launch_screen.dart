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

  late final PageController _pageController;
  late final TextEditingController _petName;
  late final TextEditingController _currency;
  late final TextEditingController _newRefCurrency;
  late final List<String> _referenceCurrencies;
  int _currentStep = 0;
  String _selectedStyle = 'classic';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _petName = TextEditingController(text: 'Mishi');
    _currency = TextEditingController(text: '\$');
    _newRefCurrency = TextEditingController();
    _referenceCurrencies = ['USD', 'EUR'];
  }

  @override
  void onViewModelChanged() {
    if (!_initialized && model.ready) {
      _selectedStyle = model.settings['pet_style'] ?? 'classic';
      final initialName = model.settings['pet_name'] ?? 'Mishi';
      _petName.text = initialName;
      final initialCur = model.settings['currency'];
      if (initialCur != null && initialCur.isNotEmpty) {
        _currency.text = initialCur;
      }
      final rawRefs = model.settings['reference_currencies'] ?? '';
      if (rawRefs.isNotEmpty) {
        _referenceCurrencies = rawRefs
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _petName.dispose();
    _currency.dispose();
    _newRefCurrency.dispose();
    super.dispose();
  }

  Future<void> _open() => model.load();

  Future<void> _enter(int page) async {
    final petName =
        _petName.text.trim().isEmpty ? 'Mishi' : _petName.text.trim();
    final cur = _currency.text.trim().isEmpty ? '\$' : _currency.text.trim();
    final refCur = _referenceCurrencies.join(',');
    if (await model.enter(
      petStyle: _selectedStyle,
      petName: petName,
      currency: cur,
      referenceCurrencies: refCur,
    )) {
      if (mounted) setState(() => _page = page);
    } else if (mounted) {
      showFailure(context, model.error ?? 'No pudimos abrir tu inicio.');
    }
  }

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
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

    final currentPetSettings = {
      ..._settings,
      'pet_style': _selectedStyle,
      'pet_name': _petName.text,
      'currency': _currency.text,
    };

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ContentWidth(
            width: 480,
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) => setState(() => _currentStep = page),
              children: [
                _buildIntroStep(currentPetSettings),
                _buildPetStep(currentPetSettings),
                _buildCurrencyStep(currentPetSettings),
                _buildPrivacyStep(currentPetSettings),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Paso 0: Bienvenida e introducción a kwall
  Widget _buildIntroStep(Map<String, String> petSettings) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'kwall',
              textAlign: TextAlign.center,
              style: KwallTheme.fontTitle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 20),
            KittyCompanionWidget(
              settings: petSettings,
              size: 160,
              activity: PetActivity.curious,
            ),
            const SizedBox(height: 20),
            Text(
              'Tu dinero.\nTu ritmo.',
              textAlign: TextAlign.center,
              style: KwallTheme.fontDisplay.copyWith(fontSize: 36),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 16,
              runSpacing: 12,
              children: [
                _feature(Icons.account_balance_wallet_outlined, 'Cuentas'),
                _feature(Icons.edit_note_rounded, 'Notas'),
                _feature(Icons.spa_outlined, 'Hábitos'),
              ],
            ),
            const SizedBox(height: 16),
            _infoCard(
              icon: Icons.tips_and_updates_outlined,
              title: 'Consejos para usar Kwallet',
              description:
                  '1. Registra tus movimientos al momento para evitar gastos invisibles.\n2. Separa tus cuentas por propósito (efectivo, banco, reserva de ahorro).\n3. Revisa tus límites para gastar con tranquilidad y sin sorpresas.',
            ),
            const SizedBox(height: 24),
            _stepIndicator(),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _goToStep(1),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Configurar mi compañero'),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _entering ? null : () => _enter(0),
                  child: const Text('Empezar con valores por defecto'),
                ),
                const Text('·'),
                TextButton(
                  onPressed: _entering ? null : () => _enter(3),
                  child: const Text('Tengo un respaldo'),
                ),
              ],
            ),
          ],
        ),
      );

  /// Paso 1: Personalizar estilo de la mascota y su nombre, junto con el compromiso
  Widget _buildPetStep(Map<String, String> petSettings) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Elige a tu compañero',
              textAlign: TextAlign.center,
              style: KwallTheme.fontTitle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 6),
            Text(
              'Estará contigo celebrando tus hábitos y cuidando tu progreso.',
              textAlign: TextAlign.center,
              style: TextStyle(color: KwallTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Center(
              child: KittyCompanionWidget(
                settings: petSettings,
                size: 110,
                activity: PetActivity.celebrate,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _petName,
              maxLength: 20,
              decoration: const InputDecoration(
                labelText: 'Nombre de tu mascota',
                hintText: 'Ej. Mishi, Garfield, Copito…',
                prefixIcon: Icon(Icons.pets_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Text(
              'Raza o estilo:',
              style: KwallTheme.fontTitle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final entry in petStyles.entries)
                  ChoiceChip(
                    avatar: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: TickerMode(
                        enabled: false,
                        child: KittyCompanionWidget(
                          size: 18,
                          settings: {'pet_style': entry.key},
                        ),
                      ),
                    ),
                    label: Text(entry.value),
                    selected: _selectedStyle == entry.key,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedStyle = entry.key;
                          if (_petName.text.isEmpty ||
                              petStyles.values.contains(_petName.text)) {
                            _petName.text = entry.value;
                          }
                        });
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _infoCard(
              icon: Icons.favorite_border_rounded,
              title: 'Compromiso con tu compañero',
              description:
                  'Tu mascota virtual se alimenta de tu constancia. Cada hábito completado te otorga +10 XP para subirla de nivel y desbloquear nuevas reacciones. Si abandonas tus registros, se quedará dormida o desganada.',
            ),
            const SizedBox(height: 24),
            _stepIndicator(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _goToStep(0),
                    child: const Text('Atrás'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _goToStep(2),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Configurar monedas'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// Paso 2: Configuración de moneda dominante y monedas alternativas
  Widget _buildCurrencyStep(Map<String, String> petSettings) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tus monedas',
              textAlign: TextAlign.center,
              style: KwallTheme.fontTitle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 6),
            Text(
              'Define tu moneda dominante y las monedas de referencia para saber cómo se diversifica tu efectivo.',
              textAlign: TextAlign.center,
              style: TextStyle(color: KwallTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _currency,
              maxLength: 8,
              decoration: const InputDecoration(
                labelText: 'Moneda dominante (principal)',
                hintText: 'C\$, USD, €, MXN…',
                prefixIcon: Icon(Icons.monetization_on_outlined),
                helperText: 'Base principal de tus saldos y metas.',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Text(
              'Sugerencias rápidas:',
              style: TextStyle(color: KwallTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final cur in ['\$', 'USD', 'C\$', 'EUR', 'MXN', 'COP'])
                  ActionChip(
                    label: Text(cur),
                    onPressed: () => setState(() => _currency.text = cur),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Otras monedas alternativas (de referencia)',
              style: KwallTheme.fontTitle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Podrás asignarlas a tus cuentas para tener claro cómo está diversificado tu dinero.',
              style: TextStyle(color: KwallTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (_referenceCurrencies.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in _referenceCurrencies)
                    Chip(
                      label: Text(c),
                      onDeleted: () => setState(() => _referenceCurrencies.remove(c)),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newRefCurrency,
                    decoration: const InputDecoration(
                      hintText: 'Agregar moneda (ej. EUR, NIO, USD)',
                      isDense: true,
                    ),
                    onSubmitted: (_) {
                      final val = _newRefCurrency.text.trim().toUpperCase();
                      if (val.isNotEmpty && !_referenceCurrencies.contains(val)) {
                        setState(() {
                          _referenceCurrencies.add(val);
                          _newRefCurrency.clear();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Añadir moneda',
                  onPressed: () {
                    final val = _newRefCurrency.text.trim().toUpperCase();
                    if (val.isNotEmpty && !_referenceCurrencies.contains(val)) {
                      setState(() {
                        _referenceCurrencies.add(val);
                        _newRefCurrency.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _stepIndicator(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _goToStep(1),
                    child: const Text('Atrás'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _goToStep(3),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Continuar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// Paso 3: Explicación de almacenamiento local y nube opcional
  Widget _buildPrivacyStep(Map<String, String> petSettings) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Privado por diseño',
              textAlign: TextAlign.center,
              style: KwallTheme.fontTitle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 6),
            Text(
              'Tus finanzas no son el negocio de nadie más.',
              textAlign: TextAlign.center,
              style: TextStyle(color: KwallTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Center(
              child: KittyCompanionWidget(
                settings: petSettings,
                size: 100,
                activity: PetActivity.sleep,
              ),
            ),
            const SizedBox(height: 16),
            _infoCard(
              icon: Icons.shield_outlined,
              title: '100% Local y privado',
              description:
                  'Tus cuentas, gastos, notas y hábitos se almacenan exclusivamente en la base de datos de tu dispositivo. No requiere registro ni cuenta obligatoria.',
            ),
            const SizedBox(height: 12),
            _infoCard(
              icon: Icons.cloud_outlined,
              title: 'Copia en la nube opcional',
              description:
                  'Si deseas respaldar en la nube o sincronizar tus datos, puedes vincular tu cuenta de GitHub (Secret Gist) desde los Ajustes cuando quieras. Es 100% opcional.',
            ),
            const SizedBox(height: 24),
            _stepIndicator(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _goToStep(2),
                    child: const Text('Atrás'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _entering ? null : () => _enter(0),
                    icon: const Icon(Icons.check_rounded),
                    label: Text(_entering ? 'Guardando…' : '¡Empezar!'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String description,
  }) =>
      Card(
        elevation: 0,
        color: KwallTheme.surfaceContainer.withValues(alpha: 0.6),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: KwallTheme.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: KwallTheme.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: KwallTheme.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _stepIndicator() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < 4; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentStep == i ? 22 : 8,
              height: 7,
              decoration: BoxDecoration(
                color: _currentStep == i
                    ? KwallTheme.accent
                    : KwallTheme.border.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      );

  Widget _feature(IconData icon, String label) => Column(
        children: [
          Icon(icon, color: KwallTheme.accent),
          const SizedBox(height: 8),
          Text(label),
        ],
      );
}
