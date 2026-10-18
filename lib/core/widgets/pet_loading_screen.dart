import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/kwall_theme.dart';
import 'kitty_companion.dart';

class PetLoadingScreen extends StatefulWidget {
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

  @override
  State<PetLoadingScreen> createState() => _PetLoadingScreenState();
}

class _PetLoadingScreenState extends State<PetLoadingScreen> {
  static const _loadingPhrases = [
    'Despertando a tu compañero…',
    'Abriendo tu bóveda privada…',
    'Organizando tus finanzas locales…',
    'Todo listo en tu dispositivo…',
  ];

  int _phraseIndex = 0;
  Timer? _phraseTimer;

  @override
  void initState() {
    super.initState();
    if (!widget.failed) {
      _phraseTimer = Timer.periodic(const Duration(milliseconds: 2200), (timer) {
        if (!mounted || widget.failed) {
          timer.cancel();
          return;
        }
        setState(() {
          _phraseIndex = (_phraseIndex + 1) % _loadingPhrases.length;
        });
      });
    }
  }

  @override
  void didUpdateWidget(PetLoadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.failed && !oldWidget.failed) {
      _phraseTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _phraseTimer?.cancel();
    super.dispose();
  }

  void _showDiagnostics(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detalle técnico del error'),
        content: SingleChildScrollView(
          child: SelectableText(
            widget.diagnosticInfo ?? 'No hay información adicional disponible.',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          if (widget.diagnosticInfo != null)
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: widget.diagnosticInfo!));
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
              widget.onRestoreRecovery?.call();
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
              widget.onRepairDatabase?.call();
            },
            child: const Text('Crear nueva vault'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
                    style: KwallTheme.fontTitle.copyWith(
                      fontSize: 30,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Escenario de la mascota con podio/sombra terrenal
                  SizedBox(
                    width: 140,
                    height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Sombra / pedestal suave bajo la mascota
                        Positioned(
                          bottom: 2,
                          child: Container(
                            width: 86,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.rectangle,
                              borderRadius: const BorderRadius.all(
                                Radius.elliptical(86, 18),
                              ),
                              gradient: RadialGradient(
                                colors: [
                                  (widget.failed
                                          ? theme.colorScheme.error
                                          : KwallTheme.accent)
                                      .withValues(alpha: 0.22),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Mascota
                        Positioned(
                          bottom: 8,
                          child: KittyCompanionWidget(
                            settings: widget.settings,
                            size: 104,
                            activity: widget.failed
                                ? PetActivity.sleep
                                : PetActivity.walk,
                          ),
                        ),
                        // Insignia triste si falló
                        if (widget.failed)
                          Positioned(
                            right: 12,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: theme.colorScheme.error,
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
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (widget.failed) ...[
                    Text(
                      'Base de datos no compatible',
                      style: KwallTheme.fontTitle.copyWith(fontSize: 19),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.error
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: theme.colorScheme.error,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.errorMessage ??
                                  'Esta base de datos no es compatible con tu versión actual de kwall. No se puede restaurar automáticamente.',
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (widget.onRepairDatabase != null)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => _confirmNewVault(context),
                          icon: const Icon(Icons.shield_outlined),
                          label: const Text('Crear nueva vault'),
                        ),
                      ),
                    if (widget.onImportBackup != null) ...[
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.onImportBackup,
                          icon: const Icon(Icons.file_open_outlined),
                          label: const Text('Importar otra copia'),
                        ),
                      ),
                    ],
                    if (widget.hasRecovery && widget.onRestoreRecovery != null) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: () => _confirmRestore(context),
                        icon: const Icon(Icons.settings_backup_restore_rounded),
                        label: const Text('Restaurar copia local previa'),
                      ),
                    ],
                    if (widget.diagnosticInfo != null &&
                        widget.diagnosticInfo!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => _showDiagnostics(context),
                        child: const Text('Ver detalle técnico'),
                      ),
                    ],
                  ] else ...[
                    // Cápsula estilizada de progreso
                    Container(
                      width: 130,
                      height: 5,
                      decoration: BoxDecoration(
                        color: KwallTheme.surfaceContainer.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.transparent,
                          color: KwallTheme.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 320),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Text(
                        _loadingPhrases[_phraseIndex],
                        key: ValueKey(_phraseIndex),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: KwallTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
