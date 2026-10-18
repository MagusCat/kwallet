import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/finance_widgets.dart';
import '../../../core/widgets/kitty_companion.dart';
import '../view_models/settings_view_model.dart';

class GitHubCloudScreen extends StatefulWidget {
  final SettingsViewModel model;

  const GitHubCloudScreen({super.key, required this.model});

  @override
  State<GitHubCloudScreen> createState() => _GitHubCloudScreenState();
}

class _GitHubCloudScreenState extends State<GitHubCloudScreen> {
  final _tokenController = TextEditingController();

  SettingsViewModel get model => widget.model;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa tu Personal Access Token.')),
      );
      return;
    }

    final ok = await model.connectGitHub(token);
    if (!mounted) return;
    if (ok) {
      _tokenController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('¡Conectado exitosamente como @${model.githubUsername}!'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(model.error ?? 'Error al validar el token de GitHub.'),
        ),
      );
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desconectar GitHub'),
        content: const Text(
          '¿Deseas desvincular tu cuenta de GitHub de este dispositivo?\n\nTus copias existentes en tu Gist no se borrarán.',
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

    if (confirmed == true && mounted) {
      await model.disconnectGitHub();
    }
  }

  Future<void> _sync() async {
    final ok = await model.syncToGitHub();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
              SizedBox(width: 10),
              Text('Respaldo sincronizado exitosamente en GitHub'),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(model.error ?? 'Error al sincronizar.'),
        ),
      );
    }
  }

  Future<void> _restore() async {
    final summary = await model.prepareGitHubRestore();
    if (!mounted) return;
    if (summary == null) {
      if (model.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(model.error!)),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar desde GitHub'),
        content: Text(
          'Contenido de la copia en GitHub:\n'
          '• ${summary.accounts} cuentas\n'
          '• ${summary.movements} movimientos\n'
          '• ${summary.notes} notas\n'
          '• ${summary.habits} hábitos\n\n'
          'Se creará una copia local de seguridad antes de sustituir los datos.\n\n'
          '¿Deseas continuar?',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Listo, tus datos han sido restaurados desde GitHub.'),
        ),
      );
    }
  }

  Future<void> _openGitHub(String url) async {
    final opened = await NotificationService.openUrl(url);
    if (!opened) {
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Enlace copiado al portapapeles: $url'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model,
      builder: (context, _) {
        final connected = model.isGitHubConnected;
        final username = model.githubUsername;
        final gistId = model.githubGistId;
        final lastSync = model.githubLastSync;
        final isBusy = model.githubBusy;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Nube Personal (GitHub)'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header con mascota y nube
                Center(
                  child: Column(
                    children: [
                      SizedBox(
                        width: 120,
                        height: 110,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              bottom: 2,
                              child: Container(
                                width: 80,
                                height: 16,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(
                                    Radius.elliptical(80, 16),
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
                            Positioned(
                              bottom: 6,
                              child: KittyCompanionWidget(
                                settings: model.settings,
                                size: 84,
                                activity: isBusy
                                    ? PetActivity.run
                                    : (connected
                                        ? PetActivity.celebrate
                                        : PetActivity.curious),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: connected
                                      ? KwallTheme.incomeGreen
                                      : KwallTheme.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  connected
                                      ? Icons.cloud_done_rounded
                                      : Icons.cloud_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tu Nube Personal',
                        style: KwallTheme.fontTitle.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Respaldo privado, cifrado y bajo tu propio control.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: KwallTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tarjeta de Estado
                LedgerPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: connected
                                  ? KwallTheme.incomeGreen.withValues(alpha: 0.15)
                                  : KwallTheme.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              connected
                                  ? Icons.cloud_done_rounded
                                  : Icons.cloud_off_rounded,
                              color: connected
                                  ? KwallTheme.incomeGreen
                                  : KwallTheme.textSecondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  connected
                                      ? 'Conectado a GitHub'
                                      : 'No conectado',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  connected ? '@$username' : 'Sin cuenta vinculada',
                                  style: TextStyle(
                                    color: KwallTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (connected)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: KwallTheme.incomeGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Activo',
                                style: TextStyle(
                                  color: KwallTheme.incomeGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(color: KwallTheme.border.withValues(alpha: 0.3)),
                      const SizedBox(height: 10),

                      // Detalles del último cambio / sync
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 18,
                            color: KwallTheme.accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Estado del último cambio:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lastSync.isNotEmpty
                                      ? 'Última sincronización: $lastSync'
                                      : (connected
                                          ? 'Aún no se ha realizado la primera sincronización.'
                                          : 'Conecta tu token para sincronizar.'),
                                  style: TextStyle(
                                    color: KwallTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (gistId.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(
                              Icons.tag_rounded,
                              size: 18,
                              color: KwallTheme.accent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Gist Secreto: ${gistId.substring(0, gistId.length > 12 ? 12 : gistId.length)}…',
                                style: TextStyle(
                                  color: KwallTheme.textSecondary,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _openGitHub('https://gist.github.com/$gistId'),
                              icon: const Icon(Icons.open_in_new_rounded, size: 14),
                              label: const Text('Ver Gist', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Botones de acción si está conectado
                      if (connected) ...[
                        FilledButton.icon(
                          onPressed: isBusy ? null : _sync,
                          icon: const Icon(Icons.cloud_upload_outlined),
                          label: Text(isBusy ? 'Sincronizando…' : 'Sincronizar ahora'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: isBusy ? null : _restore,
                          icon: const Icon(Icons.cloud_download_outlined),
                          label: const Text('Restaurar desde GitHub'),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () => _openGitHub('https://github.com/$username'),
                              icon: const Icon(Icons.person_outline_rounded, size: 16),
                              label: Text('Ver perfil @$username'),
                            ),
                            TextButton.icon(
                              onPressed: isBusy ? null : _disconnect,
                              icon: const Icon(Icons.link_off_rounded, size: 16),
                              label: const Text('Desconectar'),
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Formulario de conexión
                        TextField(
                          controller: _tokenController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Personal Access Token de GitHub',
                            hintText: 'ghp_xxxxxxxxxxxx',
                            prefixIcon: Icon(Icons.key_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: isBusy ? null : _connect,
                          icon: const Icon(Icons.link_rounded),
                          label: Text(isBusy ? 'Validando…' : 'Conectar cuenta'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Explicación de cómo funciona
                Text(
                  '¿Cómo funciona tu Nube Personal?',
                  style: KwallTheme.fontTitle.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),

                _FeatureCard(
                  icon: Icons.shield_outlined,
                  title: '100% Privado y sin intermediarios',
                  description:
                      'Tus finanzas no pasan por ningún servidor de kwall ni de terceros. La comunicación es directa entre tu teléfono y la API oficial de GitHub.',
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Secret Gist personal',
                  description:
                      'Tus copias se guardan en un Gist secreto exclusivo de tu cuenta de GitHub. Solo quien tenga tu token o el enlace exacto puede acceder.',
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.history_edu_rounded,
                  title: 'Historial de revisiones (Commits)',
                  description:
                      'Cada sincronización crea un punto de restauración en el historial de versiones de GitHub, garantizando que nunca pierdas datos.',
                ),
                const SizedBox(height: 10),
                _FeatureCard(
                  icon: Icons.vpn_key_outlined,
                  title: 'Token resguardado en Keystore',
                  description:
                      'Tu Personal Access Token se almacena en el almacén de credenciales cifrado nativo de tu dispositivo.',
                ),
                const SizedBox(height: 24),

                // Guía para obtener el token si no está conectado
                if (!connected) ...[
                  LedgerPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.help_outline_rounded, color: KwallTheme.accent),
                            const SizedBox(width: 8),
                            const Text(
                              '¿Cómo obtener tu Token?',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '1. Inicia sesión en github.com en tu navegador.\n'
                          '2. Ve a Settings → Developer Settings → Personal access tokens → Tokens (classic).\n'
                          '3. Haz clic en "Generate new token (classic)".\n'
                          '4. Asigna un nombre (ej. "kwall-backup") y marca ÚNICAMENTE el permiso "gist".\n'
                          '5. Copia el token que empieza por ghp_ y pégalo arriba.',
                          style: TextStyle(fontSize: 12, height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () => _openGitHub('https://github.com/settings/tokens'),
                          icon: const Icon(Icons.open_in_browser_rounded, size: 16),
                          label: const Text('Abrir GitHub Tokens'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: KwallTheme.surfaceContainer.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: KwallTheme.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: KwallTheme.accent, size: 18),
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
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
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
  }
}
