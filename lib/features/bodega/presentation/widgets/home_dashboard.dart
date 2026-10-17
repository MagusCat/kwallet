import 'package:flutter/material.dart';

import '../../../../core/theme/kwall_theme.dart';
import '../../view_models/home_view_model.dart';
import '../../../../core/widgets/finance_widgets.dart';
import '../../../journal/presentation/habit_actions.dart';
import '../../../journal/presentation/journal_sheets.dart';
import '../../models/account.dart';
import '../movements_screen.dart';
import 'home_overview.dart';
import 'home_hub.dart';
import 'budget_panel.dart';
import 'movement_tile.dart';
import 'habit_dot_tracker.dart';
import 'home_tasks_panel.dart';
import 'quick_expense_shortcuts.dart';
import 'upcoming_dates_panel.dart';

class HomeDashboard extends StatefulWidget {
  final HomeViewModel controller;
  final ValueChanged<String> onTransaction;
  final VoidCallback onAddAccount;
  final ValueChanged<Account> onEditAccount;
  final VoidCallback onBudget;
  final VoidCallback onAgenda;
  final ValueChanged<int> onJournal;
  final VoidCallback? onOpenFinances;
  final VoidCallback? onSettings;

  const HomeDashboard({
    super.key,
    required this.controller,
    required this.onTransaction,
    required this.onAddAccount,
    required this.onEditAccount,
    required this.onBudget,
    required this.onAgenda,
    required this.onJournal,
    this.onOpenFinances,
    this.onSettings,
  });

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  bool _isHoldingPet = false;

  void _onPetHoldChanged(bool isHolding) {
    if (_isHoldingPet != isHolding) {
      setState(() => _isHoldingPet = isHolding);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: ContentWidth(
      child: RefreshIndicator(
        onRefresh: widget.controller.load,
        child: ListView(
          physics: _isHoldingPet
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            // 1. Hero Pet Companion & Resumen de Saldos y Acciones
            HomeOverview(
              controller: widget.controller,
              onOpenFinances: widget.onOpenFinances,
              onSettings: widget.onSettings,
              onPetHoldChanged: _onPetHoldChanged,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.event_repeat_rounded,
                color: KwallTheme.accent,
              ),
              title: Text(
                '${KwallTheme.formatCurrency(widget.controller.weeklyCommitments, widget.controller.currency)} previstos esta semana',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: widget.onAgenda,
            ),
            const SizedBox(height: 16),

            // 2. Hub de Cuentas, Notas y Hábitos (Selector interactivo)
            HomeHub(
              controller: widget.controller,
              onAddAccount: widget.onAddAccount,
              onEditAccount: widget.onEditAccount,
              onJournal: widget.onJournal,
            ),
            const SizedBox(height: 16),

            // 3. Hábitos con gráfico de 7 puntos y marcado directo
            HabitDotTracker(
              controller: widget.controller,
              onAddHabit: () => editHabit(context),
              onOpenHabits: () => widget.onJournal(1),
            ),
            const SizedBox(height: 16),

            // 4. Tareas pendientes de listas
            HomeTasksPanel(
              controller: widget.controller,
              onNewTask: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const NoteSheet(initialKind: 'list'),
              ),
              onOpenNotes: () => widget.onJournal(0),
            ),
            const SizedBox(height: 16),

            // 5. Fechas importantes y compromisos
            UpcomingDatesPanel(
              controller: widget.controller,
              onOpenAgenda: widget.onAgenda,
            ),
            const SizedBox(height: 16),

            BudgetPanel(controller: widget.controller, onEdit: widget.onBudget),
            const SizedBox(height: 16),
            QuickExpenseShortcuts(controller: widget.controller),
            const SizedBox(height: 26),
            Text(
              'Movimientos',
              style: KwallTheme.fontTitle.copyWith(fontSize: 21),
            ),
            if (widget.controller.transactions.isEmpty)
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
                      MovementsScreen(currency: widget.controller.currency),
                ),
              ),
              icon: const Icon(Icons.manage_search_rounded),
              label: const Text('Ver todo el historial'),
            ),
            for (final tx in widget.controller.transactions)
              MovementTile(
                tx: tx,
                currency: widget.controller.currency,
                categories: widget.controller.categories,
                onVoid: widget.controller.voidMovement,
              ),
          ],
        ),
      ),
    ),
  );
}
