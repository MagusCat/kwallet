import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/game_hud_widgets.dart';
import '../models/account.dart';
import '../models/category_model.dart';
import '../models/transaction_record.dart';
import 'categories_sheet.dart';

class AddTransactionSheet extends StatefulWidget {
  final List<Account> accounts;
  final String? preselectedAccountId;
  final String initialType; // 'expense', 'income', 'transfer'
  final String currency;

  const AddTransactionSheet({
    super.key,
    required this.accounts,
    this.preselectedAccountId,
    this.initialType = 'expense',
    this.currency = '\$',
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late String _type; // 'expense', 'income', 'transfer'
  late String _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _selectedAccountId = widget.preselectedAccountId ??
        (widget.accounts.isNotEmpty ? widget.accounts.first.id : '');
    if (widget.accounts.length > 1) {
      _selectedToAccountId = widget.accounts[1].id;
    }
    _loadCategories();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final catType = _type == 'income' ? 'income' : 'expense';
    final cats = await DatabaseService.instance.getCategories(type: catType);
    if (mounted) {
      setState(() {
        _categories = cats;
        if (cats.isNotEmpty && (_selectedCategoryId == null || !cats.any((c) => c.id == _selectedCategoryId))) {
          _selectedCategoryId = cats.first.id;
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    final amountText = _amountController.text.trim().replaceAll(',', '.');
    final parsedAmount = double.tryParse(amountText) ?? 0.0;

    if (parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto válido mayor a 0'),
          backgroundColor: KwallTheme.expenseRed,
        ),
      );
      return;
    }

    if (_type == 'transfer' && _selectedAccountId == _selectedToAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cuenta de origen y destino deben ser distintas'),
          backgroundColor: KwallTheme.expenseRed,
        ),
      );
      return;
    }

    final newTx = TransactionRecord(
      id: const Uuid().v4(),
      accountId: _selectedAccountId,
      toAccountId: _type == 'transfer' ? _selectedToAccountId : null,
      categoryId: _selectedCategoryId ?? 'cat_food',
      amount: parsedAmount,
      type: _type,
      note: _noteController.text.trim(),
      date: _selectedDate,
      createdAt: DateTime.now(),
    );

    await DatabaseService.instance.addTransaction(newTx);

    // Update Kitty mood gently
    if (_type == 'income') {
      await DatabaseService.instance.updateKittyMood('happy', expDelta: 15, happinessDelta: 10);
    } else {
      await DatabaseService.instance.updateKittyMood('happy', expDelta: 5);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _openManageCategories() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => CategoriesSheet(type: _type == 'income' ? 'income' : 'expense'),
    );
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    Color typeColor = _type == 'expense'
        ? KwallTheme.expenseRed
        : (_type == 'income' ? KwallTheme.incomeGreen : KwallTheme.infoBlue);

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
            // Handle bar
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

            // Expressive Segmented Type Selector
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: KwallTheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildTypeTab('expense', 'Gasto', KwallTheme.expenseRed),
                  _buildTypeTab('income', 'Ingreso', KwallTheme.incomeGreen),
                  _buildTypeTab('transfer', 'Transferir', KwallTheme.infoBlue),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Large Clean Amount Field
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: KwallTheme.fontDisplay.copyWith(
                fontSize: 40,
                color: typeColor,
              ),
              decoration: InputDecoration(
                hintText: '${widget.currency} 0.00',
                hintStyle: TextStyle(
                  color: KwallTheme.textMuted.withValues(alpha: 0.5),
                  fontSize: 40,
                ),
                prefixText: '${widget.currency} ',
                prefixStyle: TextStyle(
                  color: typeColor,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                filled: true,
                fillColor: KwallTheme.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Concept / Note Input
            TextField(
              controller: _noteController,
              style: const TextStyle(color: KwallTheme.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Concepto o nota (ej. Compra semanal, Café...)',
                hintStyle: const TextStyle(color: KwallTheme.textMuted, fontSize: 13),
                prefixIcon: const Icon(Icons.edit_note_rounded, color: KwallTheme.textSecondary),
                filled: true,
                fillColor: KwallTheme.surfaceContainer,
              ),
            ),
            const SizedBox(height: 16),

            // Account selection
            Text(
              _type == 'transfer' ? 'CUENTA ORIGEN' : 'CUENTA / BÓVEDA',
              style: KwallTheme.fontBody.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: KwallTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.accounts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final acc = widget.accounts[i];
                  final isSelected = acc.id == _selectedAccountId;
                  return ChoiceChip(
                    label: Text('${acc.name} (${KwallTheme.formatCurrency(acc.balance, widget.currency)})'),
                    selected: isSelected,
                    selectedColor: KwallTheme.accent.withValues(alpha: 0.2),
                    backgroundColor: KwallTheme.surfaceContainer,
                    side: BorderSide(
                      color: isSelected ? KwallTheme.accent : KwallTheme.border,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? KwallTheme.accent : KwallTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) => setState(() => _selectedAccountId = acc.id),
                  );
                },
              ),
            ),

            if (_type == 'transfer') ...[
              const SizedBox(height: 12),
              Text(
                'CUENTA DESTINO',
                style: KwallTheme.fontBody.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: KwallTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final acc = widget.accounts[i];
                    final isSelected = acc.id == _selectedToAccountId;
                    return ChoiceChip(
                      label: Text('${acc.name} (${KwallTheme.formatCurrency(acc.balance, widget.currency)})'),
                      selected: isSelected,
                      selectedColor: KwallTheme.infoBlue.withValues(alpha: 0.2),
                      backgroundColor: KwallTheme.surfaceContainer,
                      side: BorderSide(
                        color: isSelected ? KwallTheme.infoBlue : KwallTheme.border,
                      ),
                      labelStyle: TextStyle(
                        color: isSelected ? KwallTheme.infoBlue : KwallTheme.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedToAccountId = acc.id),
                    );
                  },
                ),
              ),
            ],

