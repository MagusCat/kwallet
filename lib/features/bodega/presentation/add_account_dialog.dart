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
  late final List<String> _currencies = [
    if (widget.account != null)
      ...widget.account!.currencies
    else
      widget.currency,
  ];
  final _newCurrencyController = TextEditingController();
  late String _type = widget.account?.type ?? widget.initialType;
  bool get _saving => model.busy;
  bool _savedSuccess = false;
  String? get _error => model.error;

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    _minimum.dispose();
    _baseCurrency.dispose();
    _newCurrencyController.dispose();
    super.dispose();
  }

  void _addCurrency() {
    final cur = _newCurrencyController.text.trim();
    if (cur.isNotEmpty && !_currencies.contains(cur)) {
      setState(() {
        _currencies.add(cur);
        _newCurrencyController.clear();
      });
    }
  }

  void _removeCurrency(String cur) {
    if (cur == _baseCurrency.text.trim()) return; // Cannot remove base currency
    setState(() {
      _currencies.remove(cur);
    });
  }

  Future<void> _showCurrencyHistory() async {
    if (widget.account == null) return;
    final history = await model.loadCurrencyHistory(widget.account!.id);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registro de cambios de monedas'),
        content: SizedBox(
          width: 360,
          child: history.isEmpty
              ? const Text('Aún no hay cambios registrados.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (_, i) {
                    final item = history[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.currency_exchange_rounded),
                      title: Text(
                        '${item['currency']} (1:${(item['conversion_rate'] as num?)?.toDouble() ?? 1.0})',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${item['notes'] ?? item['change_type']}\n${item['created_at']?.toString().substring(0, 19)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final base = _baseCurrency.text.trim().isEmpty ? '\$' : _baseCurrency.text.trim();
    if (!_currencies.contains(base)) {
      _currencies.insert(0, base);
    }
    final saved = await model.save(
      original: widget.account,
      name: _name.text,
      balanceText: _balance.text,
      minimumText: _minimum.text,
      type: _type,
      currency: base,
      currencies: _currencies,
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
              controller: _baseCurrency,
              decoration: const InputDecoration(
                labelText: 'Moneda dominante de la cuenta',
                hintText: 'USD, C\$, EUR, etc.',
                helperText: 'Determina la diversificación del efectivo de esta cuenta.',
              ),
              onChanged: (val) {
                final base = val.trim();
                if (base.isNotEmpty && !_currencies.contains(base)) {
                  setState(() {
                    if (_currencies.isNotEmpty) {
                      _currencies[0] = base;
                    } else {
                      _currencies.add(base);
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            // Multi-currency list support (1:1 conversion)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monedas secundarias de referencia (1 a 1)',
                  style: KwallTheme.fontTitle.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final c in _currencies)
                      Chip(
                        label: Text(c == _baseCurrency.text.trim() ? '$c (dominante)' : '$c (1:1)'),
                        onDeleted: c == _baseCurrency.text.trim() ? null : () => _removeCurrency(c),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newCurrencyController,
                        decoration: const InputDecoration(
                          hintText: 'Agregar moneda (ej. EUR, MXN)',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        onSubmitted: (_) => _addCurrency(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Añadir a la lista',
                      onPressed: _addCurrency,
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
                if (widget.account != null) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _showCurrencyHistory,
                      icon: const Icon(Icons.history_rounded, size: 16),
                      label: const Text('Ver registro de cambios de moneda'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _balance,
              readOnly: widget.account != null,
              onTap: widget.account != null
                  ? () {
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: Row(
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                color: Theme.of(context).snackBarTheme.contentTextStyle?.color ??
                                    (KwallTheme.isDark ? const Color(0xFF191C19) : const Color(0xFFF0F1EB)),
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Saldo de solo lectura. Se calcula automáticamente con tus transacciones.',
                                ),
                              ),
                            ],
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  : null,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: widget.account == null
                    ? 'Saldo inicial'
                    : 'Saldo actual (solo lectura)',
                prefixText: '${_baseCurrency.text} ',
                suffixIcon: widget.account != null
                    ? Tooltip(
                        message:
                            'Solo lectura: se actualiza con los movimientos',
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: KwallTheme.textSecondary,
                        ),
                      )
                    : null,
                helperText: widget.account != null
                    ? 'Solo lectura · Calculado según tus movimientos'
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
                labelText: 'Mínimo que quiero proteger',
                prefixText: '${_baseCurrency.text} ',
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
                            : Icons.check,
                        key: ValueKey(_savedSuccess),
                      ),
              ),
              label: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  _saving
                      ? 'Guardando…'
                      : _savedSuccess
                          ? '¡Guardado!'
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
