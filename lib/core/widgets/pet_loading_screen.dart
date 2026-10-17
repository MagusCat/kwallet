import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/kwall_theme.dart';
import 'kitty_companion.dart';

class PetLoadingScreen extends StatelessWidget {
  final Map<String, String> settings;
  final bool failed;
  final VoidCallback? onRetry;
  final bool hasRecovery;
  final VoidCallback? onRestoreRecovery;
  final VoidCallback? onRepairDatabase;
  final String? diagnosticInfo;

  const PetLoadingScreen({
    super.key,
    this.settings = const {},
    this.failed = false,
    this.onRetry,
    this.hasRecovery = false,
    this.onRestoreRecovery,
    this.onRepairDatabase,
    this.diagnosticInfo,
  });

  void _showDiagnostics(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detalle técnico del error'),
        content: SingleChildScrollView(
          child: SelectableText(
            diagnosticInfo ?? 'No hay información adicional disponible.',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          if (diagnosticInfo != null)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: diagnosticInfo!));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copiado al portapapeles')),
                );
                Navigator.of(ctx).pop();
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Copiar'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar copia previa'),
        content: const Text(
          'Se creará un respaldo del archivo actual (.corrupted) y se importarán tus datos desde la copia automática previa a la migración.\n\n¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onRestoreRecovery?.call();
            },
            child: const Text('Restaurar'),
          ),
        ],
      ),
    );
  }

  void _confirmRepair(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reparar base de datos'),
        content: const Text(
          'Se guardará tu base actual dañada como copia segura (.corrupted) y se inicializará una base de datos limpia para restablecer el acceso a kwall.\n\n¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onRepairDatabase?.call();
            },
            child: const Text('Reparar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'kwall',
                  style: KwallTheme.fontTitle.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 20),
                KittyCompanionWidget(
                  settings: settings,
                  size: 110,
                  activity: failed ? PetActivity.relax : PetActivity.walk,
                ),
                const SizedBox(height: 20),
                if (failed) ...[
                  Text(
                    'No pudimos abrir tus datos',
                    style: KwallTheme.fontTitle.copyWith(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ocurrió un problema de lectura con la base de datos local.',
                    style: TextStyle(color: KwallTheme.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar conexión'),
                  ),
                  if (hasRecovery && onRestoreRecovery != null) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _confirmRestore(context),
                      icon: const Icon(Icons.settings_backup_restore_rounded),
                      label: const Text('Restaurar copia previa'),
                    ),
                  ],
                  if (onRepairDatabase != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _confirmRepair(context),
                      icon: const Icon(Icons.build_circle_outlined),
                      label: const Text('Reparar base de datos'),
                    ),
                  ],
                  if (diagnosticInfo != null && diagnosticInfo!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => _showDiagnostics(context),
                      child: const Text('Ver detalle técnico'),
                    ),
                  ],
                ] else ...[
                  const SizedBox(width: 80, child: LinearProgressIndicator()),
                  const SizedBox(height: 14),
                  const Text('Un momento…'),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
