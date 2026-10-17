import 'package:flutter/material.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../view_models/home_view_model.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../../../core/widgets/juice_widgets.dart';
import '../../../../core/widgets/kitty_companion.dart';

class HomeOverview extends StatelessWidget {
  final HomeViewModel controller;
  final ValueChanged<String> onTransaction;
  const HomeOverview({
    super.key,
    required this.controller,
    required this.onTransaction,
  });
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final mirror = controller.settings['mirror_currency'] ?? '';
    final rate = double.tryParse(controller.settings['mirror_rate'] ?? '') ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Bienvenido',
                style: KwallTheme.fontTitle.copyWith(fontSize: 26),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: KwallTheme.accentLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: KwallTheme.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Nv. ${controller.xp ~/ 100 + 1} · ${controller.xp % 100}/100',
                    style: TextStyle(
                      color: KwallTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        LedgerPanel(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo total',
                      style: TextStyle(color: KwallTheme.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        KwallTheme.formatCurrency(
                          controller.balance,
                          controller.currency,
                        ),
                        style: KwallTheme.fontDisplay.copyWith(fontSize: 34),
                      ),
                    ),
                    if (mirror.isNotEmpty && rate > 0)
                      Text(
                        '≈ ${KwallTheme.formatCurrency(controller.balance * rate, mirror)}',
                        style: TextStyle(color: KwallTheme.textSecondary),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      'Libre ${KwallTheme.formatCurrency(controller.available, controller.currency)}',
                      style: TextStyle(
                        color: KwallTheme.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              KittyCompanionWidget(
                size: 96,
                reward: controller.xp,
                settings: controller.settings,
                activity: now.hour >= 22 || now.hour < 6
                    ? PetActivity.sleep
                    : PetActivity.idle,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CommitmentAlert(
          balance: controller.balance,
          committed: controller.committed,
          currency: controller.currency,
        ),
        Row(
          children: [
            Expanded(
              child: JuiceButton(
                icon: Icons.north_east_rounded,
                label: 'Gasto',
                filled: true,
                onPressed: () => onTransaction('expense'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: JuiceButton(
                icon: Icons.south_west_rounded,
                label: 'Ingreso',
                onPressed: () => onTransaction('income'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: JuiceButton(
                icon: Icons.swap_horiz_rounded,
                label: 'Transferir',
                onPressed: () => onTransaction('transfer'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
