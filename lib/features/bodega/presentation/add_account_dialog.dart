import '../../../core/widgets/currency_selector.dart';
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
  late final _baseCurrency = TextEditingController(
    text: widget.account?.currency ?? widget.currency,
  );
  late String _type = widget.account?.type ?? widget.initialType;
  bool get _saving => model.busy;
  bool _savedSuccess = false;
  String? get _error => model.error;

  @override
  void onViewModelChanged() {
    super.onViewModelChanged();
    if (widget.account == null &&
        model.currencyOptions.isNotEmpty &&
        !model.currencyOptions.contains(_baseCurrency.text)) {
      _baseCurrency.text = model.currencyOptions.first;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    _minimum.dispose();
    _baseCurrency.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final cur = _baseCurrency.text.trim().isEmpty ? widget.currency : _baseCurrency.text.trim();
    final saved = await model.save(
      original: widget.account,
      name: _name.text,
      balanceText: _balance.text,
      minimumText: _minimum.text,
      type: _type,
      currency: cur,
      currencies: widget.account?.currencies ?? [cur],
      color: KwallTheme.accent.toARGB32(),
    );
    if (saved && mounted) {
      setState(() => _savedSuccess = true);
      await Future.delayed(const Duration(milliseconds: 320));
      if (mounted) Navigator.pop(context);
    }
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
              widget.account == null ? 'Nueva cuenta' : 'Editar cuenta',
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
              icon: const Icon(Icons.expand_more_rounded),
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
            CurrencySelector(
              value: _baseCurrency.text,
              options: model.currencyOptions.isNotEmpty
                  ? (model.currencyOptions.contains(_baseCurrency.text)
                      ? model.currencyOptions.toSet()
                      : {model.currencyOptions.first, ...model.currencyOptions})
                  : {_baseCurrency.text.trim().isNotEmpty ? _baseCurrency.text.trim() : widget.currency},
              currencyNames: model.currencyNames,
              onChanged: _saving ? null : (value) => setState(() => _baseCurrency.text = value),
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
                prefixText: '${_baseCurrency.text} ',
                suffixIcon: widget.account != null
                    ? Tooltip(
                        message:
                            'Saldo calculado por movimientos',
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: KwallTheme.textSecondary,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _minimum,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Reserva mínima',
                prefixText: '${_baseCurrency.text} ',
                prefixIcon: const Icon(Icons.shield_outlined),
              ),
            ),
            const SizedBox(height: 20),
            if (_error != null)
              Text(_error!, style: TextStyle(color: KwallTheme.expenseRed)),
            FilledButton.icon(
              onPressed: _saving || _savedSuccess ? null : _save,
              style: _savedSuccess
                  ? FilledButton.styleFrom(
                      backgroundColor: KwallTheme.incomeGreen,
                      foregroundColor: Colors.white,
                    )
                  : null,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        _savedSuccess
                            ? Icons.check_circle_rounded
                            : Icons.save_outlined,
                        key: ValueKey(_savedSuccess),
                      ),
              ),
              label: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _saving
                      ? 'Guardando…'
                      : _savedSuccess
                          ? 'Guardado'
                          : 'Guardar cuenta',
                  key: ValueKey('$_saving-$_savedSuccess'),
                ),
              ),
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
