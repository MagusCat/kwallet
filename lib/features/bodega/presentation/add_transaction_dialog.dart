import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/game_hud_widgets.dart';
import '../models/account.dart';
import '../models/category_model.dart';
import '../models/transaction_record.dart';

class AddTransactionDialog extends StatefulWidget {
  final List<Account> accounts;
  final String? preselectedAccountId;
  final String initialType; // 'expense', 'income', 'transfer'

  const AddTransactionDialog({
    super.key,
    required this.accounts,
    this.preselectedAccountId,
    this.initialType = 'expense',
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  late String _type; // 'expense', 'income', 'transfer'
  late String _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;

  String _amountString = '0';
  final TextEditingController _noteController = TextEditingController();

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
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final catType = _type == 'income' ? 'income' : 'expense';
    final cats = await DatabaseService.instance.getCategories(type: catType);
    if (mounted) {
      setState(() {
        _categories = cats;
        if (cats.isNotEmpty) {
          _selectedCategoryId = cats.first.id;
        }
        _isLoading = false;
      });
    }
  }

  void _onNumpadPress(String key) {
    setState(() {
      if (key == 'C') {
        _amountString = '0';
      } else if (key == '⌫') {
        if (_amountString.length > 1) {
          _amountString = _amountString.substring(0, _amountString.length - 1);
        } else {
          _amountString = '0';
        }
      } else if (key == '.') {
        if (!_amountString.contains('.')) {
          _amountString += '.';
        }
      } else {
        if (_amountString == '0') {
          _amountString = key;
        } else {
          // Limit to 2 decimals
          if (_amountString.contains('.')) {
            final parts = _amountString.split('.');
            if (parts.length > 1 && parts[1].length >= 2) return;
          }
          if (_amountString.length < 9) {
            _amountString += key;
          }
        }
      }
    });
  }

  Future<void> _submitTransaction() async {
    final parsedAmount = double.tryParse(_amountString) ?? 0.0;
    if (parsedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto mayor a 0'),
          backgroundColor: KwallTheme.plasmaPink,
        ),
      );
      return;
    }

