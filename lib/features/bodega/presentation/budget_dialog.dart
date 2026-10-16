import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/game_hud_widgets.dart';

class BudgetDialog extends StatefulWidget {
  final double currentBudget;
  final double currentSpent;

  const BudgetDialog({
    super.key,
    required this.currentBudget,
    required this.currentSpent,
  });

  @override
  State<BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<BudgetDialog> {
  late TextEditingController _controller;
  late double _sliderValue;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentBudget.toStringAsFixed(0));
    _sliderValue = widget.currentBudget.clamp(100.0, 10000.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    final value = double.tryParse(_controller.text.trim()) ?? _sliderValue;
    if (value <= 0) return;

    await DatabaseService.instance.setMonthlyBudget(value);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: KwallTheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_rounded, color: KwallTheme.neonGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'CALIBRAR ESCUDO MENSUAL',
                      style: KwallTheme.hudHeaderFont.copyWith(
                        color: KwallTheme.textBright,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: KwallTheme.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Text(
              'Define el límite de gastos antes de que el Kitty Kwall entre en modo pánico o alerta roja.',
              style: TextStyle(color: KwallTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),

            // Live preview
            HudHealthBar(
              spent: widget.currentSpent,
              budget: _sliderValue,
              label: 'PREVISUALIZACIÓN DE ESCUDO',
            ),
            const SizedBox(height: 16),

            Slider(
              value: _sliderValue,
              min: 200.0,
              max: 5000.0,
              divisions: 48,
              activeColor: KwallTheme.neonGreen,
              inactiveColor: KwallTheme.borderBright,
              onChanged: (val) {
                setState(() {
                  _sliderValue = val;
                  _controller.text = val.toStringAsFixed(0);
                });
              },
            ),

            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: false),
              style: KwallTheme.gameFont.copyWith(color: KwallTheme.neonGreen, fontSize: 26),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: const TextStyle(color: KwallTheme.neonGreen),
                filled: true,
                fillColor: KwallTheme.surfaceCardHighlight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val);
                if (parsed != null && parsed >= 100 && parsed <= 20000) {
                  setState(() => _sliderValue = parsed.clamp(200.0, 5000.0));
                }
              },
            ),
            const SizedBox(height: 18),

            HudButton(
              onPressed: _saveBudget,
              color: KwallTheme.neonGreen,
              child: Center(
                child: Text(
                  'CONFIRMAR CAPACIDAD DEL ESCUDO',
                  style: KwallTheme.hudHeaderFont.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
