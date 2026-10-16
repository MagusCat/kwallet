import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/game_hud_widgets.dart';
import '../../../core/widgets/kitty_companion.dart';

class SettingsScreen extends StatefulWidget {
  final String currentCurrency;
  final Function(String) onCurrencyChanged;

  const SettingsScreen({
    super.key,
    required this.currentCurrency,
    required this.onCurrencyChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _kittyNameController = TextEditingController();
  final TextEditingController _budgetLimitController = TextEditingController();

  String _selectedCoat = 'orange';
  String _selectedCurrency = '\$';
  double _currentBudgetLimit = 1200.0;
  bool _isLoading = true;

  final List<Map<String, String>> _coatOptions = [
    {'id': 'orange', 'label': 'Naranja Tabby'},
    {'id': 'tuxedo', 'label': 'Tuxedo (Negro)'},
    {'id': 'white', 'label': 'Blanco Nieve'},
    {'id': 'grey', 'label': 'Gris Plateado'},
    {'id': 'calico', 'label': 'Calicó Tricolor'},
  ];

  final List<String> _currencies = ['\$', '€', '£', 'S/', '¥', 'R\$'];

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currentCurrency;
    _loadSettings();
  }

  @override
  void dispose() {
    _kittyNameController.dispose();
    _budgetLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final kitty = await DatabaseService.instance.getKittyProfile();
    final budget = await DatabaseService.instance.getCurrentBudget();
    final curr = await DatabaseService.instance.getCurrency();

    if (mounted) {
      setState(() {
        _kittyNameController.text = (kitty['name'] as String?) ?? 'Mishi';
        _selectedCoat = (kitty['coat_color'] as String?) ?? 'orange';
        _currentBudgetLimit = budget.monthlyLimit;
        _budgetLimitController.text = _currentBudgetLimit.toStringAsFixed(0);
        _selectedCurrency = curr;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveKittySettings() async {
    final name = _kittyNameController.text.trim();
    if (name.isEmpty) return;

    await DatabaseService.instance.updateKittyConfig(
      name: name,
      coatColor: _selectedCoat,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compañero Kitty actualizado'),
          backgroundColor: KwallTheme.surfaceElevated,
        ),
      );
    }
  }

  Future<void> _saveBudget() async {
    final val = double.tryParse(_budgetLimitController.text.trim());
    if (val != null && val > 0) {
      await DatabaseService.instance.setMonthlyBudget(val);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Límite de presupuesto guardado'),
            backgroundColor: KwallTheme.surfaceElevated,
          ),
        );
      }
    }
  }

  Future<void> _changeCurrency(String curr) async {
    setState(() => _selectedCurrency = curr);
    await DatabaseService.instance.setCurrency(curr);
    widget.onCurrencyChanged(curr);
  }

  void _exportJsonBackup() async {
    final jsonStr = await DatabaseService.instance.exportFullDataAsJson();
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: KwallTheme.surface,
          title: Text('Copia de Seguridad JSON', style: KwallTheme.fontTitle),
          content: SizedBox(
            width: 480,
            height: 300,
            child: SelectableText(
              jsonStr,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: KwallTheme.textPrimary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CERRAR', style: TextStyle(color: KwallTheme.accent)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: KwallTheme.accent));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configuración',
          style: KwallTheme.fontTitle.copyWith(fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ================= 1. PERSONALIZAR EL GATO =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KwallTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: KwallTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pets_rounded, color: KwallTheme.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Tu Compañero Kitty',
                        style: KwallTheme.fontTitle.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Live Preview of Cat with chosen coat
                  Center(
                    child: KittyCompanionWidget(
                      coatColor: _selectedCoat,
                      size: 110,
                      name: _kittyNameController.text,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name Input
                  Text(
                    'Nombre del Gato',
                    style: KwallTheme.fontBody.copyWith(fontSize: 12, color: KwallTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _kittyNameController,
                    style: const TextStyle(color: KwallTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Ej. Mishi, Luna, Kwall...',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),

                  // Coat Color Selector
                  Text(
                    'Pelaje del Gato',
                    style: KwallTheme.fontBody.copyWith(fontSize: 12, color: KwallTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _coatOptions.map((opt) {
                      final isSelected = _selectedCoat == opt['id'];
                      return ChoiceChip(
                        label: Text(opt['label']!),
                        selected: isSelected,
                        selectedColor: KwallTheme.accent.withValues(alpha: 0.2),
                        backgroundColor: KwallTheme.surfaceContainer,
                        side: BorderSide(color: isSelected ? KwallTheme.accent : KwallTheme.border),
                        labelStyle: TextStyle(
                          color: isSelected ? KwallTheme.accent : KwallTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) {
                          setState(() => _selectedCoat = opt['id']!);
                          _saveKittySettings();
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  ExpressiveButton(
                    onPressed: _saveKittySettings,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'Guardar Cambios de Kitty',
                        style: KwallTheme.fontTitle.copyWith(color: Colors.black, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ================= 2. MONEDA & LÍMITES =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KwallTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: KwallTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.currency_exchange_rounded, color: KwallTheme.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Moneda & Presupuesto',
                        style: KwallTheme.fontTitle.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Símbolo de Moneda',
                    style: KwallTheme.fontBody.copyWith(fontSize: 12, color: KwallTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    children: _currencies.map((c) {
                      final isSelected = _selectedCurrency == c;
                      return ChoiceChip(
                        label: Text(c, style: const TextStyle(fontSize: 14)),
                        selected: isSelected,
                        selectedColor: KwallTheme.accent.withValues(alpha: 0.2),
                        backgroundColor: KwallTheme.surfaceContainer,
                        side: BorderSide(color: isSelected ? KwallTheme.accent : KwallTheme.border),
                        onSelected: (_) => _changeCurrency(c),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  Text(
                    'Límite de Presupuesto Mensual',
                    style: KwallTheme.fontBody.copyWith(fontSize: 12, color: KwallTheme.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _budgetLimitController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(color: KwallTheme.textPrimary),
                          decoration: InputDecoration(
                            prefixText: '$_selectedCurrency ',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ExpressiveButton(
                        onPressed: _saveBudget,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: const Text('Actualizar', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ================= 3. RESPALDO OFFLINE =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KwallTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: KwallTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.backup_rounded, color: KwallTheme.accent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Datos & Privacidad',
                        style: KwallTheme.fontTitle.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tus datos están guardados localmente en SQLite sin telemetría ni servidores externos.',
                    style: KwallTheme.fontBody.copyWith(color: KwallTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ExpressiveButton(
                    onPressed: _exportJsonBackup,
                    isOutlined: true,
                    color: KwallTheme.textPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: const Center(
                      child: Text(
                        'Exportar Copia de Seguridad JSON',
                        style: TextStyle(color: KwallTheme.textPrimary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
