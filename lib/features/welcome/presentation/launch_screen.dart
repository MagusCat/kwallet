import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/models/pet_species.dart';
import '../../../core/mvvm/view_model_state.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/finance_widgets.dart';
import '../../../core/widgets/kitty_companion.dart';
import '../../../core/widgets/pet_loading_screen.dart';
import '../../../core/widgets/pet_selection_panel.dart';
import '../../bodega/presentation/bodega_screen.dart';
import '../view_models/launch_view_model.dart';

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
  late final TextEditingController _currencyName;
  late final TextEditingController _newRefSymbol;
  late final TextEditingController _newRefName;
  late List<String> _referenceCurrencies;
  final Map<String, String> _customCurrencyNames = {};
  int _currentStep = 0;
  String _selectedStyle = 'classic';
  bool _initialized = false;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _petName = TextEditingController(text: 'Mishi');
    _currency = TextEditingController(text: '\$');
    _currencyName = TextEditingController();
    _newRefSymbol = TextEditingController();
    _newRefName = TextEditingController();
    _referenceCurrencies = [];
  }

  @override
  void onViewModelChanged() {
    if (!_initialized && model.ready) {
      if (model.userCurrencies.isNotEmpty) {
        _customCurrencyNames.addAll(model.userCurrencies);
      }
      _selectedStyle = model.settings['pet_style'] ?? 'classic';
      final initialName = model.settings['pet_name'] ?? 'Mishi';
      _petName.text = initialName;
      final initialCur = model.settings['currency'];
      if (initialCur != null && initialCur.isNotEmpty) {
        _currency.text = initialCur;
        _currencyName.text = model.userCurrencies[initialCur] ?? '';
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
    _currencyName.dispose();
    _newRefSymbol.dispose();
    _newRefName.dispose();
    super.dispose();
  }

  Future<void> _enter(int page) async {
    HapticFeedback.mediumImpact();
    final petName =
        _petName.text.trim().isEmpty ? 'Mishi' : _petName.text.trim();
    final cur = _currency.text.trim().isEmpty ? '\$' : _currency.text.trim();
    final curName = _currencyName.text.trim();
    final refCur = _referenceCurrencies.join(',');
    final allUserCurrencies = <String, String>{
      cur: curName,
      for (final ref in _referenceCurrencies)
        ref: _customCurrencyNames[ref] ?? '',
    };
    if (await model.enter(
      petStyle: _selectedStyle,
      petName: petName,
      currency: cur,
      currencyName: curName,
      referenceCurrencies: refCur,
      userCurrencies: allUserCurrencies,
      notificationsEnabled: _notificationsEnabled,
    )) {
      if (mounted) setState(() => _page = page);
    } else if (mounted) {
      showFailure(context, model.error ?? 'No pudimos abrir tu inicio.');
    }
  }

  void _goToStep(int step) {
    HapticFeedback.lightImpact();
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _suggestRandomName() {
    HapticFeedback.selectionClick();
    final speciesNames = [
      'Mishi', 'Kuro', 'Garfield', 'Copito', 'Simba',
      'Bandit', 'Rocket', 'Mapachín', 'Pillo',
      'Mimi', 'Quesito', 'Splinter', 'Pixie', 'Rattata'
    ];
    final randomName = speciesNames[math.Random().nextInt(speciesNames.length)];
    setState(() {
      _petName.text = randomName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Widget currentView;

    if (_page != null || model.returning) {
      currentView = KeyedSubtree(
        key: const ValueKey('launch_bodega'),
        child: BodegaScreen(initialPage: _page ?? 0),
      );
    } else if (!_ready || _failed) {
      currentView = KeyedSubtree(
        key: const ValueKey('launch_loading'),
        child: PetLoadingScreen(
          settings: _settings,
          failed: _failed,
          errorMessage: model.error,
          hasRecovery: model.hasRecovery,
          onRestoreRecovery: () => model.restoreRecovery(),
          onRepairDatabase: () => model.repairDatabase(),
          onImportBackup: () => model.importBackup(),
          diagnosticInfo: model.diagnosticInfo,
        ),
      );
    } else {
      final currentPetSettings = {
        ..._settings,
        'pet_style': _selectedStyle,
        'pet_name': _petName.text,
        'currency': _currency.text,
      };

      currentView = KeyedSubtree(
        key: const ValueKey('launch_wizard'),
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: ContentWidth(
                width: 480,
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (page) => setState(() => _currentStep = page),
                  children: [
                    _buildIntroStep(currentPetSettings),
                    _buildPetStep(currentPetSettings),
                    _buildCurrencyStep(currentPetSettings),
                    _buildNotificationsStep(currentPetSettings),
                    _buildPrivacyStep(currentPetSettings),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: currentView,
    );
  }

  /// Escenario dinámico para la mascota con suelo/sombra para dar tridimensionalidad
  Widget _petHeroStage({
    required Map<String, String> petSettings,
    required PetActivity activity,
    double size = 130,
    Widget? overlayBadge,
    String? caption,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size + 36,
          height: size + 20,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Sombra / pedestal suave bajo la mascota
              Positioned(
                bottom: 4,
                child: Container(
                  width: size * 0.76,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(size * 0.76, 18),
                    ),
                    gradient: RadialGradient(
                      colors: [
                        KwallTheme.accent.withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Mascota interactiva
              Positioned(
                bottom: 10,
                child: KittyCompanionWidget(
                  settings: petSettings,
                  size: size,
                  activity: activity,
                ),
              ),
              if (overlayBadge != null)
                Positioned(
                  right: 4,
                  top: 4,
                  child: overlayBadge,
                ),
            ],
          ),
        ),
        if (caption != null && caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: KwallTheme.accentLight.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: KwallTheme.accent.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              caption,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: KwallTheme.accent,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Paso 0: Bienvenida e introducción a kwall
  Widget _buildIntroStep(Map<String, String> petSettings) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: KwallTheme.surfaceContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: KwallTheme.border.withValues(alpha: 0.35),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 13,
                        color: KwallTheme.accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'BÓVEDA FINANCIERA · 100% LOCAL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: KwallTheme.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'kwall',
              textAlign: TextAlign.center,
              style: KwallTheme.fontTitle.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 12),
            _petHeroStage(
              petSettings: petSettings,
              activity: PetActivity.curious,
              size: 140,
              caption: '¡Hola! Soy tu compañero',
            ),
            const SizedBox(height: 16),
            Text(
              'Tu dinero.\nTu ritmo.',
              textAlign: TextAlign.center,
              style: KwallTheme.fontDisplay.copyWith(fontSize: 34, height: 1.15),
            ),
            const SizedBox(height: 8),
            Text(
              'Gestiona tus cuentas, consolida notas y cultiva tus hábitos diarios junto a tu mascota virtual.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: KwallTheme.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _featureChip(Icons.account_balance_wallet_outlined, 'Cuentas'),
                const SizedBox(width: 8),
                _featureChip(Icons.edit_note_rounded, 'Notas'),
                const SizedBox(width: 8),
                _featureChip(Icons.spa_outlined, 'Hábitos'),
              ],
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
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                TextButton(
                  onPressed: _entering ? null : () => _enter(0),
                  child: const Text('Empezar directo'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                  child: Text('·', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: _entering ? null : () => _enter(3),
                  child: const Text('Tengo un respaldo'),
                ),
              ],
            ),
          ],
        ),
      );

  Widget _featureChip(IconData icon, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: KwallTheme.surfaceContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: KwallTheme.border.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: KwallTheme.accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: KwallTheme.accent, size: 18),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

  /// Paso 1: Personalizar estilo de la mascota y su nombre
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
              'Estará contigo celebrando tus hábitos y cuidando tu constancia.',
              textAlign: TextAlign.center,
              style: TextStyle(color: KwallTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _petHeroStage(
              petSettings: petSettings,
              activity: PetActivity.celebrate,
              size: 116,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _petName,
              maxLength: 20,
              decoration: InputDecoration(
                labelText: 'Nombre de tu mascota',
                hintText: 'Ej. Mishi, Rocket, Copito…',
                prefixIcon: const Icon(Icons.pets_rounded),
                suffixIcon: IconButton(
                  tooltip: 'Sugerir nombre aleatorio',
                  icon: const Icon(Icons.casino_outlined, size: 20),
                  onPressed: _suggestRandomName,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            PetSelectionPanel(
              selectedStyle: _selectedStyle,
              onSelectStyle: (style) {
                setState(() => _selectedStyle = style);
              },
              onNameSuggested: (name) {
                setState(() {
                  if (_petName.text.isEmpty ||
                      PetSpeciesCatalog.namesMap.values.contains(_petName.text)) {
                    _petName.text = name;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            _infoCard(
              icon: Icons.favorite_border_rounded,
              title: 'Compromiso con tu compañero',
              description:
                  'Tu mascota virtual se alimenta de tu constancia. Cada hábito completado le otorga +10 XP para subir de nivel y desbloquear nuevas reacciones dinámicas.',
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
              'Define tu moneda principal y monedas de referencia.',
              textAlign: TextAlign.center,
              style: TextStyle(color: KwallTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _petHeroStage(
              petSettings: petSettings,
              activity: PetActivity.walk,
              size: 104,
              caption: 'Moneda activa: ${_currency.text.trim().isEmpty ? '\$' : _currency.text.trim()}',
            ),
            const SizedBox(height: 16),
            Text(
              'Moneda principal',
              style: KwallTheme.fontTitle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Símbolo *',
                      hintText: 'Ej. \$, USD, €',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _currencyName,
                    decoration: const InputDecoration(
                      labelText: 'Nombre (opcional)',
                      hintText: 'Ej. Dólar, Córdoba',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (val) {
                      _customCurrencyNames[_currency.text.trim()] = val.trim();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Monedas de referencia',
              style: KwallTheme.fontTitle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Opcional. Otras monedas que también utilices.',
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
                      label: Text(
                        _customCurrencyNames[c]?.isNotEmpty == true
                            ? '$c · ${_customCurrencyNames[c]}'
                            : c,
                      ),
                      onDeleted: () => setState(() {
                        _referenceCurrencies.remove(c);
                        _customCurrencyNames.remove(c);
                      }),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _newRefSymbol,
                    decoration: const InputDecoration(
                      labelText: 'Símbolo',
                      hintText: 'Ej. EUR, C\$',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _newRefName,
                    decoration: const InputDecoration(
                      labelText: 'Nombre (opcional)',
                      hintText: 'Ej. Euro, Peso',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Añadir moneda',
                  onPressed: () {
                    final sym = _newRefSymbol.text.trim();
                    final name = _newRefName.text.trim();
                    if (sym.isNotEmpty && !_referenceCurrencies.contains(sym)) {
                      setState(() {
                        _referenceCurrencies.add(sym);
                        if (name.isNotEmpty) {
                          _customCurrencyNames[sym] = name;
                        }
                        _newRefSymbol.clear();
                        _newRefName.clear();
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

  /// Paso 3: Configuración de notificaciones y rutinas diarias
  Widget _buildNotificationsStep(Map<String, String> petSettings) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Rutinas y Notificaciones',
              textAlign: TextAlign.center,
              style: KwallTheme.fontTitle.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 6),
            Text(
              'Comienza y culmina cada jornada con tu compañero.',
              textAlign: TextAlign.center,
              style: TextStyle(color: KwallTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _petHeroStage(
              petSettings: petSettings,
              activity: _notificationsEnabled ? PetActivity.celebrate : PetActivity.curious,
              size: 110,
              caption: _notificationsEnabled ? '¡Notificaciones activadas!' : 'Tu compañero estará listo',
              overlayBadge: _notificationsEnabled
                  ? Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: KwallTheme.incomeGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            _infoCard(
              icon: Icons.wb_sunny_outlined,
              title: 'Inicio de día (Flow Start)',
              description:
                  'Motivación matutina para trazar tu presupuesto, revisar tus compromisos y arrancar tus hábitos del día.',
            ),
            const SizedBox(height: 10),
            _infoCard(
              icon: Icons.nightlight_outlined,
              title: 'Finalización de jornada (Cierre)',
              description:
                  'Aviso nocturno para registrar tus movimientos, repasar tus hábitos cumplidos y cerrar el día en calma.',
            ),
            const SizedBox(height: 16),
            if (!_notificationsEnabled) ...[
              FilledButton.icon(
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  final granted = await NotificationService.requestNotificationPermission();
                  if (mounted) {
                    setState(() {
                      _notificationsEnabled = granted;
                    });
                    if (!granted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Permiso no concedido. Podrás activarlo después en Ajustes.'),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.notifications_active_rounded),
                label: const Text('Activar notificaciones'),
              ),
              const SizedBox(height: 6),
              Text(
                'Es opcional. Si prefieres no recibirlas, continuarán desactivadas.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: KwallTheme.textSecondary),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: KwallTheme.incomeGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KwallTheme.incomeGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: KwallTheme.incomeGreen, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '¡Notificaciones concedidas! Te avisaremos al inicio y fin de tu día.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: KwallTheme.incomeGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                    onPressed: () => _goToStep(4),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Continuar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );

  /// Paso 4: Explicación de almacenamiento local y nube opcional
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
            _petHeroStage(
              petSettings: petSettings,
              activity: PetActivity.celebrate,
              size: 110,
              overlayBadge: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: KwallTheme.accentLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  color: KwallTheme.accent,
                  size: 20,
                ),
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
                    onPressed: () => _goToStep(3),
                    child: const Text('Atrás'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _entering ? null : () => _enter(0),
                    icon: const Icon(Icons.rocket_launch_rounded),
                    label: Text(_entering ? 'Guardando…' : '¡Comenzar!'),
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
          for (var i = 0; i < 5; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentStep == i ? 28 : 8,
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
}
