import 'package:flutter/material.dart';

import '../../../app/app_dependencies.dart';
import '../../../core/mvvm/view_model_state.dart';
import '../view_models/account_editor_view_model.dart';
import '../../../core/theme/kwall_theme.dart';
import '../models/account.dart';

class AddAccountDialog extends StatefulWidget {
  final String currency;
  final String initialType;
  final Account? account;
  const AddAccountDialog({
    super.key,
    this.currency = '\$',
    this.initialType = 'cash',
    this.account,
  });
  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState
    extends ViewModelState<AddAccountDialog, AccountEditorViewModel> {
  @override
  AccountEditorViewModel createViewModel(AppDependencies dependencies) =>
      dependencies.accountEditor();
  late final _name = TextEditingController(text: widget.account?.name ?? '');
  late final _balance = TextEditingController(
    text: widget.account?.balance.toStringAsFixed(2) ?? '0.00',
  );
  late final _minimum = TextEditingController(
    text: widget.account?.minimumBalance.toStringAsFixed(2) ?? '0.00',
  );
  late String _type = widget.account?.type ?? widget.initialType;
  bool get _saving => model.busy;
  String? get _error => model.error;
  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    _minimum.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final saved = await model.save(
      original: widget.account,
      name: _name.text,
      balanceText: _balance.text,
      minimumText: _minimum.text,
      type: _type,
      currency: widget.currency,
      color: KwallTheme.accent.toARGB32(),
    );
    if (saved && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.account == null ? 'Nueva cuenta' : 'Cuidar mi cuenta',
              style: KwallTheme.fontTitle.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Nombre de la cuenta',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: [
                for (final type in {
                  'cash': 'Efectivo',
                  'bank': 'Banco',
                  'vault': 'Ahorro',
                  'credit': 'Crédito',
                }.entries)
                  DropdownMenuItem(value: type.key, child: Text(type.value)),
              ],
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _balance,
              readOnly: widget.account != null,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: widget.account == null
                    ? 'Saldo inicial'
                    : 'Saldo actual',
                prefixText: '${widget.currency} ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _minimum,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Mínimo que quiero proteger',
                prefixText: '${widget.currency} ',
                prefixIcon: const Icon(Icons.shield_outlined),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'El anillo muestra cuánto del mínimo está cubierto. El presupuesto flexible protege esta reserva.',
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: TextStyle(color: KwallTheme.expenseRed)),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(_saving ? 'Guardando…' : 'Guardar cuenta'),
            ),
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    ),
  );
}
