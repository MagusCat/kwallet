import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/kwall_theme.dart';
import 'kitty_companion.dart';

class PetLoadingScreen extends StatelessWidget {
  final Map<String, String> settings;
  final bool failed;
  final String? errorMessage;
  final bool hasRecovery;
  final VoidCallback? onRestoreRecovery;
  final VoidCallback? onRepairDatabase;
  final VoidCallback? onImportBackup;
  final String? diagnosticInfo;

  const PetLoadingScreen({
    super.key,
    this.settings = const {},
    this.failed = false,
    this.errorMessage,
    this.hasRecovery = false,
    this.onRestoreRecovery,
    this.onRepairDatabase,
    this.onImportBackup,
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

  void _confirmNewVault(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crear nueva vault limpia'),
        content: const Text(
          'Se guardará tu base de datos actual incompatible como copia segura (.corrupted) y se inicializará una nueva bóveda limpia para empezar de cero.\n\n¿Deseas continuar?',
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
            child: const Text('Crear nueva vault'),
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
                if (failed)
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      KittyCompanionWidget(
                        settings: settings,
                        size: 110,
                        activity: PetActivity.sleep,
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.error,
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.sentiment_dissatisfied_rounded,
                            size: 22,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  KittyCompanionWidget(
                    settings: settings,
                    size: 110,
                    activity: PetActivity.walk,
                  ),
                const SizedBox(height: 20),
                if (failed) ...[
                  Text(
                    'Base de datos no compatible',
                    style: KwallTheme.fontTitle.copyWith(fontSize: 19),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .error
                            .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.error,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            errorMessage ??
                                'Esta base de datos no es compatible con tu versión actual de kwall. No se puede restaurar automáticamente.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (onRepairDatabase != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _confirmNewVault(context),
                        icon: const Icon(Icons.shield_outlined),
                        label: const Text('Crear nueva vault'),
                      ),
                    ),
                  if (onImportBackup != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onImportBackup,
                        icon: const Icon(Icons.file_open_outlined),
                        label: const Text('Importar otra copia'),
                      ),
                    ),
                  ],
                  if (hasRecovery && onRestoreRecovery != null) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => _confirmRestore(context),
                      icon: const Icon(Icons.settings_backup_restore_rounded),
                      label: const Text('Restaurar copia local previa'),
                    ),
                  ],
                  if (diagnosticInfo != null && diagnosticInfo!.isNotEmpty) ...[
                    const SizedBox(height: 6),
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
