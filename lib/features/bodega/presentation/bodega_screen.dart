import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/mvvm/view_model_state.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/kitty_companion.dart';
import '../../../core/widgets/finance_widgets.dart';
import '../../../core/widgets/pet_loading_screen.dart';
import '../../../core/widgets/juice_widgets.dart';
import '../../journal/presentation/journal_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../view_models/home_view_model.dart';
import '../models/account.dart';
import 'add_account_dialog.dart';
import 'add_transaction_sheet.dart';
import 'budget_sheet.dart';
import 'categories_sheet.dart';
import 'planned_expenses_screen.dart';
import 'widgets/home_dashboard.dart';

class BodegaScreen extends StatefulWidget {
  final int initialPage;
  const BodegaScreen({super.key, this.initialPage = 0});
  @override
  State<BodegaScreen> createState() => _BodegaScreenState();
}

class _BodegaScreenState extends ViewModelState<BodegaScreen, HomeViewModel>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late int _nav = widget.initialPage;
  late final AnimationController _navigation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
    value: 1,
  );
  late final Animation<double> _navigationOpacity = _navigation
      .drive(CurveTween(curve: Curves.easeOutCubic))
      .drive(Tween<double>(begin: .8, end: 1));
  int _journalTab = 0;
  @override
  HomeViewModel createViewModel(AppDependencies dependencies) =>
      dependencies.home();
  HomeViewModel get _home => model;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _navigation.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _home.load();
  }

  @override
  void onViewModelChanged() {
    if (!mounted) return;
    final gained = _home.takeReward();
    if (gained > 0) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          content: Row(
            children: [
              KittyCompanionWidget(
                size: 40,
                settings: _home.settings,
                activity: PetActivity.celebrate,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('¡Un paso más! +$gained XP')),
            ],
          ),
        ),
      );
    }
  }

  void _transaction(String type) {
    if (_home.accounts.isEmpty) {
      _account();
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 180),
        reverseDuration: Duration(milliseconds: 120),
      ),
      builder: (_) => AddTransactionSheet(
        accounts: _home.accounts,
        preselectedAccountId: _home.filter,
        initialType: type,
        currency: _home.currency,
      ),
    );
  }

  void _account({String type = 'cash', Account? account}) => showDialog(
    context: context,
    builder: (_) => AddAccountDialog(
      currency: _home.currency,
      initialType: type,
      account: account,
    ),
  );
  void _budgetEditor() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BudgetSheet(
      period: _home.period,
      current: _home.limit,
      available: _home.available,
      currency: _home.currency,
      mode: _home.budgetMode,
      share: _home.share,
    ),
  );
  void _quickActions() {
    final actions = <(IconData, String, VoidCallback)>[
      (Icons.north_east_rounded, 'Gasto', () => _transaction('expense')),
      (Icons.south_west_rounded, 'Ingreso', () => _transaction('income')),
      (Icons.swap_horiz_rounded, 'Transferir', () => _transaction('transfer')),
      (Icons.account_balance_outlined, 'Banco', () => _account(type: 'bank')),
      (
        Icons.edit_note_rounded,
        'Nota',
        () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const NoteSheet(),
        ),
      ),
      (Icons.event_outlined, 'Fecha', () => _navigate(1)),
      (
        Icons.category_outlined,
        'Categorías',
        () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const CategoriesSheet(type: 'expense'),
        ),
      ),
      (Icons.local_fire_department_outlined, 'Hábitos', () => _openJournal(1)),
      (Icons.palette_outlined, 'Apariencia', () => _navigate(3)),
    ];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SheetBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Qué hacemos?',
              style: KwallTheme.fontTitle.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    constraints.maxWidth < 320 ||
                        MediaQuery.textScalerOf(context).scale(14) > 20
                    ? 2
                    : 3;
                final width =
                    (constraints.maxWidth - (columns - 1) * 12) / columns;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final (icon, label, action) in actions)
                      SizedBox(
                        width: width,
                        child: JuiceButton(
                          icon: icon,
                          label: label,
                          onPressed: () {
                            Navigator.pop(ctx);
                            action();
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    if (_home.budget == null) {
      return PetLoadingScreen(
        settings: _home.settings,
        failed: _home.error != null,
        onRetry: _home.load,
      );
    }
    final pages = [
      HomeDashboard(
        controller: _home,
        onTransaction: _transaction,
        onAddAccount: _account,
        onEditAccount: (account) => _account(account: account),
        onBudget: _budgetEditor,
        onAgenda: () => _navigate(1),
        onJournal: _openJournal,
      ),
      PlannedExpensesScreen(currency: _home.currency),
      JournalScreen(key: ValueKey(_journalTab), initialTab: _journalTab),
      SettingsScreen(
        currentCurrency: _home.currency,
        onCurrencyChanged: (_) {},
      ),
    ];
    return Scaffold(
      body: FadeTransition(
        opacity: _navigationOpacity,
        child: IndexedStack(
          index: _nav,
          children: [
            for (var i = 0; i < pages.length; i++)
              TickerMode(enabled: _nav == i, child: pages[i]),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Acciones rápidas',
        onPressed: _quickActions,
        child: const Icon(Icons.add_rounded, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        height: 78,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        color: KwallTheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            _destination(0, Icons.account_balance_wallet_outlined, 'Inicio'),
            _destination(1, Icons.calendar_month_outlined, 'Agenda'),
            const SizedBox(width: 72),
            _destination(2, Icons.spa_outlined, 'Mi espacio'),
            _destination(3, Icons.tune_rounded, 'Ajustes'),
          ],
        ),
      ),
    );
  }

  Widget _destination(int index, IconData icon, String label) => Expanded(
    child: Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          _navigate(index);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _nav == index
                      ? KwallTheme.accentLight
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: _nav == index
                      ? KwallTheme.accent
                      : KwallTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: _nav == index ? FontWeight.w700 : FontWeight.w400,
                  color: KwallTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  void _navigate(int page) {
    if (_nav == page) return;
    setState(() => _nav = page);
    if (MediaQuery.disableAnimationsOf(context)) {
      _navigation.value = 1;
    } else {
      _navigation.forward(from: 0);
    }
  }

  void _openJournal(int tab) {
    setState(() => _journalTab = tab);
    _navigate(2);
  }
}
