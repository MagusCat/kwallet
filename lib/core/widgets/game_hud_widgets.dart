import 'package:flutter/material.dart';
import '../theme/kwall_theme.dart';

/// Segmented Video Game Health/Mana Bar for Budgets
/// "Mostrar en lugar de explicar"
class HudHealthBar extends StatelessWidget {
  final double spent;
  final double budget;
  final String label;

  const HudHealthBar({
    super.key,
    required this.spent,
    required this.budget,
    this.label = 'ESCUDO FINANCIERO',
  });

  @override
  Widget build(BuildContext context) {
    final validBudget = budget <= 0 ? 1.0 : budget;
    final ratio = (spent / validBudget).clamp(0.0, 1.5);
    final remaining = (budget - spent).clamp(0.0, double.infinity);
    final percentage = ((1.0 - (spent / validBudget)) * 100).clamp(0, 100).toInt();

    // Determine state color based on health
    Color barColor;
    String statusTitle;
    if (ratio >= 1.0) {
      barColor = KwallTheme.plasmaPink;
      statusTitle = 'CRÍTICO / ESCUDO ROTO';
    } else if (ratio >= 0.75) {
      barColor = KwallTheme.cyberGold;
      statusTitle = 'ALERTA / 25% RESTANTE';
    } else {
      barColor = KwallTheme.neonGreen;
      statusTitle = 'ESTABLE / ÓPTIMO';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KwallTheme.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KwallTheme.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: barColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: barColor.withValues(alpha: 0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: KwallTheme.hudHeaderFont.copyWith(
                      color: KwallTheme.textMuted,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              Text(
                statusTitle,
                style: KwallTheme.gameFont.copyWith(
                  color: barColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Segmented Game Bar
          Stack(
            children: [
              // Track background
              Container(
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF0C0E14),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: KwallTheme.borderBright, width: 1),
                ),
              ),
              // Filled Progress with segments
              LayoutBuilder(
                builder: (context, constraints) {
                  final fillWidth = constraints.maxWidth * (1.0 - (ratio.clamp(0.0, 1.0)));
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: 18,
                    width: fillWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      gradient: LinearGradient(
                        colors: [
                          barColor.withValues(alpha: 0.8),
                          barColor,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: barColor.withValues(alpha: 0.35),
                          blurRadius: 8,
                        )
                      ],
                    ),
                  );
                },
              ),
              // Segment lines overlay (Grid effect)
              Positioned.fill(
                child: Row(
                  children: List.generate(
                    10,
                    (index) => Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.black.withValues(alpha: 0.55),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Values footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gastado: ${KwallTheme.formatCurrency(spent)} / ${KwallTheme.formatCurrency(budget)}',
                style: const TextStyle(
                  color: KwallTheme.textMuted,
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                '$percentage% HP RESTANTE (${KwallTheme.formatCurrency(remaining)})',
                style: KwallTheme.gameFont.copyWith(
                  color: barColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tactile Video Game Button with 3D drop effect & haptic feedback
class HudButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color color;
  final Color textColor;
  final EdgeInsetsGeometry padding;
  final bool isSecondary;

  const HudButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color = KwallTheme.neonGreen,
    this.textColor = Colors.black,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.isSecondary = false,
  });

  @override
  State<HudButton> createState() => _HudButtonState();
}

class _HudButtonState extends State<HudButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.isSecondary ? KwallTheme.surfaceCardHighlight : widget.color;
    final borderColor = widget.isSecondary ? KwallTheme.borderBright : widget.color.withValues(alpha: 0.8);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        padding: widget.padding,
        transform: Matrix4.translationValues(0, _isPressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                  if (!widget.isSecondary)
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.3),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                ],
        ),
        child: widget.child,
      ),
    );
  }
}

/// HUD Stat Pip (e.g. LVL 1, 85 HP)
class GamerStatPip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const GamerStatPip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: KwallTheme.surfaceCardHighlight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            '$label: ',
            style: const TextStyle(
              color: KwallTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            value,
            style: KwallTheme.gameFont.copyWith(
              color: color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
