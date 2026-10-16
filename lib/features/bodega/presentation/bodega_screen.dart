import 'package:flutter/material.dart';
import '../../../core/database/database_service.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/game_hud_widgets.dart';
import '../../../core/widgets/kitty_companion.dart';
import '../../../core/widgets/spending_chart.dart';
import '../models/account.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_record.dart';
import 'add_account_dialog.dart';
import 'add_transaction_sheet.dart';
import 'categories_sheet.dart';
import 'planned_expenses_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class BodegaScreen extends StatefulWidget {
  const BodegaScreen({super.key});

  @override
  State<BodegaScreen> createState() => _BodegaScreenState();
}

class _BodegaScreenState extends State<BodegaScreen> {
  int _currentNavIndex = 0;

  List<Account> _accounts = [];
  List<TransactionRecord> _transactions = [];
  Map<String, CategoryModel> _categoryMap = {};
  BudgetModel? _currentBudget;
  double _monthlySpent = 0.0;
  Map<String, dynamic> _kittyProfile = {};
  List<DailySpend> _dailySpends = [];
  List<CategoryBreakdown> _categoryBreakdown = [];

  String _currency = '\$';
  String? _filterAccountId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    DatabaseService.instance.changeNotifier.addListener(_loadAllData);
  }

  @override
  void dispose() {
    DatabaseService.instance.changeNotifier.removeListener(_loadAllData);
    super.dispose();
  }

  Future<void> _loadAllData() async {
    final now = DateTime.now();
    final accounts = await DatabaseService.instance.getAccounts();
    final categories = await DatabaseService.instance.getCategories();
    final transactions = await DatabaseService.instance.getTransactions(
      accountId: _filterAccountId,
      limit: 60,
    );
    final budget = await DatabaseService.instance.getCurrentBudget();
    final spent = await DatabaseService.instance.getMonthlySpentTotal(now.month, now.year);
    final kitty = await DatabaseService.instance.getKittyProfile();
    final daily = await DatabaseService.instance.getDailySpendingLast7Days();
    final breakdown = await DatabaseService.instance.getCategorySpendingBreakdown(now.month, now.year);
    final curr = await DatabaseService.instance.getCurrency();

    if (mounted) {
      setState(() {
        _accounts = accounts;
        _categoryMap = {for (var c in categories) c.id: c};
        _transactions = transactions;
        _currentBudget = budget;
        _monthlySpent = spent;
        _kittyProfile = kitty;
        _dailySpends = daily;
        _categoryBreakdown = breakdown;
        _currency = curr;
        _isLoading = false;
      });
    }
  }

  double get _totalNetWorth {
    return _accounts.fold(0.0, (sum, acc) => sum + acc.balance);
  }

  void _openAddTransaction([String initialType = 'expense']) {
    if (_accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crea primero una cuenta para registrar movimientos')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => AddTransactionSheet(
        accounts: _accounts,
        preselectedAccountId: _filterAccountId,
        initialType: initialType,
        currency: _currency,
      ),
    );
  }

  void _openAddAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AddAccountDialog(currency: _currency),
    );
  }

  void _openManageCategories() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const CategoriesSheet(type: 'expense'),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: KwallTheme.accent),
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildBodegaTab(),
          PlannedExpensesScreen(currency: _currency),
          SettingsScreen(
            currentCurrency: _currency,
            onCurrencyChanged: (c) => setState(() => _currency = c),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentNavIndex,
        onDestinationSelected: (index) => setState(() => _currentNavIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_rounded),
            selectedIcon: Icon(Icons.book_rounded, color: KwallTheme.accent),
            label: 'Bodega',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_rounded),
            selectedIcon: Icon(Icons.calendar_today_rounded, color: KwallTheme.accent),
            label: 'Planificados',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            selectedIcon: Icon(Icons.tune_rounded, color: KwallTheme.accent),
            label: 'Ajustes & Gato',
          ),
        ],
      ),
    );
  }

  Widget _buildBodegaTab() {
    final kittyName = (_kittyProfile['name'] as String?) ?? 'Mishi';
    final coatColor = (_kittyProfile['coat_color'] as String?) ?? 'orange';
    final kittyHappiness = (_kittyProfile['happiness'] as int?) ?? 85;

    return RefreshIndicator(
      onRefresh: _loadAllData,
      color: KwallTheme.accent,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: KwallTheme.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pets_rounded, size: 16, color: KwallTheme.accent),
                ),
                const SizedBox(width: 10),
                Text('kwall', style: KwallTheme.fontTitle.copyWith(fontSize: 20)),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Gestionar Categorías',
                onPressed: _openManageCategories,
                icon: const Icon(Icons.category_rounded, color: KwallTheme.textSecondary),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ================= TOP HERO CARD (Cute Kitty + Balance) =================
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: KwallTheme.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: KwallTheme.border),
                    ),
                    child: Row(
                      children: [
                        // Cute, Normalito Chibi Kitty (Configurable, NO EMOJIS)
                        KittyCompanionWidget(
                          size: 100,
                          coatColor: coatColor,
                          name: kittyName,
                          onPet: () async {
                            await DatabaseService.instance.updateKittyMood('happy', happinessDelta: 5);
                          },
                        ),
                        const SizedBox(width: 18),

                        // Balance Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    kittyName,
                                    style: KwallTheme.fontTitle.copyWith(
                                      fontSize: 14,
                                      color: KwallTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: KwallTheme.accent.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '♥ $kittyHappiness%',
                                      style: TextStyle(
                                        color: KwallTheme.accent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Saldo Total',
                                style: KwallTheme.fontBody.copyWith(
                                  fontSize: 11,
                                  color: KwallTheme.textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                KwallTheme.formatCurrency(_totalNetWorth, _currency),
                                style: KwallTheme.fontDisplay.copyWith(
                                  fontSize: 28,
                                  color: _totalNetWorth >= 0 ? KwallTheme.textPrimary : KwallTheme.expenseRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ================= BUDGET PROGRESS BAR =================
                  ExpressiveBudgetBar(
                    spent: _monthlySpent,
                    budget: _currentBudget?.monthlyLimit ?? 1200.0,
                    currency: _currency,
                  ),
                  const SizedBox(height: 16),

                  // ================= QUICK EXPRESSIVE ACTION BUTTONS =================
                  Row(
                    children: [
                      Expanded(
                        child: ExpressiveButton(
                          onPressed: () => _openAddTransaction('expense'),
                          color: KwallTheme.expenseRed.withValues(alpha: 0.18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_upward_rounded, size: 16, color: KwallTheme.expenseRed),
                              const SizedBox(width: 6),
                              Text(
                                'Gasto',
                                style: KwallTheme.fontTitle.copyWith(
                                  color: KwallTheme.expenseRed,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ExpressiveButton(
                          onPressed: () => _openAddTransaction('income'),
                          color: KwallTheme.incomeGreen.withValues(alpha: 0.18),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.arrow_downward_rounded, size: 16, color: KwallTheme.incomeGreen),
                              const SizedBox(width: 6),
                              Text(
                                'Ingreso',
                                style: KwallTheme.fontTitle.copyWith(
                                  color: KwallTheme.incomeGreen,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ExpressiveButton(
                        onPressed: () => _openAddTransaction('transfer'),
                        color: KwallTheme.surfaceContainer,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        child: const Icon(Icons.sync_alt_rounded, size: 18, color: KwallTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ================= DAILY SPENDING & CHARTS =================
                  SpendingChartWidget(
                    dailySpends: _dailySpends,
                    categoryBreakdowns: _categoryBreakdown,
                    currency: _currency,
                  ),
                  const SizedBox(height: 20),

                  // ================= ACCOUNTS / BÓVEDAS =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Cuentas',
                            style: KwallTheme.fontTitle.copyWith(fontSize: 15, color: KwallTheme.textPrimary),
                          ),
                          if (_filterAccountId != null) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() => _filterAccountId = null);
                                _loadAllData();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: KwallTheme.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Ver todas ×',
                                  style: TextStyle(color: KwallTheme.accent, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _openAddAccount,
                        icon: const Icon(Icons.add_rounded, size: 16, color: KwallTheme.accent),
                        label: Text('Nueva cuenta', style: TextStyle(color: KwallTheme.accent, fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  SizedBox(
                    height: 82,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _accounts.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final acc = _accounts[i];
                        final isSelected = _filterAccountId == acc.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _filterAccountId = isSelected ? null : acc.id);
                            _loadAllData();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 160,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? KwallTheme.accent.withValues(alpha: 0.12)
                                  : KwallTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? KwallTheme.accent : KwallTheme.border,
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        acc.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isSelected ? KwallTheme.accent : KwallTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Color(acc.colorValue),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  KwallTheme.formatCurrency(acc.balance, _currency),
                                  style: KwallTheme.fontTitle.copyWith(
                                    fontSize: 16,
                                    color: acc.balance >= 0 ? KwallTheme.textPrimary : KwallTheme.expenseRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ================= EL CUADERNO (Transactions List) =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _filterAccountId != null ? 'Movimientos filtrados' : 'Cuaderno diario',
                        style: KwallTheme.fontTitle.copyWith(fontSize: 15, color: KwallTheme.textPrimary),
                      ),
                      Text(
                        '${_transactions.length} registros',
                        style: KwallTheme.fontBody.copyWith(color: KwallTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (_transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                      decoration: BoxDecoration(
                        color: KwallTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: KwallTheme.border),
                      ),
                      child: Center(
                        child: Text(
                          'El cuaderno está vacío para esta selección.\nToca + Gasto para registrar el primero.',
                          textAlign: TextAlign.center,
                          style: KwallTheme.fontBody.copyWith(color: KwallTheme.textMuted, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _transactions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final tx = _transactions[index];
                        final cat = _categoryMap[tx.categoryId] ??
                            CategoryModel(
                              id: tx.categoryId,
                              name: 'General',
                              type: tx.type,
                              iconKey: 'tag',
                              colorValue: 0xFF10B981,
                            );

                        final isExpense = tx.isExpense;
                        final isIncome = tx.isIncome;
                        final color = isExpense
                            ? KwallTheme.expenseRed
                            : (isIncome ? KwallTheme.incomeGreen : KwallTheme.infoBlue);
                        final prefix = isExpense ? '-' : (isIncome ? '+' : '⇄ ');

                        return Dismissible(
                          key: Key(tx.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: KwallTheme.expenseRed,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                          ),
                          onDismissed: (_) async {
                            await DatabaseService.instance.deleteTransaction(tx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Movimiento eliminado y saldo restaurado'),
                                  backgroundColor: KwallTheme.surfaceElevated,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: KwallTheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: KwallTheme.border),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(cat.colorValue).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(cat.iconData, size: 20, color: Color(cat.colorValue)),
                                ),
                                const SizedBox(width: 14),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.note.isNotEmpty ? tx.note : cat.name,
                                        style: KwallTheme.fontTitle.copyWith(
                                          fontSize: 14,
                                          color: KwallTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${cat.name} • ${_formatDate(tx.date)}',
                                        style: KwallTheme.fontBody.copyWith(
                                          fontSize: 11,
                                          color: KwallTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Text(
                                  '$prefix${KwallTheme.formatCurrency(tx.amount, _currency)}',
                                  style: KwallTheme.fontTitle.copyWith(
                                    fontSize: 15,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(date, now)) {
      return 'Hoy ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
