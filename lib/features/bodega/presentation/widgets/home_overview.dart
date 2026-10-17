import 'package:flutter/material.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../view_models/home_view_model.dart';
import 'pet_hero_card.dart';

class HomeOverview extends StatelessWidget {
  final HomeViewModel controller;
  final VoidCallback? onOpenFinances;
  final VoidCallback? onSettings;
  final ValueChanged<bool>? onPetHoldChanged;

  const HomeOverview({
    super.key,
    required this.controller,
    this.onOpenFinances,
    this.onSettings,
    this.onPetHoldChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cashByCur = controller.cashByCurrency;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Saludo de bienvenida con acceso a ajustes
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bienvenido',
                style: KwallTheme.fontTitle.copyWith(fontSize: 26),
              ),
              if (onSettings != null)
                IconButton.filledTonal(
                  tooltip: 'Ajustes',
                  onPressed: onSettings,
                  icon: const Icon(Icons.tune_rounded, size: 20),
                ),
            ],
          ),
        ),

        // 1. CARD PRINCIPAL: LA MASCOTA VIRTUAL
        PetHeroCard(
          controller: controller,
          onHoldChanged: onPetHoldChanged,
        ),
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
              if (cashByCur.length > 1) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final entry in cashByCur.entries)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: KwallTheme.surfaceContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: KwallTheme.border.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '${entry.key}: ${KwallTheme.formatCurrency(entry.value, entry.key)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: KwallTheme.textSecondary,
                          ),
                        ),
                      ),
                  ],
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
