import 'package:flutter/material.dart';

import '../theme/kwall_theme.dart';
import 'kitty_companion.dart';

class PetPicker extends StatelessWidget {
  final Map<String, String> settings;
  final bool busy;
  final String? error;
  final ValueChanged<String> onChoose;
  final VoidCallback onUpload;
  const PetPicker({
    super.key,
    required this.settings,
    required this.busy,
    required this.onChoose,
    required this.onUpload,
    this.error,
  });
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 360 ? 3 : 4;
          final itemWidth =
              (constraints.maxWidth - (columns - 1) * 8) / columns;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final style in petStyles.entries)
                SizedBox(
                  width: itemWidth,
                  child: Semantics(
                    selected: (settings['pet_style'] ?? 'classic') == style.key,
                    child: Material(
                      color: (settings['pet_style'] ?? 'classic') == style.key
                          ? KwallTheme.accentLight
                          : KwallTheme.surfaceContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color:
                              (settings['pet_style'] ?? 'classic') == style.key
                              ? KwallTheme.accent
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: busy ? null : () => onChoose(style.key),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            children: [
                              IgnorePointer(
                                child: TickerMode(
                                  enabled: false,
                                  child: KittyCompanionWidget(
                                    size: 48,
                                    settings: {'pet_style': style.key},
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                style.value,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 10),
      if (settings['pet_image_data']?.isNotEmpty == true &&
          settings['pet_style'] != 'custom')
        TextButton.icon(
          onPressed: busy ? null : () => onChoose('custom'),
          icon: const Icon(Icons.pets_outlined),
          label: const Text('Mi mascota guardada'),
        ),
      OutlinedButton.icon(
        onPressed: busy ? null : onUpload,
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: Text(
          settings['pet_style'] == 'custom'
              ? 'Cambiar mi imagen'
              : 'Usar mi mascota',
        ),
      ),
      if (busy)
        const Padding(
          padding: EdgeInsets.all(8),
          child: LinearProgressIndicator(),
        ),
      if (error != null)
        Text(error!, style: TextStyle(color: KwallTheme.expenseRed)),
    ],
  );
}
