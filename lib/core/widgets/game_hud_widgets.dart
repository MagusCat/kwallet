import 'package:flutter/material.dart';
import '../theme/kwall_theme.dart';

/// Clean Google Material 3 Expressive Budget Bar
class ExpressiveBudgetBar extends StatelessWidget {
  final double spent;
  final double budget;
  final String currency;

  const ExpressiveBudgetBar({
    super.key,
    required this.spent,
    required this.budget,
    this.currency = '\$',
  });

  @override
  Widget build(BuildContext context) {
    final validBudget = budget <= 0 ? 1.0 : budget;
    final ratio = (spent / validBudget).clamp(0.0, 1.5);
    final remaining = budget - spent;
    final percentage = ((spent / validBudget) * 100).toInt();

    Color statusColor;
    String statusText;
    if (ratio >= 1.0) {
      statusColor = KwallTheme.expenseRed;
      statusText = 'Límite excedido';
    } else if (ratio >= 0.8) {
      statusColor = KwallTheme.warningAmber;
      statusText = '80% utilizado';
    } else {
      statusColor = KwallTheme.accent;
      statusText = 'En presupuesto';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KwallTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KwallTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Presupuesto mensual',
                style: KwallTheme.fontTitle.copyWith(
                  fontSize: 13,
                  color: KwallTheme.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: KwallTheme.fontBody.copyWith(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Expressive progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: KwallTheme.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gastado: ${KwallTheme.formatCurrency(spent, currency)} de ${KwallTheme.formatCurrency(budget, currency)}',
                style: KwallTheme.fontBody.copyWith(
                  color: KwallTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                remaining >= 0
                    ? 'Quedan ${KwallTheme.formatCurrency(remaining, currency)} ($percentage%)'
                    : 'Exceso: ${KwallTheme.formatCurrency(-remaining, currency)}',
                style: KwallTheme.fontBody.copyWith(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Material 3 Expressive Tactile Button
class ExpressiveButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? color;
  final Color? textColor;
  final bool isOutlined;
  final EdgeInsetsGeometry padding;

  const ExpressiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.textColor,
    this.isOutlined = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
  });

  @override
  State<ExpressiveButton> createState() => _ExpressiveButtonState();
}

class _ExpressiveButtonState extends State<ExpressiveButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? KwallTheme.accent;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.isOutlined ? Colors.transparent : effectiveColor,
            borderRadius: BorderRadius.circular(16),
            border: widget.isOutlined
                ? Border.all(color: effectiveColor.withValues(alpha: 0.5), width: 1.5)
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
