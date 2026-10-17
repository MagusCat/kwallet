import 'package:flutter/material.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../view_models/home_view_model.dart';
import 'pet_hero_card.dart';

class HomeOverview extends StatelessWidget {
  final HomeViewModel controller;
  final VoidCallback? onOpenFinances;

  const HomeOverview({
    super.key,
    required this.controller,
    this.onOpenFinances,
  });

  @override
  Widget build(BuildContext context) {
    final mirror = controller.settings['mirror_currency'] ?? '';
    final rate = double.tryParse(controller.settings['mirror_rate'] ?? '') ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Saludo de bienvenida
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Bienvenido',
            style: KwallTheme.fontTitle.copyWith(fontSize: 26),
          ),
        ),

        // 1. CARD PRINCIPAL: LA MASCOTA VIRTUAL
        PetHeroCard(controller: controller),
        const SizedBox(height: 16),

        // 2. CARD DE ESTADO FINANCIERO (Sin botones de registro de movimiento)
        LedgerPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: KwallTheme.accentLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_outlined,
                      color: KwallTheme.accent,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Estado financiero',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: KwallTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onOpenFinances != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: onOpenFinances,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Finanzas',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: KwallTheme.accent,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 14,
                              color: KwallTheme.accent,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
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
              if (mirror.isNotEmpty && rate > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '≈ ${KwallTheme.formatCurrency(controller.balance * rate, mirror)}',
                  style: TextStyle(
                    fontSize: 13,
                    color: KwallTheme.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: KwallTheme.incomeGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Libre disponible: ${KwallTheme.formatCurrency(controller.available, controller.currency)}',
                      style: TextStyle(
                        color: KwallTheme.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Alerta de compromisos próximos
        CommitmentAlert(
          balance: controller.balance,
          committed: controller.committed,
          currency: controller.currency,
        ),
      ],
    );
  }
}
