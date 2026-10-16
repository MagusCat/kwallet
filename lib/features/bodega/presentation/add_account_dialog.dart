import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/game_hud_widgets.dart';
import '../models/account.dart';

class AddAccountDialog extends StatefulWidget {
  const AddAccountDialog({super.key});

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController(text: '0.00');

  String _selectedType = 'cash';
  int _selectedColor = 0xFF00FF9D;

  final List<Map<String, dynamic>> _types = [
    {'type': 'cash', 'label': 'Bolsillo (Efectivo)', 'color': 0xFF00FF9D},
    {'type': 'bank', 'label': 'Banco / Débito', 'color': 0xFF00D2FF},
    {'type': 'vault', 'label': 'Hucha Secreta (Ahorro)', 'color': 0xFFFFB800},
    {'type': 'credit', 'label': 'Tarjeta / Crédito', 'color': 0xFFFF3366},
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
        const SnackBar(content: Text('Por favor escribe un nombre para la bóveda')),
      );
      return;
    }

    final balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;

    final newAccount = Account(
      id: const Uuid().v4(),
      name: name,
      type: _selectedType,
      balance: balance,
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
        width: 420,
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NUEVA BÓVEDA / CUENTA',
                  style: KwallTheme.hudHeaderFont.copyWith(
                    color: KwallTheme.textBright,
                    fontSize: 15,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: KwallTheme.textMuted),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name
            const Text(
              'NOMBRE DE LA BÓVEDA',
              style: TextStyle(color: KwallTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: KwallTheme.textBright),
              decoration: InputDecoration(
                hintText: 'Ej. Billetera Gamer, Tarjeta Luna...',
                hintStyle: const TextStyle(color: KwallTheme.textMuted, fontSize: 13),
                filled: true,
                fillColor: KwallTheme.surfaceCardHighlight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),

            // Type
            const Text(
              'TIPO DE CUENTA',
              style: TextStyle(color: KwallTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final isSelected = _selectedType == t['type'];
                return ChoiceChip(
                  label: Text(
                    t['label'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: isSelected ? Colors.black : KwallTheme.textBright,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: Color(t['color'] as int),
                  backgroundColor: KwallTheme.surfaceCardHighlight,
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
            const Text(
              'SALDO INICIAL (\$)',
              style: TextStyle(color: KwallTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _balanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: KwallTheme.gameFont.copyWith(color: Color(_selectedColor), fontSize: 24),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: TextStyle(color: Color(_selectedColor)),
                filled: true,
                fillColor: KwallTheme.surfaceCardHighlight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 18),

            HudButton(
              onPressed: _saveAccount,
              color: Color(_selectedColor),
              child: Center(
                child: Text(
                  'ACTIVAR BÓVEDA',
                  style: KwallTheme.hudHeaderFont.copyWith(
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
