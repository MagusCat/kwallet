import 'package:flutter/material.dart';

import '../theme/kwall_theme.dart';
import 'kitty_companion.dart';

class PetLoadingScreen extends StatelessWidget {
  final Map<String, String> settings;
  final bool failed;
  final VoidCallback? onRetry;
  const PetLoadingScreen({
    super.key,
    this.settings = const {},
    this.failed = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'kwall',
                  style: KwallTheme.fontTitle.copyWith(fontSize: 28),
                ),
                const SizedBox(height: 24),
                KittyCompanionWidget(
                  settings: settings,
                  size: 120,
                  activity: failed ? PetActivity.relax : PetActivity.walk,
                ),
                const SizedBox(height: 24),
                if (failed) ...[
                  const Text('No pudimos abrir tus datos.'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                  ),
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
