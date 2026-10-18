import 'package:flutter/material.dart';

import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/finance_widgets.dart';
import '../../../core/widgets/financial_balance_card.dart';
import '../../../core/widgets/juice_widgets.dart';
import '../../../core/widgets/pet_cameo_empty_state.dart';
import '../models/account.dart';
import '../view_models/home_view_model.dart';
import 'movements_screen.dart';
import 'widgets/budget_panel.dart';
import 'widgets/movement_tile.dart';

class FinancesScreen extends StatelessWidget {
  final HomeViewModel controller;
  final ValueChanged<String> onTransaction;
  final VoidCallback onAddAccount;
  final ValueChanged<Account> onEditAccount;
  final VoidCallback onBudget;
  final VoidCallback onAgenda;

  const FinancesScreen({
    super.key,
    required this.controller,
    required this.onTransaction,
    required this.onAddAccount,
    required this.onEditAccount,
    required this.onBudget,
    required this.onAgenda,
  });

  @override
  Widget build(BuildContext context) {
    final cashByCur = controller.cashByCurrency;

    return SafeArea(
      bottom: false,
      child: ContentWidth(
        child: RefreshIndicator(
          onRefresh: controller.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              // Header de Finanzas
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: KwallTheme.accentLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: KwallTheme.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Finanzas',
                          style: KwallTheme.fontTitle.copyWith(fontSize: 26),
                        ),
                        Text(
                          'Control de ingresos, gastos y cuentas',
                          style: TextStyle(
                            fontSize: 12,
                            color: KwallTheme.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Presupuesto',
                    onPressed: onBudget,
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 1. Unified Balance Card
              FinancialBalanceCard(
                title: 'Saldo Total',
                balance: controller.balance,
                available: controller.available,
                currency: controller.currency,
                cashByCurrency: cashByCur,
              ),
              const SizedBox(height: 16),

              // 2. Botones de Registro de Movimiento (Gasto, Ingreso, Transferir)
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
              const SizedBox(height: 16),

              // Compromisos semanales
              CommitmentAlert(
                balance: controller.balance,
                committed: controller.committed,
                currency: controller.currency,
              ),
              const SizedBox(height: 12),

              // 3. Cuentas
              LedgerPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Cuentas (${controller.accounts.length})',
                          style: KwallTheme.fontTitle.copyWith(fontSize: 18),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Nueva cuenta',
                          onPressed: onAddAccount,
                          icon: const Icon(Icons.add_rounded, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (controller.accounts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: OutlinedButton.icon(
                          onPressed: onAddAccount,
                          icon: const Icon(Icons.add_card_rounded),
                          label: const Text('Agregar primera cuenta'),
                        ),
                      )
                    else
                      for (final account in controller.accounts) ...[
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => onEditAccount(account),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(account.colorValue).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 18,
                                    color: Color(account.colorValue),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        account.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Text(
                                        account.type == 'cash'
                                            ? 'Efectivo'
                                            : account.type == 'bank'
                                            ? 'Banco'
                                            : 'Ahorro',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: KwallTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  KwallTheme.formatCurrency(
                                    account.balance,
                                    account.currency,
                                  ),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: account.balance < 0
                                        ? KwallTheme.expenseRed
                                        : KwallTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 18,
                                  color: KwallTheme.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 10),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Presupuesto
              BudgetPanel(controller: controller, onEdit: onBudget),
              const SizedBox(height: 20),

              // 5. Movimientos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Movimientos',
                    style: KwallTheme.fontTitle.copyWith(fontSize: 21),
                  ),
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MovementsScreen(currency: controller.currency),
                      ),
                    ),
                    icon: const Icon(Icons.manage_search_rounded, size: 18),
                    label: const Text('Ver todos'),
                  ),
                ],
              ),
              if (controller.transactions.isEmpty)
                const PetCameoEmptyState(
                  label: 'No hay movimientos recientes.',
                  iconBadge: Icons.monetization_on_outlined,
                ),
              for (final tx in controller.transactions.take(10))
                MovementTile(
                  tx: tx,
                  currency: controller.currency,
                  categories: controller.categories,
                  onVoid: controller.voidMovement,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
