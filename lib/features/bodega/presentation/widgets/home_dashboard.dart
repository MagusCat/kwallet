import 'package:flutter/material.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../view_models/home_view_model.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../models/account.dart';
import '../movements_screen.dart';
import 'home_overview.dart';
import 'home_hub.dart';
import 'budget_panel.dart';
import 'movement_tile.dart';

class HomeDashboard extends StatelessWidget {
  final HomeViewModel controller;
  final ValueChanged<String> onTransaction;
  final VoidCallback onAddAccount;
  final ValueChanged<Account> onEditAccount;
  final VoidCallback onBudget;
  final VoidCallback onAgenda;
  final ValueChanged<int> onJournal;
  const HomeDashboard({
    super.key,
    required this.controller,
    required this.onTransaction,
    required this.onAddAccount,
    required this.onEditAccount,
    required this.onBudget,
    required this.onAgenda,
    required this.onJournal,
  });
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ContentWidth(
      child: RefreshIndicator(
        onRefresh: controller.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            HomeOverview(controller: controller, onTransaction: onTransaction),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.event_repeat_rounded,
                color: KwallTheme.accent,
              ),
              title: Text(
                '${KwallTheme.formatCurrency(controller.weeklyCommitments, controller.currency)} previstos esta semana',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: onAgenda,
            ),
            const SizedBox(height: 16),
            HomeHub(
              controller: controller,
              onAddAccount: onAddAccount,
              onEditAccount: onEditAccount,
              onJournal: onJournal,
            ),
            const SizedBox(height: 22),
            BudgetPanel(controller: controller, onEdit: onBudget),
            const SizedBox(height: 26),
            Text(
              'Movimientos',
              style: KwallTheme.fontTitle.copyWith(fontSize: 21),
            ),
            if (controller.transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Tu próxima acción empieza con +.',
                  style: TextStyle(color: KwallTheme.textSecondary),
                ),
              ),
            TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MovementsScreen(currency: controller.currency),
                ),
              ),
              icon: const Icon(Icons.manage_search_rounded),
              label: const Text('Ver todo el historial'),
            ),
            for (final tx in controller.transactions)
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
