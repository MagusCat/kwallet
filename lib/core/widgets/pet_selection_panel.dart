import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pet_species.dart';
import '../theme/kwall_theme.dart';
import 'kitty_companion.dart';

class PetSelectionPanel extends StatefulWidget {
  final String selectedStyle;
  final ValueChanged<String> onSelectStyle;
  final ValueChanged<String>? onNameSuggested;

  const PetSelectionPanel({
    super.key,
    required this.selectedStyle,
    required this.onSelectStyle,
    this.onNameSuggested,
  });

  @override
  State<PetSelectionPanel> createState() => _PetSelectionPanelState();
}

class _PetSelectionPanelState extends State<PetSelectionPanel> {
  PetSpecies? _filterSpecies;

  @override
  void initState() {
    super.initState();
    // Default species filter based on initial selected style
    final currentDef = PetSpeciesCatalog.get(widget.selectedStyle);
    _filterSpecies = currentDef.species;
  }

  void _pickRandom() {
    HapticFeedback.mediumImpact();
    final randomStyle = PetSpeciesCatalog.pickRandom(species: _filterSpecies);
    widget.onSelectStyle(randomStyle.key);
    widget.onNameSuggested?.call(randomStyle.name);
  }

  @override
  Widget build(BuildContext context) {
    final styles = PetSpeciesCatalog.forSpecies(_filterSpecies);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Species filter & Random picker
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected: _filterSpecies == null,
                onSelected: (_) => setState(() => _filterSpecies = null),
              ),
              const SizedBox(width: 6),
              for (final species in PetSpecies.values) ...[
                FilterChip(
                  label: Text(species.label),
                  selected: _filterSpecies == species,
                  onSelected: (selected) {
                    setState(() {
                      _filterSpecies = selected ? species : null;
                    });
                  },
                ),
                const SizedBox(width: 6),
              ],
              ActionChip(
                avatar: const Icon(Icons.casino_outlined, size: 18),
                label: const Text('Al azar'),
                onPressed: _pickRandom,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Pet style cards
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final style in styles)
              _buildStyleTile(context, style),
          ],
        ),
      ],
    );
  }

  Widget _buildStyleTile(BuildContext context, PetStyleDef style) {
    final isSelected = widget.selectedStyle == style.key;

    return Semantics(
      selected: isSelected,
      label: '${style.species.label} ${style.name}',
      child: Material(
        color: isSelected ? KwallTheme.accentLight : KwallTheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isSelected ? KwallTheme.accent : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onSelectStyle(style.key);
            widget.onNameSuggested?.call(style.name);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IgnorePointer(
                  child: TickerMode(
                    enabled: false,
                    child: KittyCompanionWidget(
                      size: 42,
                      settings: {'pet_style': style.key},
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  style.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? KwallTheme.accent : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
