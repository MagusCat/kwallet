import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/mvvm/view_model_state.dart';
import '../view_models/settings_view_model.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/finance_widgets.dart';
import '../../../core/widgets/kitty_companion.dart';
import '../../../core/widgets/pet_picker.dart';

class SettingsScreen extends StatefulWidget {
  final String currentCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final VoidCallback? onBack;
  const SettingsScreen({
    super.key,
    required this.currentCurrency,
    required this.onCurrencyChanged,
    this.onBack,
  });
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState
    extends ViewModelState<SettingsScreen, SettingsViewModel> {
  @override
  SettingsViewModel createViewModel(AppDependencies dependencies) =>
      dependencies.settingsScreen();
  final _currency = TextEditingController();
  final _mirror = TextEditingController();
  final _rate = TextEditingController();
  final _petName = TextEditingController();
  Map<String, String> get _petSettings => model.settings;
  bool get _loading => model.loading;
  bool get _saving => model.busy;
  bool get _backupBusy => model.backupBusy;
  bool _mirrorEnabled = false;
  bool _fieldsReady = false;
  String? get _error => model.error;
  @override
  void onViewModelChanged() {
    if (!_fieldsReady && !model.loading) {
      _syncFields();
      _fieldsReady = true;
    }
  }

  void _syncFields() {
    _currency.text = model.settings['currency'] ?? widget.currentCurrency;
    _mirror.text = model.settings['mirror_currency'] ?? '';
    _rate.text = model.settings['mirror_rate'] ?? '';
    _petName.text = model.settings['pet_name'] ?? 'Mishi';
    _mirrorEnabled = _mirror.text.isNotEmpty;
  }

  @override
  void dispose() {
    for (final controller in [_currency, _mirror, _rate, _petName]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _appearance(String key, String value) =>
      model.appearance(key, value);
  Future<void> _save() async {
    final saved = await model.save(
      currency: _currency.text,
      mirrorEnabled: _mirrorEnabled,
      mirror: _mirror.text,
      rateText: _rate.text,
      petName: _petName.text,
    );
    if (saved && mounted) {
      widget.onCurrencyChanged(_currency.text.trim());
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ajustes guardados')));
    }
  }

  Future<void> _export() async {
    if (await model.export() && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Respaldo guardado')));
    }
  }

  Future<void> _restore({String? recovery}) async {
    final summary = await model.prepareRestore(recovery: recovery);
    if (summary == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar respaldo'),
        content: Text(
          '${summary.accounts} cuentas · ${summary.movements} movimientos\n${summary.notes} notas · ${summary.habits} hábitos\n\nReemplazará los datos actuales. Antes se guardará una copia local de recuperación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      model.discardRestore();
      return;
    }
    if (await model.restore() && mounted) {
      setState(_syncFields);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listo, recuperamos tus datos.')),
      );
    }
  }

  Future<void> _recoveries() async {
    if (!await model.loadRecoveries() || !mounted) return;
    final selected = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Copias de recuperación'),
        children: [
          if (model.recoveries.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Aún no hay copias de recuperación.'),
            ),
          for (final copy in model.recoveries)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, copy.id),
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(
                  copy.beforeUpdate
                      ? 'Antes de actualizar'
                      : 'Antes de restaurar',
                ),
                subtitle: Text(copy.createdAt.toString().substring(0, 19)),
              ),
            ),
        ],
      ),
    );
    if (selected != null && mounted) await _restore(recovery: selected);
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        leading: widget.onBack != null
            ? IconButton(
                tooltip: 'Volver',
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ContentWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                children: [
                  Text(
                    'Hazlo tuyo',
                    style: KwallTheme.fontTitle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'light',
                        icon: Icon(Icons.light_mode_outlined),
                        label: Text('Claro'),
                      ),
                      ButtonSegment(
                        value: 'dark',
                        icon: Icon(Icons.dark_mode_outlined),
                        label: Text('Oscuro'),
                      ),
                      ButtonSegment(
                        value: 'system',
                        icon: Icon(Icons.brightness_auto_outlined),
                        label: Text('Auto'),
                      ),
                    ],
                    selected: {KwallTheme.mode},
                    onSelectionChanged: (value) =>
                        _appearance('theme_mode', value.first),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final palette in KwallTheme.palettes.entries)
                        ChoiceChip(
                          avatar: Icon(
                            Icons.palette_outlined,
                            color: KwallTheme.paletteColor(
                              palette.key,
                              dark: KwallTheme.isDark,
                            ),
                            size: 18,
                          ),
                          label: Text(palette.value),
                          selected: KwallTheme.palette == palette.key,
                          onSelected: (_) =>
                              _appearance('palette', palette.key),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 40),
                  Text(
                    'Monedas',
                    style: KwallTheme.fontTitle.copyWith(fontSize: 21),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _currency,
                    maxLength: 12,
                    decoration: const InputDecoration(
                      labelText: 'Moneda principal',
                      hintText: 'C\$, USD, €, puntos…',
                    ),
                  ),
                  Text(
                    'Cambiar el símbolo no convierte tus saldos existentes.',
                    style: TextStyle(color: KwallTheme.textSecondary),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Moneda espejo'),
                    value: _mirrorEnabled,
                    onChanged: (value) =>
                        setState(() => _mirrorEnabled = value),
                  ),
                  if (_mirrorEnabled) ...[
                    TextField(
                      controller: _mirror,
                      maxLength: 12,
                      decoration: const InputDecoration(
                        labelText: 'Símbolo espejo',
                      ),
                    ),
                    TextField(
                      controller: _rate,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: '1 moneda principal equivale a',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tasa manual de referencia.',
                      style: TextStyle(color: KwallTheme.textSecondary),
                    ),
                  ],
                  const Divider(height: 40),
                  Text(
                    'Tu compañero',
                    style: KwallTheme.fontTitle.copyWith(fontSize: 21),
                  ),
                  KittyCompanionWidget(size: 100, settings: _petSettings),
                  const SizedBox(height: 12),
                  PetPicker(
                    settings: _petSettings,
                    busy: model.busy,
                    onChoose: model.choosePet,
                    onUpload: model.uploadPet,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _petName,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 18),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(color: KwallTheme.expenseRed),
                      ),
                    ),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check),
                    label: Text(_saving ? 'Guardando…' : 'Guardar ajustes'),
                  ),
                  const Divider(height: 40),
                  Text(
                    'Tus datos, a salvo',
                    style: KwallTheme.fontTitle.copyWith(fontSize: 21),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Lleva una copia de todo contigo.',
                    style: TextStyle(color: KwallTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: _backupBusy ? null : _export,
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Exportar respaldo'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _backupBusy ? null : _restore,
                    icon: const Icon(Icons.restore_rounded),
                    label: const Text('Importar respaldo'),
                  ),
                  if (_backupBusy)
                    KittyCompanionWidget(
                      size: 64,
                      settings: _petSettings,
                      activity: PetActivity.run,
                    ),
                  TextButton.icon(
                    onPressed: _backupBusy ? null : _recoveries,
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('Copias de recuperación'),
                  ),
                ],
              ),
            ),
    );
  }
}
