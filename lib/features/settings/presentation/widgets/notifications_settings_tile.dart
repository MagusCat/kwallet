import 'package:flutter/material.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../../../core/widgets/finance_widgets.dart';

class NotificationsSettingsTile extends StatelessWidget {
  final Map<String, String> settings;
  final Future<void> Function(String key, String value) onToggle;

  const NotificationsSettingsTile({
    super.key,
    required this.settings,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = settings['notifications_enabled'] != 'false';
    final notifyFinances = settings['notify_finances'] != 'false';
    final notifyHabits = settings['notify_habits'] != 'false';
    final notifyPet = settings['notify_pet'] != 'false';

    return LedgerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 20,
                color: KwallTheme.accent,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notificaciones en la app',
                      style: KwallTheme.fontTitle.copyWith(fontSize: 16),
                    ),
                    Text(
                      enabled ? 'Alertas visuales activadas' : 'Desactivadas',
                      style: TextStyle(
                        fontSize: 12,
                        color: KwallTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                activeThumbColor: KwallTheme.accent,
                onChanged: (val) => onToggle('notifications_enabled', val.toString()),
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 12),
            Divider(color: KwallTheme.border.withValues(alpha: 0.3)),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Finanzas y compromisos'),
              subtitle: const Text('Avisos de vencimientos y presupuestos'),
              value: notifyFinances,
              activeColor: KwallTheme.accent,
              onChanged: (val) => onToggle('notify_finances', (val ?? true).toString()),
            ),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Hábitos diarios'),
              subtitle: const Text('Recordatorios según el momento del día'),
              value: notifyHabits,
              activeColor: KwallTheme.accent,
              onChanged: (val) => onToggle('notify_habits', (val ?? true).toString()),
            ),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Mascota'),
              subtitle: const Text('Alertas de cariño y estado de ánimo'),
              value: notifyPet,
              activeColor: KwallTheme.accent,
              onChanged: (val) => onToggle('notify_pet', (val ?? true).toString()),
            ),
          ],
        ],
      ),
    );
  }
}
