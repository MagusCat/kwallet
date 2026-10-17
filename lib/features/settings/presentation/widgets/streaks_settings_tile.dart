import 'package:flutter/material.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../../../core/widgets/finance_widgets.dart';

class StreaksSettingsTile extends StatelessWidget {
  final Map<String, String> settings;
  final Future<void> Function(String key, String value) onToggle;

  const StreaksSettingsTile({
    super.key,
    required this.settings,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = settings['disable_streaks'] == 'true';

    return LedgerPanel(
      child: Row(
        children: [
          Icon(
            disabled ? Icons.timer_off_outlined : Icons.local_fire_department_rounded,
            size: 20,
            color: disabled ? KwallTheme.textSecondary : KwallTheme.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Desactivar rachas',
                  style: KwallTheme.fontTitle.copyWith(fontSize: 16),
                ),
                Text(
                  disabled
                      ? 'Rachas ocultas para avanzar a tu propio ritmo'
                      : 'Contadores de racha activos en tus hábitos',
                  style: TextStyle(
                    fontSize: 12,
                    color: KwallTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: disabled,
            activeThumbColor: KwallTheme.accent,
            onChanged: (val) => onToggle('disable_streaks', val.toString()),
          ),
        ],
      ),
    );
  }
}