            // Categories (if not transfer)
            if (_type != 'transfer') ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CATEGORÍA',
                    style: KwallTheme.fontBody.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: KwallTheme.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: _openManageCategories,
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline_rounded, size: 14, color: KwallTheme.accent),
                        const SizedBox(width: 4),
                        Text(
                          'Añadir propia',
                          style: KwallTheme.fontBody.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: KwallTheme.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const LinearProgressIndicator()
              else
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      if (i == _categories.length) {
                        return ActionChip(
                          avatar: const Icon(Icons.add, size: 16, color: KwallTheme.accent),
                          label: const Text('Nueva...'),
                          backgroundColor: KwallTheme.surfaceContainer,
                          side: const BorderSide(color: KwallTheme.border),
                          labelStyle: const TextStyle(color: KwallTheme.accent, fontSize: 12),
                          onPressed: _openManageCategories,
                        );
                      }
                      final cat = _categories[i];
                      final isSelected = cat.id == _selectedCategoryId;
                      return ChoiceChip(
                        avatar: Icon(cat.iconData, size: 16, color: Color(cat.colorValue)),
                        label: Text(cat.name),
                        selected: isSelected,
                        selectedColor: Color(cat.colorValue).withValues(alpha: 0.25),
                        backgroundColor: KwallTheme.surfaceContainer,
                        side: BorderSide(
                          color: isSelected ? Color(cat.colorValue) : KwallTheme.border,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : KwallTheme.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (_) => setState(() => _selectedCategoryId = cat.id),
                      );
                    },
                  ),
                ),
            ],

            const SizedBox(height: 16),

            // Date selector
            Row(
              children: [
                ActionChip(
                  avatar: const Icon(Icons.calendar_today_rounded, size: 14, color: KwallTheme.textSecondary),
                  label: Text(_formatDateLabel(_selectedDate)),
                  backgroundColor: KwallTheme.surfaceContainer,
                  side: const BorderSide(color: KwallTheme.border),
                  labelStyle: const TextStyle(color: KwallTheme.textPrimary, fontSize: 12),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
                const SizedBox(width: 8),
                if (!DateUtils.isSameDay(_selectedDate, DateTime.now()))
                  TextButton(
                    onPressed: () => setState(() => _selectedDate = DateTime.now()),
                    child: const Text('Volver a Hoy', style: TextStyle(color: KwallTheme.accent, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Save Button
            ExpressiveButton(
              onPressed: _submit,
              color: typeColor,
              child: Center(
                child: Text(
                  'Guardar ${_type == 'expense' ? 'Gasto' : (_type == 'income' ? 'Ingreso' : 'Transferencia')}',
                  style: KwallTheme.fontTitle.copyWith(
                    color: Colors.black,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(String type, String label, Color activeColor) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _type = type;
            _isLoading = true;
          });
          _loadCategories();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: KwallTheme.fontBody.copyWith(
                color: isSelected ? Colors.black : KwallTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDateLabel(DateTime date) {
    final now = DateTime.now();
    if (DateUtils.isSameDay(date, now)) return 'Hoy';
    if (DateUtils.isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Ayer';
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
