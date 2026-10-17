import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/mvvm/view_model_state.dart';
import '../view_models/settings_view_model.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/finance_widgets.dart';
import '../../../core/widgets/kitty_companion.dart';
import '../../../core/widgets/pet_picker.dart';
import 'widgets/notifications_settings_tile.dart';
import 'widgets/streaks_settings_tile.dart';

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
  final _newRefCurrency = TextEditingController();
  final _petName = TextEditingController();
  List<String> _referenceCurrencies = [];
  Map<String, String> get _petSettings => model.settings;
  bool get _loading => model.loading;
  bool get _saving => model.busy;
  bool get _backupBusy => model.backupBusy;
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
    final rawRefs = model.settings['reference_currencies'] ?? '';
    _referenceCurrencies = rawRefs
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    _petName.text = model.settings['pet_name'] ?? 'Mishi';
  }

  @override
  void dispose() {
    for (final controller in [_currency, _newRefCurrency, _petName]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addRefCurrency() {
    final cur = _newRefCurrency.text.trim().toUpperCase();
    if (cur.isNotEmpty && !_referenceCurrencies.contains(cur) && cur != _currency.text.trim()) {
      setState(() {
        _referenceCurrencies.add(cur);
        _newRefCurrency.clear();
      });
    }
  }

  Future<void> _appearance(String key, String value) =>
      model.appearance(key, value);
  Future<void> _save() async {
    final saved = await model.save(
      currency: _currency.text,
      referenceCurrencies: _referenceCurrencies,
      petName: _petName.text,
    );
    if (saved && mounted) {
      widget.onCurrencyChanged(_currency.text.trim());
      setState(() => _justSaved = true);
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      final iconColor = Theme.of(context).snackBarTheme.contentTextStyle?.color ??
          (KwallTheme.isDark ? const Color(0xFF191C19) : const Color(0xFFF0F1EB));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: iconColor, size: 20),
              const SizedBox(width: 10),
              const Text('Ajustes guardados correctamente'),
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
      final iconColor = Theme.of(context).snackBarTheme.contentTextStyle?.color ??
          (KwallTheme.isDark ? const Color(0xFF191C19) : const Color(0xFFF0F1EB));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              Icon(Icons.cloud_done_rounded, color: iconColor, size: 20),
              const SizedBox(width: 10),
              const Text('Respaldo sincronizado en GitHub'),
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
                      labelText: 'Moneda dominante (principal)',
                      hintText: 'C\$, USD, €, puntos…',
                      helperText: 'Moneda base principal de tus finanzas y metas.',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Monedas alternativas de referencia',
                    style: KwallTheme.fontTitle.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Agrega las monedas adicionales que utilizas. Podrás designarlas en tus cuentas para ver la diversificación de tu efectivo.',
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
                            hintText: 'Agregar moneda (ej. EUR, USD, NIO)',
                            isDense: true,
                          ),
                          onSubmitted: (_) => _addRefCurrency(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Agregar moneda alternativa',
                        onPressed: _addRefCurrency,
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
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
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: KwallTheme.surfaceContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: KwallTheme.border.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.widgets_outlined,
                          color: KwallTheme.accent,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Personalización nativa de Android',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Para configurar o cambiar el estilo de tu widget, mantén presionado el widget en tu pantalla de inicio de Android y toca el icono de editar / lápiz.',
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
                  const Divider(height: 40),
                  Text(
                    'Preferencias de la app',
                    style: KwallTheme.fontTitle.copyWith(fontSize: 21),
                  ),
                  const SizedBox(height: 14),
                  NotificationsSettingsTile(
                    settings: model.settings,
                    onToggle: (key, val) => _appearance(key, val),
                  ),
                  const SizedBox(height: 14),
                  StreaksSettingsTile(
                    settings: model.settings,
                    onToggle: (key, val) => _appearance(key, val),
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
