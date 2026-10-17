import 'package:flutter/material.dart';

import '../../../../core/theme/kwall_theme.dart';

/// Selector modular para elegir el bloque horario de un hábito.
class HabitTimeBlockSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const HabitTimeBlockSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static const blocks = [
    ('anytime', 'Todo el día', Icons.all_inclusive_rounded),
    ('morning', 'Mañana', Icons.wb_sunny_rounded),
    ('afternoon', 'Tarde', Icons.wb_twilight_rounded),
    ('evening', 'Noche', Icons.nights_stay_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Momento del día',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: KwallTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (key, label, icon) in blocks)
              ChoiceChip(
                selected: selected == key,
                onSelected: (val) {
                  if (val) onChanged(key);
                },
                avatar: Icon(
                  icon,
                  size: 16,
                  color: selected == key
                      ? KwallTheme.onAccent
                      : KwallTheme.accent,
                ),
                label: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected == key
                        ? KwallTheme.onAccent
                        : KwallTheme.textPrimary,
                  ),
                ),
                selectedColor: KwallTheme.accent,
                backgroundColor:
                    KwallTheme.surfaceContainer.withValues(alpha: 0.5),
                side: BorderSide(
                  color: selected == key
                      ? KwallTheme.accent
                      : KwallTheme.border.withValues(alpha: 0.4),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
