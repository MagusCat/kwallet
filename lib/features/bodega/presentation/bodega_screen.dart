import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/database/database_service.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/game_hud_widgets.dart';
import '../../../core/widgets/kitty_companion.dart';
import '../models/account.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/transaction_record.dart';
import 'add_account_dialog.dart';
import 'add_transaction_dialog.dart';
import 'budget_dialog.dart';

class BodegaScreen extends StatefulWidget {
  const BodegaScreen({super.key});

  @override
  State<BodegaScreen> createState() => _BodegaScreenState();
}

class _BodegaScreenState extends State<BodegaScreen> {
  List<Account> _accounts = [];
  List<TransactionRecord> _transactions = [];
  Map<String, CategoryModel> _categoryMap = {};
  BudgetModel? _currentBudget;
  double _monthlySpent = 0.0;
  Map<String, dynamic> _kittyProfile = {};

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

    if (mounted) {
      setState(() {
        _accounts = accounts;
        _categoryMap = {for (var c in categories) c.id: c};
        _transactions = transactions;
        _currentBudget = budget;
        _monthlySpent = spent;
        _kittyProfile = kitty;
        _isLoading = false;
      });
    }
  }

  double get _totalNetWorth {
    return _accounts.fold(0.0, (sum, acc) => sum + acc.balance);
  }

  KittyMoodState _deriveKittyMood() {
    final budget = _currentBudget?.monthlyLimit ?? 1000.0;
    if (_monthlySpent >= budget * 0.85) {
      return KittyMoodState.alert; // Stressed about expenses!
    }
    if (_totalNetWorth > 3000.0) {
      return KittyMoodState.boss; // Rich cat shades!
    }
    final dbMood = _kittyProfile['mood'] as String?;
    if (dbMood == 'happy') return KittyMoodState.happy;
    if (dbMood == 'sleepy') return KittyMoodState.sleepy;
    return KittyMoodState.zen;
  }

  void _openAddTransaction([String initialType = 'expense']) {
    if (_accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crea primero una bóveda para registrar movimientos')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        accounts: _accounts,
        preselectedAccountId: _filterAccountId,
        initialType: initialType,
      ),
    );
  }

  void _openAddAccount() {
    showDialog(
      context: context,
      builder: (context) => const AddAccountDialog(),
    );
  }

  void _openBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => BudgetDialog(
        currentBudget: _currentBudget?.monthlyLimit ?? 1000.0,
        currentSpent: _monthlySpent,
      ),
    );
  }

  void _showBackupSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: KwallTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: KwallTheme.borderBright, width: 1.5),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_rounded, color: KwallTheme.neonGreen),
                  const SizedBox(width: 10),
                  Text(
                    'RESILIENCIA OFFLINE & COPIAS DE SEGURIDAD',
                    style: KwallTheme.hudHeaderFont.copyWith(
                      color: KwallTheme.textBright,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Tus datos residen 100% en tu SQLite local. Puedes exportar un archivo JSON transparente para archivarlo o moverlo a otro dispositivo.',
                style: TextStyle(color: KwallTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              HudButton(
                onPressed: () async {
                  final jsonStr = await DatabaseService.instance.exportFullDataAsJson();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: KwallTheme.surfaceCard,
                        title: Text('Copia de Seguridad JSON', style: KwallTheme.hudHeaderFont),
                        content: SizedBox(
                          width: 500,
                          height: 300,
                          child: SelectableText(
                            jsonStr,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('CERRAR', style: TextStyle(color: KwallTheme.neonGreen)),
                          ),
                        ],
                      ),
                    );
                  }
                },
                color: KwallTheme.cyberGold,
                child: const Center(
                  child: Text(
                    'EXPORTAR JSON DE SEGURIDAD',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: KwallTheme.neonGreen),
        ),
      );
    }

    final kittyMood = _deriveKittyMood();
    final kittyLvl = (_kittyProfile['level'] as int?) ?? 1;
    final kittyExp = (_kittyProfile['exp'] as int?) ?? 0;
    final kittyHappiness = (_kittyProfile['happiness'] as int?) ?? 80;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: KwallTheme.neonGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: KwallTheme.neonGreen, width: 1),
              ),
              child: Text(
                'KWALL',
                style: KwallTheme.gameFont.copyWith(
                  color: KwallTheme.neonGreen,
                  fontSize: 16,
                  letterSpacing: 2.0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'BODEGA & GATOS',
              style: KwallTheme.hudHeaderFont.copyWith(fontSize: 14),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ajustar Escudo / Presupuesto',
            onPressed: _openBudgetDialog,
            icon: const Icon(Icons.tune_rounded, color: KwallTheme.textBright),
          ),
          IconButton(
            tooltip: 'Copias de Seguridad Offline',
            onPressed: _showBackupSheet,
            icon: const Icon(Icons.save_rounded, color: KwallTheme.cyberGold),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        color: KwallTheme.neonGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ================= GAME HUD HEADER (Kitty + Net Worth) =================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KwallTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: KwallTheme.borderBright, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    // Interactive Kitty Companion (NO EMOJIS!)
                    KittyCompanionWidget(
                      size: 110,
                      mood: kittyMood,
                      onPet: () async {
                        await DatabaseService.instance.updateKittyMood(
                          'happy',
                          happinessDelta: 5,
                          expDelta: 5,
                        );
                      },
                    ),
                    const SizedBox(width: 16),

                    // Net Worth & Kitty Stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PATRIMONIO TOTAL',
                            style: KwallTheme.hudHeaderFont.copyWith(
                              color: KwallTheme.textMuted,
                              fontSize: 10,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            KwallTheme.formatCurrency(_totalNetWorth),
                            style: KwallTheme.gameFont.copyWith(
                              color: _totalNetWorth >= 0
                                  ? KwallTheme.neonGreen
                                  : KwallTheme.plasmaPink,
                              fontSize: 32,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Kitty Stat Pips
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              GamerStatPip(
                                label: 'LVL',
                                value: '$kittyLvl',
                                color: KwallTheme.cyberGold,
                                icon: Icons.star_rounded,
                              ),
                              GamerStatPip(
                                label: 'EXP',
                                value: '$kittyExp%',
                                color: KwallTheme.electricCyan,
                                icon: Icons.bolt_rounded,
                              ),
                              GamerStatPip(
                                label: 'ÁNIMO',
                                value: '$kittyHappiness%',
                                color: KwallTheme.plasmaPink,
                                icon: Icons.favorite_rounded,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0.0),

              const SizedBox(height: 14),

              // ================= VISUAL BUDGET HEALTH BAR =================
              GestureDetector(
                onTap: _openBudgetDialog,
                child: HudHealthBar(
                  spent: _monthlySpent,
                  budget: _currentBudget?.monthlyLimit ?? 1000.0,
                  label: 'ESCUDO MENSUAL (TOCA PARA CALIBRAR)',
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

              const SizedBox(height: 18),

              // ================= BÓVEDAS (Accounts Row) =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'BÓVEDAS & CUENTAS',
                        style: KwallTheme.hudHeaderFont.copyWith(
                          color: KwallTheme.textBright,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_filterAccountId != null)
                        GestureDetector(
                          onTap: () {
                            setState(() => _filterAccountId = null);
                            _loadAllData();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: KwallTheme.plasmaPink.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'VER TODAS [X]',
                              style: KwallTheme.gameFont.copyWith(
                                color: KwallTheme.plasmaPink,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _openAddAccount,
                    icon: const Icon(Icons.add_rounded, size: 16, color: KwallTheme.neonGreen),
                    label: Text(
                      'NUEVA BÓVEDA',
                      style: KwallTheme.hudHeaderFont.copyWith(
                        color: KwallTheme.neonGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, i) {
                    final acc = _accounts[i];
                    final isFiltered = _filterAccountId == acc.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _filterAccountId = isFiltered ? null : acc.id;
                        });
                        _loadAllData();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 170,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isFiltered
                              ? Color(acc.colorValue).withValues(alpha: 0.16)
                              : KwallTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFiltered
                                ? Color(acc.colorValue)
                                : KwallTheme.border,
                            width: isFiltered ? 2 : 1.5,
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
                                      color: isFiltered
                                          ? Color(acc.colorValue)
                                          : KwallTheme.textBright,
                                      fontWeight: FontWeight.bold,
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
                              KwallTheme.formatCurrency(acc.balance, acc.currency),
                              style: KwallTheme.gameFont.copyWith(
                                color: acc.balance >= 0
                                    ? Color(acc.colorValue)
                                    : KwallTheme.plasmaPink,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              // ================= QUICK TACTILE ACTION BUTTONS =================
              Row(
                children: [
                  Expanded(
                    child: HudButton(
                      onPressed: () => _openAddTransaction('expense'),
                      color: KwallTheme.plasmaPink,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.remove_circle_outline_rounded, size: 16, color: Colors.black),
                          const SizedBox(width: 6),
                          Text(
                            'GASTO',
                            style: KwallTheme.hudHeaderFont.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: HudButton(
                      onPressed: () => _openAddTransaction('income'),
                      color: KwallTheme.neonGreen,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_circle_outline_rounded, size: 16, color: Colors.black),
                          const SizedBox(width: 6),
                          Text(
                            'INGRESO',
                            style: KwallTheme.hudHeaderFont.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  HudButton(
                    onPressed: () => _openAddTransaction('transfer'),
                    color: KwallTheme.electricCyan,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: const Icon(Icons.sync_alt_rounded, size: 18, color: Colors.black),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ================= EL CUADERNO (Transactions Ledger) =================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _filterAccountId != null
                        ? 'MOVIMIENTOS DE LA BÓVEDA'
                        : 'EL CUADERNO (GASTOS DIARIOS)',
                    style: KwallTheme.hudHeaderFont.copyWith(
                      color: KwallTheme.textBright,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${_transactions.length} REGISTROS',
                    style: KwallTheme.gameFont.copyWith(
                      color: KwallTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  decoration: BoxDecoration(
                    color: KwallTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: KwallTheme.border),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.auto_stories_rounded, size: 36, color: KwallTheme.textMuted),
                        const SizedBox(height: 10),
                        Text(
                          'El cuaderno está en blanco',
                          style: KwallTheme.hudHeaderFont.copyWith(
                            color: KwallTheme.textBright,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Registra tu primer gasto con el botón superior para alimentar las estadísticas del Kitty.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: KwallTheme.textMuted, fontSize: 11),
                        ),
                      ],
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
                          colorValue: 0xFF00FF9D,
                        );

                    final isExpense = tx.isExpense;
                    final isIncome = tx.isIncome;
                    final color = isExpense
                        ? KwallTheme.plasmaPink
                        : (isIncome ? KwallTheme.neonGreen : KwallTheme.electricCyan);

                    final prefix = isExpense ? '-' : (isIncome ? '+' : '⇄ ');

                    return Dismissible(
                      key: Key(tx.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: KwallTheme.plasmaPink,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
                      ),
                      onDismissed: (_) async {
                        await DatabaseService.instance.deleteTransaction(tx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Movimiento eliminado y saldo restaurado'),
                              backgroundColor: KwallTheme.surfaceCardHighlight,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: KwallTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: KwallTheme.border),
                        ),
                        child: Row(
                          children: [
                            // Category Icon Badge (NO EMOJIS!)
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Color(cat.colorValue).withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Color(cat.colorValue).withValues(alpha: 0.6),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                cat.iconData,
                                size: 19,
                                color: Color(cat.colorValue),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Note & Category name
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.note.isNotEmpty ? tx.note : cat.name,
                                    style: const TextStyle(
                                      color: KwallTheme.textBright,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${cat.name} • ${_formatDate(tx.date)}',
                                    style: const TextStyle(
                                      color: KwallTheme.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Amount Display
                            Text(
                              '$prefix${KwallTheme.formatCurrency(tx.amount)}',
                              style: KwallTheme.gameFont.copyWith(
                                color: color,
                                fontSize: 18,
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
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return 'Hoy $hour:$minute';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
