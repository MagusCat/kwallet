import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/game_hud_widgets.dart';
import '../models/account.dart';
import '../models/category_model.dart';
import '../models/planned_expense.dart';

class PlannedExpensesScreen extends StatefulWidget {
  final String currency;

  const PlannedExpensesScreen({super.key, this.currency = '\$'});

  @override
  State<PlannedExpensesScreen> createState() => _PlannedExpensesScreenState();
}

class _PlannedExpensesScreenState extends State<PlannedExpensesScreen> {
  List<PlannedExpense> _expenses = [];
  Map<String, CategoryModel> _categoryMap = {};
  List<Account> _accounts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    DatabaseService.instance.changeNotifier.addListener(_loadData);
  }

  @override
  void dispose() {
    DatabaseService.instance.changeNotifier.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final expenses = await DatabaseService.instance.getPlannedExpenses();
    final categories = await DatabaseService.instance.getCategories();
    final accounts = await DatabaseService.instance.getAccounts();

    if (mounted) {
      setState(() {
        _expenses = expenses;
        _categoryMap = {for (var c in categories) c.id: c};
        _accounts = accounts;
        _isLoading = false;
      });
    }
  }

  void _openAddPlannedExpense() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AddPlannedExpenseSheet(
        categories: _categoryMap.values.toList(),
        accounts: _accounts,
        currency: widget.currency,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: KwallTheme.accent));
    }

    final pending = _expenses.where((e) => !e.isCompleted).toList();
    final completed = _expenses.where((e) => e.isCompleted).toList();
    final totalPlannedMonthly = pending.fold<double>(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gastos Planificados',
          style: KwallTheme.fontTitle.copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: _openAddPlannedExpense,
            icon: const Icon(Icons.add_circle_outline_rounded, color: KwallTheme.accent),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KwallTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: KwallTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: KwallTheme.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.calendar_month_rounded, color: KwallTheme.accent),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compromisos Pendientes',
                          style: KwallTheme.fontBody.copyWith(
                            fontSize: 12,
                            color: KwallTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          KwallTheme.formatCurrency(totalPlannedMonthly, widget.currency),
                          style: KwallTheme.fontDisplay.copyWith(
                            fontSize: 24,
                            color: KwallTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pending list
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Próximos vencimientos (${pending.length})',
                  style: KwallTheme.fontTitle.copyWith(
                    fontSize: 14,
                    color: KwallTheme.textSecondary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _openAddPlannedExpense,
                  icon: const Icon(Icons.add_rounded, size: 16, color: KwallTheme.accent),
                  label: Text('Planificar', style: KwallTheme.fontBody.copyWith(color: KwallTheme.accent, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (pending.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: KwallTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: KwallTheme.border),
                ),
                child: Center(
                  child: Text(
                    'No tienes compromisos planificados pendientes.',
                    style: KwallTheme.fontBody.copyWith(color: KwallTheme.textMuted, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pending.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final item = pending[i];
                  return _buildPlannedItem(item);
                },
              ),

            // Completed Section
            if (completed.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Completados / Pagados (${completed.length})',
                style: KwallTheme.fontTitle.copyWith(
                  fontSize: 14,
                  color: KwallTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: completed.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final item = completed[i];
                  return _buildPlannedItem(item);
                },
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPlannedItem(PlannedExpense item) {
    final cat = _categoryMap[item.categoryId] ??
        CategoryModel(id: item.categoryId, name: 'Varios', type: 'expense', iconKey: 'tag', colorValue: 0xFF64748B);

    final days = item.daysRemaining;
    String badgeText;
    Color badgeColor;
    if (item.isCompleted) {
      badgeText = 'Pagado';
      badgeColor = KwallTheme.accent;
    } else if (days < 0) {
      badgeText = 'Atrasado ${-days}d';
      badgeColor = KwallTheme.expenseRed;
    } else if (days == 0) {
      badgeText = 'Vence hoy';
      badgeColor = KwallTheme.warningAmber;
    } else {
      badgeText = 'En $days días';
      badgeColor = KwallTheme.infoBlue;
    }

    return Dismissible(
      key: Key(item.id),
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
        await DatabaseService.instance.deletePlannedExpense(item.id);
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
            Checkbox(
              value: item.isCompleted,
              activeColor: KwallTheme.accent,
              checkColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              onChanged: (val) async {
                await DatabaseService.instance.togglePlannedExpenseCompleted(item.id, val ?? false);
              },
            ),
            const SizedBox(width: 4),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(cat.colorValue).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(cat.iconData, size: 16, color: Color(cat.colorValue)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: KwallTheme.fontTitle.copyWith(
                      fontSize: 14,
                      color: item.isCompleted ? KwallTheme.textMuted : KwallTheme.textPrimary,
                      decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.recurrenceLabel} • ${DateFormat('dd MMM').format(item.dueDate)}',
                        style: const TextStyle(color: KwallTheme.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              KwallTheme.formatCurrency(item.amount, widget.currency),
              style: KwallTheme.fontTitle.copyWith(
                fontSize: 15,
                color: item.isCompleted ? KwallTheme.textMuted : KwallTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPlannedExpenseSheet extends StatefulWidget {
  final List<CategoryModel> categories;
  final List<Account> accounts;
  final String currency;

  const _AddPlannedExpenseSheet({
    required this.categories,
    required this.accounts,
    this.currency = '\$',
  });

  @override
  State<_AddPlannedExpenseSheet> createState() => _AddPlannedExpenseSheetState();
}

class _AddPlannedExpenseSheetState extends State<_AddPlannedExpenseSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  String _recurrence = 'monthly';
  String? _selectedCategoryId;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _selectedCategoryId = widget.categories.first.id;
    }
    if (widget.accounts.isNotEmpty) {
      _selectedAccountId = widget.accounts.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (title.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un título y monto válido')),
      );
      return;
    }

    final newExpense = PlannedExpense(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      dueDate: _dueDate,
      recurrence: _recurrence,
      categoryId: _selectedCategoryId ?? 'cat_bills',
      accountId: _selectedAccountId,
      note: _noteController.text.trim(),
      createdAt: DateTime.now(),
    );

    await DatabaseService.instance.addPlannedExpense(newExpense);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KwallTheme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Nuevo Gasto Planificado', style: KwallTheme.fontTitle.copyWith(fontSize: 18)),
            const SizedBox(height: 14),

            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'Título (ej. Alquiler, Spotify, Seguro...)'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Monto estimado',
                prefixText: '${widget.currency} ',
              ),
            ),
            const SizedBox(height: 14),

            // Recurrence Chips
            Text('Frecuencia', style: KwallTheme.fontBody.copyWith(fontSize: 12, color: KwallTheme.textSecondary)),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildRecurrenceChip('monthly', 'Mensual'),
                const SizedBox(width: 8),
                _buildRecurrenceChip('yearly', 'Anual'),
                const SizedBox(width: 8),
                _buildRecurrenceChip('one_time', 'Único'),
              ],
            ),
            const SizedBox(height: 14),

            // Date picker
            Row(
              children: [
                Text('Fecha de vencimiento: ', style: KwallTheme.fontBody.copyWith(fontSize: 12, color: KwallTheme.textSecondary)),
                ActionChip(
                  label: Text(DateFormat('dd/MM/yyyy').format(_dueDate)),
                  backgroundColor: KwallTheme.surfaceContainer,
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setState(() => _dueDate = picked);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            ExpressiveButton(
              onPressed: _submit,
              child: Center(
                child: Text(
                  'Guardar Compromiso',
                  style: KwallTheme.fontTitle.copyWith(color: Colors.black, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceChip(String key, String label) {
    final isSelected = _recurrence == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: KwallTheme.accent.withValues(alpha: 0.2),
      backgroundColor: KwallTheme.surfaceContainer,
      side: BorderSide(color: isSelected ? KwallTheme.accent : KwallTheme.border),
      labelStyle: TextStyle(
        color: isSelected ? KwallTheme.accent : KwallTheme.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => setState(() => _recurrence = key),
    );
  }
}
