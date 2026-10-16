import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/game_hud_widgets.dart';
import '../models/account.dart';

class AddAccountDialog extends StatefulWidget {
  final String currency;

  const AddAccountDialog({super.key, this.currency = '\$'});

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController(text: '0.00');

  String _selectedType = 'cash';
  int _selectedColor = 0xFF10B981;

  final List<Map<String, dynamic>> _types = [
    {'type': 'cash', 'label': 'Efectivo / Cartera', 'color': 0xFF10B981},
    {'type': 'bank', 'label': 'Banco / Débito', 'color': 0xFF3B82F6},
    {'type': 'vault', 'label': 'Hucha / Ahorro', 'color': 0xFFF59E0B},
    {'type': 'credit', 'label': 'Tarjeta de Crédito', 'color': 0xFFEF4444},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor escribe un nombre para la cuenta')),
      );
      return;
    }

    final balanceText = _balanceController.text.trim().replaceAll(',', '.');
    final balance = double.tryParse(balanceText) ?? 0.0;

    final newAccount = Account(
      id: const Uuid().v4(),
      name: name,
      type: _selectedType,
      balance: balance,
      currency: widget.currency,
      colorValue: _selectedColor,
      createdAt: DateTime.now(),
    );

    await DatabaseService.instance.createAccount(newAccount);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: KwallTheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nueva Cuenta / Bóveda',
                  style: KwallTheme.fontTitle.copyWith(fontSize: 18),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: KwallTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              'Nombre de la cuenta',
              style: KwallTheme.fontBody.copyWith(fontSize: 12, color: KwallTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: KwallTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Ej. Cuenta sueldo, Ahorro viaje, Efectivo...',
              ),
            ),
            const SizedBox(height: 14),

            // Type
            Text(
              'Tipo de cuenta',
              style: KwallTheme.fontBody.copyWith(fontSize: 12, color: KwallTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final isSelected = _selectedType == t['type'];
                return ChoiceChip(
                  label: Text(t['label'] as String),
                  selected: isSelected,
                  selectedColor: Color(t['color'] as int).withValues(alpha: 0.2),
                  backgroundColor: KwallTheme.surfaceContainer,
                  side: BorderSide(
                    color: isSelected ? Color(t['color'] as int) : KwallTheme.border,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Color(t['color'] as int) : KwallTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedType = t['type'] as String;
                      _selectedColor = t['color'] as int;
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Initial Balance
            Text(
              'Saldo inicial (${widget.currency})',
              style: KwallTheme.fontBody.copyWith(fontSize: 12, color: KwallTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: KwallTheme.fontDisplay.copyWith(color: Color(_selectedColor), fontSize: 26),
              decoration: InputDecoration(
                prefixText: '${widget.currency} ',
              ),
            ),
            const SizedBox(height: 20),

            ExpressiveButton(
              onPressed: _saveAccount,
              color: Color(_selectedColor),
              child: const Center(
                child: Text(
                  'Crear Cuenta',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
