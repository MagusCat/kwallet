import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../view_models/home_view_model.dart';

class QuickExpenseShortcuts extends StatelessWidget {
  final HomeViewModel controller;

  const QuickExpenseShortcuts({
    super.key,
    required this.controller,
  });

  static const _shortcuts = [
    (title: 'Café', amount: 2.0, icon: Icons.coffee_rounded, cat: 'cat_leisure'),
    (title: 'Bus / Metro', amount: 1.5, icon: Icons.directions_bus_rounded, cat: 'cat_transport'),
    (title: 'Snack', amount: 3.0, icon: Icons.fastfood_rounded, cat: 'cat_food'),
    (title: 'Agua', amount: 1.0, icon: Icons.water_drop_rounded, cat: 'cat_food'),
  ];

  Future<void> _trigger(
    BuildContext context, {
    required String title,
    required double amount,
    required String categoryId,
  }) async {
    HapticFeedback.lightImpact();
    final record = await controller.logQuickExpense(
      title: title,
      amount: amount,
      categoryId: categoryId,
    );

    if (record != null && context.mounted) {
      final currency = controller.accounts.firstOrNull?.currency ?? controller.currency;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          content: Text(
            '$title (${KwallTheme.formatCurrency(amount, currency)}) registrado',
          ),
          action: SnackBarAction(
            label: 'Deshacer',
            textColor: KwallTheme.accent,
            onPressed: () {
              controller.voidMovement(record);
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller.accounts.isEmpty) return const SizedBox.shrink();

    final currency = controller.accounts.firstOrNull?.currency ?? controller.currency;

    return LedgerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on_rounded,
                size: 18,
                color: KwallTheme.accent,
              ),
              const SizedBox(width: 8),
              Text(
                'Gastos rápidos (1 toque)',
                style: KwallTheme.fontTitle.copyWith(fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in _shortcuts) ...[
                  ActionChip(
                    avatar: Icon(
                      item.icon,
                      size: 15,
                      color: KwallTheme.accent,
                    ),
                    label: Text(
                      '${item.title} (${KwallTheme.formatCurrency(item.amount, currency)})',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: KwallTheme.textPrimary,
                      ),
                    ),
                    backgroundColor:
                        KwallTheme.surfaceContainer.withValues(alpha: 0.7),
                    side: BorderSide(
                      color: KwallTheme.border.withValues(alpha: 0.35),
                    ),
                    onPressed: () => _trigger(
                      context,
                      title: item.title,
                      amount: item.amount,
                      categoryId: item.cat,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
