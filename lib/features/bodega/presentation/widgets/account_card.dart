import 'package:flutter/material.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../../../core/widgets/juice_widgets.dart';
import '../../models/account.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final String currency;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  const AccountCard({
    super.key,
    required this.account,
    required this.currency,
    required this.selected,
    required this.onTap,
    required this.onEdit,
  });
  @override
  Widget build(BuildContext context) {
    final below = account.balance < account.minimumBalance;
    final progress = account.minimumBalance > 0
        ? account.balance / account.minimumBalance
        : account.balance > 0
        ? 1.0
        : 0.0;
    final icon = switch (account.type) {
      'bank' => Icons.account_balance_outlined,
      'credit' => Icons.credit_card_rounded,
      'vault' => Icons.savings_outlined,
      _ => Icons.wallet_outlined,
    };
    return Material(
      color: selected ? KwallTheme.accentLight : KwallTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: below
              ? KwallTheme.expenseRed
              : KwallTheme.border.withValues(alpha: .65),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        onLongPress: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CircularMeter(
                      value: progress,
                      icon: icon,
                      size: 54,
                      color: below ? KwallTheme.expenseRed : KwallTheme.accent,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Editar mínimo de ${account.name}',
                    onPressed: onEdit,
                    icon: const Icon(Icons.more_horiz_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                account.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: KwallTheme.fontTitle,
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  KwallTheme.formatCurrency(account.balance, account.currency),
                  style: KwallTheme.fontDisplay.copyWith(fontSize: 20),
                ),
              ),
              if (account.currencies.length > 1) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final c in account.currencies.where((c) => c != account.currency))
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: KwallTheme.surfaceContainer.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '≈ $c ${account.balance.toStringAsFixed(2)} (1:1)',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: KwallTheme.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Mín. ${KwallTheme.formatCurrency(account.minimumBalance, account.currency)}',
                style: TextStyle(fontSize: 12, color: KwallTheme.textSecondary),
              ),
              if (below)
                Text(
                  'Bajo el mínimo',
                  style: TextStyle(
                    fontSize: 12,
                    color: KwallTheme.expenseRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
