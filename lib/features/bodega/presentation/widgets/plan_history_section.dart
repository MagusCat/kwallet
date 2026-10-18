import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../view_models/planning_view_model.dart';

class PlanHistorySection extends StatelessWidget {
  final PlanningViewModel model;
  final String currency;

  const PlanHistorySection({
    super.key,
    required this.model,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final payments = model.paymentHistory;
    final completed = model.completedPlans;
    if (payments.isEmpty && completed.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: LedgerPanel(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            leading: Icon(
              Icons.history_rounded,
              color: KwallTheme.incomeGreen,
              size: 20,
            ),
            title: Text(
              'Historial de pagos (${payments.length})',
              style: KwallTheme.fontTitle.copyWith(fontSize: 15),
            ),
            subtitle: completed.isNotEmpty
                ? Text(
                    '${completed.length} compromisos completados',
                    style: TextStyle(
                      fontSize: 12,
                      color: KwallTheme.textSecondary,
                    ),
                  )
                : null,
            children: [
              const SizedBox(height: 8),
              if (payments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Aún no hay cuotas pagadas.',
                    style: TextStyle(color: KwallTheme.textSecondary),
                  ),
                )
              else
                for (final payment in payments.take(15)) _paymentTile(payment),
              if (completed.isNotEmpty) ...[
                const Divider(height: 24),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Compromisos completados',
                    style: KwallTheme.fontTitle.copyWith(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 6),
                for (final plan in completed)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.check_circle_rounded,
                      color: KwallTheme.incomeGreen,
                      size: 18,
                    ),
                    title: Text(
                      plan.title,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    trailing: Text(
                      KwallTheme.formatCurrency(plan.amount, currency),
                      style: TextStyle(
                        color: KwallTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentTile(Map<String, dynamic> payment) {
    final paidAtStr = payment['paid_at'] as String?;
    final paidAt = paidAtStr != null ? DateTime.tryParse(paidAtStr) : null;
    final dueDateStr = payment['due_date'] as String?;
    final dueDate = dueDateStr != null ? DateTime.tryParse(dueDateStr) : null;
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0.0;
    final planId = payment['planned_expense_id'] as String?;
    final plan = model.plans.where((p) => p.id == planId).firstOrNull;
    final title = plan?.title ?? 'Compromiso';

    final paidDateText = paidAt != null
        ? DateFormat('dd/MM/yyyy', 'es').format(paidAt)
        : 'Reciente';
    final dueDateText = dueDate != null
        ? DateFormat('dd/MM/yyyy', 'es').format(dueDate)
        : '';

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.check_circle_outline_rounded,
        color: KwallTheme.incomeGreen,
        size: 18,
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(
        'Pagado el $paidDateText${dueDateText.isNotEmpty ? ' · Vencía: $dueDateText' : ''}',
        style: TextStyle(fontSize: 11, color: KwallTheme.textSecondary),
      ),
      trailing: Text(
        KwallTheme.formatCurrency(amount, currency),
        style: TextStyle(
          color: KwallTheme.incomeGreen,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
