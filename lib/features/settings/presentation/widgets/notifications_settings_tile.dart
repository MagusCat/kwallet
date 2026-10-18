import 'package:flutter/material.dart';

import '../../../../core/services/notification_service.dart';
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

  Future<void> _pickTime(BuildContext context, String key, String defaultVal) async {
    final raw = settings[key] ?? defaultVal;
    final parts = raw.split(':').map((s) => int.tryParse(s) ?? 0).toList();
    final initial = TimeOfDay(
      hour: parts.isNotEmpty ? parts[0] : 8,
      minute: parts.length > 1 ? parts[1] : 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: key == 'day_start_time'
          ? 'Hora de inicio de día (Flow Start)'
          : 'Hora de finalización de día (Cierre)',
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await onToggle(key, formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = settings['notifications_enabled'] != 'false';
    final notifyStart = settings['notify_day_start'] != 'false';
    final notifyEnd = settings['notify_day_end'] != 'false';
    final startTime = settings['day_start_time'] ?? '08:00';
    final endTime = settings['day_end_time'] ?? '21:00';

    final notifyFinances = settings['notify_finances'] != 'false';
    final notifyHabits = settings['notify_habits'] != 'false';
    final notifyPet = settings['notify_pet'] != 'false';

    final petName = settings['pet_name'] ?? 'Mishi';

    return LedgerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: KwallTheme.accentLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  size: 20,
                  color: KwallTheme.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notificaciones y Rutinas',
                      style: KwallTheme.fontTitle.copyWith(fontSize: 16),
                    ),
                    Text(
                      enabled
                          ? 'Alertas de inicio de día y rutinas activas'
                          : 'Desactivadas por completo',
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

            // 1. Inicio de día (Flow Start)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: notifyStart,
                    activeColor: KwallTheme.accent,
                    onChanged: (val) =>
                        onToggle('notify_day_start', (val ?? true).toString()),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Inicio de día (Flow Start)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Motivación para registrar y arrancar tu día',
                          style: TextStyle(
                            fontSize: 12,
                            color: KwallTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: notifyStart
                        ? () => _pickTime(context, 'day_start_time', '08:00')
                        : null,
                    icon: const Icon(Icons.schedule_rounded, size: 16),
                    label: Text(startTime),
                  ),
                ],
              ),
            ),

            // 2. Finalización de día (Cierre nocturno)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: notifyEnd,
                    activeColor: KwallTheme.accent,
                    onChanged: (val) =>
                        onToggle('notify_day_end', (val ?? true).toString()),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Finalización de día (Cierre)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Recordatorio para cerrar gastos y hábitos antes de dormir',
                          style: TextStyle(
                            fontSize: 12,
                            color: KwallTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: notifyEnd
                        ? () => _pickTime(context, 'day_end_time', '21:00')
                        : null,
                    icon: const Icon(Icons.nightlight_round, size: 16),
                    label: Text(endTime),
                  ),
                ],
              ),
            ),

            Divider(color: KwallTheme.border.withValues(alpha: 0.3)),

            // Otras categorías
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
              subtitle: const Text('Recordatorios según el bloque del día'),
              value: notifyHabits,
              activeColor: KwallTheme.accent,
              onChanged: (val) => onToggle('notify_habits', (val ?? true).toString()),
            ),
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text('Mascota y compañero'),
              subtitle: const Text('Alertas de cariño y estado de ánimo'),
              value: notifyPet,
              activeColor: KwallTheme.accent,
              onChanged: (val) => onToggle('notify_pet', (val ?? true).toString()),
            ),

            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    NotificationService.showDayStartNotification(
                      petName: petName,
                      settings: settings,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notificación de inicio de día enviada'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.wb_sunny_rounded, size: 16),
                  label: const Text('Probar inicio'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    NotificationService.showDayEndNotification(
                      petName: petName,
                      settings: settings,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notificación de fin de día enviada'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.nights_stay_rounded, size: 16),
                  label: const Text('Probar fin de día'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
