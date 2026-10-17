import 'package:flutter/material.dart';

import '../theme/kwall_theme.dart';
import 'pet_selection_panel.dart';

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
      PetSelectionPanel(
        selectedStyle: settings['pet_style'] ?? 'classic',
        onSelectStyle: onChoose,
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
