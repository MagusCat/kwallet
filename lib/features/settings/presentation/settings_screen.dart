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
  bool _justSaved = false;
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
      setState(() => _justSaved = true);
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Ajustes guardados correctamente'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _justSaved = false);
      });
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

  Future<void> _connectGitHubDialog() async {
    final tokenController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Conectar con GitHub'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa tu Personal Access Token con permiso "gist". Tus respaldos se guardarán en un Gist secreto y privado.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: tokenController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'GitHub Token (ghp_...)',
                hintText: 'ghp_xxxxxxxxxxxx',
                prefixIcon: Icon(Icons.key_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Conectar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await model.connectGitHub(tokenController.text);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text('Conectado a GitHub como @${model.githubUsername}'),
          ),
        );
      }
    }
    tokenController.dispose();
  }

  Future<void> _disconnectGitHub() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desconectar GitHub'),
        content: const Text(
          '¿Deseas desvincular tu cuenta de GitHub de este dispositivo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Desconectar'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await model.disconnectGitHub();
    }
  }

  Future<void> _syncToGitHub() async {
    final ok = await model.syncToGitHub();
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: const Row(
            children: [
              Icon(Icons.cloud_done_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text('Respaldo sincronizado en GitHub'),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _restoreFromGitHub() async {
    final summary = await model.prepareGitHubRestore();
    if (summary == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar desde GitHub'),
        content: Text(
          '${summary.accounts} cuentas · ${summary.movements} movimientos\n${summary.notes} notas · ${summary.habits} hábitos\n\nReemplazará los datos actuales con la copia de GitHub. Antes se guardará una copia local de recuperación.',
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
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Listo, datos restaurados desde GitHub.'),
        ),
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
                    style: _justSaved
                        ? FilledButton.styleFrom(
                            backgroundColor: KwallTheme.incomeGreen,
                            foregroundColor: Colors.white,
                          )
                        : null,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              _justSaved
                                  ? Icons.check_circle_rounded
                                  : Icons.check,
                              key: ValueKey(_justSaved),
                            ),
                    ),
                    label: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        _saving
                            ? 'Guardando…'
                            : _justSaved
                                ? '¡Ajustes guardados!'
                                : 'Guardar ajustes',
                        key: ValueKey('$_saving-$_justSaved'),
                      ),
                    ),
                  ),
                  const Divider(height: 40),
                  Text(
                    'Widget de pantalla de inicio',
                    style: KwallTheme.fontTitle.copyWith(fontSize: 21),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Personaliza el fondo del widget de Android para que combine con tu pantalla de inicio.',
                    style: TextStyle(color: KwallTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'default',
                        icon: Icon(Icons.crop_portrait_rounded),
                        label: Text('Tarjeta'),
                      ),
                      ButtonSegment(
                        value: 'transparent',
                        icon: Icon(Icons.blur_on_rounded),
                        label: Text('Sin fondo'),
                      ),
                      ButtonSegment(
                        value: 'color',
                        icon: Icon(Icons.color_lens_outlined),
                        label: Text('Color'),
                      ),
                    ],
                    selected: {model.settings['widget_bg_mode'] ?? 'default'},
                    onSelectionChanged: (value) =>
                        _appearance('widget_bg_mode', value.first),
                  ),
                  if ((model.settings['widget_bg_mode'] ?? 'default') == 'color') ...[
                    const SizedBox(height: 14),
                    Text(
                      'Color de fondo del widget',
                      style: KwallTheme.fontTitle.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final preset in const [
                          ('Bosque', 0xFF212722),
                          ('Ciruela', 0xFF281F2C),
                          ('Rosa', 0xFF2C1E23),
                          ('Miel', 0xFF2C261A),
                          ('OLED', 0xFF101211),
                          ('Pizarra', 0xFF1E252B),
                        ])
                          ChoiceChip(
                            avatar: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Color(preset.$2),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24),
                              ),
                            ),
                            label: Text(preset.$1),
                            selected: (model.settings['widget_bg_color'] ?? '0xFF212722') == preset.$2.toString() ||
                                (model.settings['widget_bg_color'] == null && preset.$2 == 0xFF212722),
                            onSelected: (_) =>
                                _appearance('widget_bg_color', preset.$2.toString()),
                          ),
                      ],
                    ),
                  ],
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
                  const SizedBox(height: 12),
                  const Divider(height: 32),
                  Row(
                    children: [
                      Icon(Icons.cloud_sync_outlined, color: KwallTheme.accent),
                      const SizedBox(width: 8),
                      Text(
                        'Copia en la nube (GitHub)',
                        style: KwallTheme.fontTitle.copyWith(fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Guarda tus datos de forma privada en un Gist secreto de tu cuenta de GitHub con control de versiones.',
                    style: TextStyle(color: KwallTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  if (!model.isGitHubConnected) ...[
                    OutlinedButton.icon(
                      onPressed: _backupBusy ? null : _connectGitHubDialog,
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('Conectar cuenta de GitHub'),
                    ),
                  ] else ...[
                    Card(
                      elevation: 0,
                      color: KwallTheme.surfaceContainer.withValues(alpha: 0.6),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: KwallTheme.incomeGreen.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    size: 18,
                                    color: KwallTheme.incomeGreen,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '@${model.githubUsername}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        model.githubLastSync.isNotEmpty
                                            ? 'Última copia: ${model.githubLastSync}'
                                            : 'Sin copias en la nube aún',
                                        style: TextStyle(
                                          color: KwallTheme.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Desconectar GitHub',
                                  icon: const Icon(Icons.link_off_rounded),
                                  onPressed: _backupBusy ? null : _disconnectGitHub,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.tonalIcon(
                                  onPressed: _backupBusy ? null : _syncToGitHub,
                                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                                  label: const Text('Sincronizar ahora'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _backupBusy ? null : _restoreFromGitHub,
                                  icon: const Icon(Icons.cloud_download_outlined, size: 18),
                                  label: const Text('Restaurar desde GitHub'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (_backupBusy)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: KittyCompanionWidget(
                          size: 64,
                          settings: _petSettings,
                          activity: PetActivity.run,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _backupBusy ? null : _recoveries,
                    icon: const Icon(Icons.history_rounded),
                    label: const Text('Copias de recuperación locales'),
                  ),
                ],
              ),
            ),
    );
  }
}