    if (_type == 'transfer' && _selectedAccountId == _selectedToAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cuenta de origen y destino deben ser distintas'),
          backgroundColor: KwallTheme.plasmaPink,
        ),
      );
      return;
    }

    final newTx = TransactionRecord(
      id: const Uuid().v4(),
      accountId: _selectedAccountId,
      toAccountId: _type == 'transfer' ? _selectedToAccountId : null,
      categoryId: _selectedCategoryId ?? 'cat_other',
      amount: parsedAmount,
      type: _type,
      note: _noteController.text.trim(),
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await DatabaseService.instance.addTransaction(newTx);

    // Update Kitty mood / stats based on action
    if (_type == 'income') {
      await DatabaseService.instance.updateKittyMood('happy', expDelta: 15, happinessDelta: 10);
    } else if (_type == 'expense' && parsedAmount > 200) {
      await DatabaseService.instance.updateKittyMood('alert', expDelta: 5);
    } else {
      await DatabaseService.instance.updateKittyMood('zen', expDelta: 5);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    String typeTitle;
    if (_type == 'expense') {
      typeColor = KwallTheme.plasmaPink;
      typeTitle = 'REGISTRAR GASTO';
    } else if (_type == 'income') {
      typeColor = KwallTheme.neonGreen;
      typeTitle = 'REGISTRAR INGRESO';
    } else {
      typeColor = KwallTheme.electricCyan;
      typeTitle = 'TRANSFERENCIA ENTRE BÓVEDAS';
    }

    return Dialog(
      backgroundColor: KwallTheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 700),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: typeColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      typeTitle,
                      style: KwallTheme.hudHeaderFont.copyWith(
                        color: KwallTheme.textBright,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: KwallTheme.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Type Segment Selector
            Container(
              decoration: BoxDecoration(
                color: KwallTheme.surfaceCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: KwallTheme.border),
              ),
              child: Row(
                children: [
                  _buildTypeTab('expense', 'GASTO', KwallTheme.plasmaPink),
                  _buildTypeTab('income', 'INGRESO', KwallTheme.neonGreen),
                  _buildTypeTab('transfer', 'TRANSFERIR', KwallTheme.electricCyan),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Amount Display HUD
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF090B10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: typeColor.withValues(alpha: 0.5), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MONTO:',
                    style: KwallTheme.hudHeaderFont.copyWith(
                      color: KwallTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '\$$_amountString',
                    style: KwallTheme.gameFont.copyWith(
                      color: typeColor,
                      fontSize: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Scrollable Options: Accounts & Categories & Notes
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Selector
                    Text(
                      _type == 'transfer' ? 'BÓVEDA ORIGEN' : 'BÓVEDA DE ORIGEN',
                      style: const TextStyle(
                        color: KwallTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: 38,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.accounts.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final acc = widget.accounts[i];
                          final isSelected = acc.id == _selectedAccountId;
                          return ChoiceChip(
                            label: Text(
                              '${acc.name} (${KwallTheme.formatCurrency(acc.balance)})',
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.black : KwallTheme.textBright,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: KwallTheme.neonGreen,
                            backgroundColor: KwallTheme.surfaceCardHighlight,
                            onSelected: (_) => setState(() => _selectedAccountId = acc.id),
                          );
                        },
                      ),
                    ),

                    if (_type == 'transfer') ...[
                      const SizedBox(height: 10),
                      const Text(
                        'BÓVEDA DESTINO',
                        style: TextStyle(
                          color: KwallTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: widget.accounts.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final acc = widget.accounts[i];
                            final isSelected = acc.id == _selectedToAccountId;
                            return ChoiceChip(
                              label: Text(
                                '${acc.name} (${KwallTheme.formatCurrency(acc.balance)})',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.black : KwallTheme.textBright,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: KwallTheme.electricCyan,
                              backgroundColor: KwallTheme.surfaceCardHighlight,
                              onSelected: (_) => setState(() => _selectedToAccountId = acc.id),
                            );
                          },
                        ),
                      ),
                    ],

                    // Categories (only if not transfer)
                    if (_type != 'transfer') ...[
                      const SizedBox(height: 12),
                      const Text(
                        'CATEGORÍA',
                        style: TextStyle(
                          color: KwallTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_isLoading)
                        const LinearProgressIndicator()
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _categories.map((cat) {
                            final isSelected = cat.id == _selectedCategoryId;
                            return FilterChip(
                              avatar: Icon(
                                cat.iconData,
                                size: 15,
                                color: isSelected ? Colors.black : Color(cat.colorValue),
                              ),
                              label: Text(
                                cat.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.black : KwallTheme.textBright,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: Color(cat.colorValue),
                              backgroundColor: KwallTheme.surfaceCardHighlight,
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.transparent
                                    : KwallTheme.borderBright,
                              ),
                              onSelected: (_) => setState(() => _selectedCategoryId = cat.id),
                            );
                          }).toList(),
                        ),
                    ],

                    const SizedBox(height: 12),
                    // Note / Gato diario
                    TextField(
                      controller: _noteController,
                      style: const TextStyle(color: KwallTheme.textBright, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Nota o detalle del gasto...',
                        hintStyle: const TextStyle(color: KwallTheme.textMuted, fontSize: 12),
                        filled: true,
                        fillColor: KwallTheme.surfaceCardHighlight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: KwallTheme.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: KwallTheme.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Quick Arcade Numpad for ultra-fast usability
                    _buildArcadeNumpad(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Submit Button
            HudButton(
              onPressed: _submitTransaction,
              color: typeColor,
              textColor: Colors.black,
              child: Center(
                child: Text(
                  'CONFIRMAR Y GUARDAR',
                  style: KwallTheme.hudHeaderFont.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTab(String type, String label, Color color) {
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: color, width: 1.5) : null,
          ),
          child: Center(
            child: Text(
              label,
              style: KwallTheme.hudHeaderFont.copyWith(
                color: isSelected ? color : KwallTheme.textMuted,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArcadeNumpad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', '⌫'],
    ];

    return Column(
      children: keys.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: row.map((key) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Material(
                    color: KwallTheme.surfaceCard,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => _onNumpadPress(key),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: KwallTheme.border),
                        ),
                        child: Center(
                          child: Text(
                            key,
                            style: KwallTheme.gameFont.copyWith(
                              color: KwallTheme.textBright,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
