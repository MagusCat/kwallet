import 'package:flutter/material.dart';

import '../../../../core/theme/kwall_theme.dart';
import 'currency_rate_dialog.dart';

class CurrenciesSettingsSection extends StatelessWidget {
  final TextEditingController dominantCurrencyController;
  final List<String> referenceCurrencies;
  final Map<String, double> rates;
  final Future<void> Function(String currency, double rate, String notes) onSaveRate;
  final Future<void> Function(String currency) onRemoveCurrency;
  final Future<List<Map<String, dynamic>>> Function(String currency) onFetchHistory;

  const CurrenciesSettingsSection({
    super.key,
    required this.dominantCurrencyController,
    required this.referenceCurrencies,
    required this.rates,
    required this.onSaveRate,
    required this.onRemoveCurrency,
    required this.onFetchHistory,
  });

  void _openRateDialog(BuildContext context, String currency, {bool isNew = false}) {
    final dominant = dominantCurrencyController.text.trim().isEmpty
        ? '\$'
        : dominantCurrencyController.text.trim();
    final currentRate = rates[currency] ?? 1.0;

    showDialog<void>(
      context: context,
      builder: (ctx) => CurrencyRateDialog(
        currency: currency,
        dominantCurrency: dominant,
        currentRate: currentRate,
        onFetchHistory: onFetchHistory,
        onSave: (newRate, notes) => onSaveRate(currency, newRate, notes),
      ),
    );
  }

  void _promptAddCurrency(BuildContext context) {
    final textController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Agregar moneda alternativa'),
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Código o símbolo',
            hintText: 'USD, EUR, NIO, CAD…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final code = textController.text.trim().toUpperCase();
              if (code.isNotEmpty &&
                  code != dominantCurrencyController.text.trim().toUpperCase()) {
                Navigator.of(ctx).pop();
                _openRateDialog(context, code, isNew: true);
              }
            },
            child: const Text('Siguiente'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dominant = dominantCurrencyController.text.trim().isEmpty
        ? '\$'
        : dominantCurrencyController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Monedas',
          style: KwallTheme.fontTitle.copyWith(fontSize: 21),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: dominantCurrencyController,
          maxLength: 12,
          decoration: const InputDecoration(
            labelText: 'Moneda dominante (principal)',
            hintText: 'C\$, USD, €, puntos…',
            helperText: 'Moneda base principal de tus finanzas y metas.',
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Monedas alternativas y conversión global',
          style: KwallTheme.fontTitle.copyWith(fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          'Asigna la tasa de conversión para cada moneda alternativa respecto a $dominant. Todas tus cuentas mostrarán su equivalencia.',
          style: TextStyle(color: KwallTheme.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 10),
        if (referenceCurrencies.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in referenceCurrencies)
                ActionChip(
                  avatar: const Icon(Icons.currency_exchange_rounded, size: 16),
                  label: Text(
                    rates.containsKey(c)
                        ? '$c (1 = ${rates[c]!.toStringAsFixed(rates[c]! % 1 == 0 ? 0 : 2)} $dominant)'
                        : c,
                  ),
                  onPressed: () => _openRateDialog(context, c),
                  backgroundColor: KwallTheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _promptAddCurrency(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Agregar moneda alternativa'),
        ),
      ],
    );
  }
}
