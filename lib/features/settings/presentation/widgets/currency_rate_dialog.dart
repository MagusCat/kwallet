import 'package:flutter/material.dart';

import '../../../../core/theme/kwall_theme.dart';

class CurrencyRateDialog extends StatefulWidget {
  final String currency;
  final String dominantCurrency;
  final double currentRate;
  final Future<List<Map<String, dynamic>>> Function(String currency) onFetchHistory;
  final Future<void> Function(double newRate, String notes) onSave;

  const CurrencyRateDialog({
    super.key,
    required this.currency,
    required this.dominantCurrency,
    required this.currentRate,
    required this.onFetchHistory,
    required this.onSave,
  });

  @override
  State<CurrencyRateDialog> createState() => _CurrencyRateDialogState();
}

class _CurrencyRateDialogState extends State<CurrencyRateDialog> {
  late final TextEditingController _rateController;
  final TextEditingController _notesController = TextEditingController();
  List<Map<String, dynamic>>? _history;
  bool _showHistory = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rateController = TextEditingController(
      text: widget.currentRate > 0 ? widget.currentRate.toString() : '1.0',
    );
  }

  @override
  void dispose() {
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final list = await widget.onFetchHistory(widget.currency);
    if (mounted) {
      setState(() {
        _history = list;
        _showHistory = true;
      });
    }
  }

  Future<void> _submit() async {
    final val = double.tryParse(_rateController.text.trim().replaceAll(',', '.'));
    if (val == null || val <= 0) return;
    setState(() => _saving = true);
    await widget.onSave(val, _notesController.text.trim());
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tasa: 1 ${widget.currency}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Valor de 1 ${widget.currency} en tu moneda principal (${widget.dominantCurrency}):',
              style: TextStyle(fontSize: 13, color: KwallTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Tasa de conversión',
                suffixText: widget.dominantCurrency,
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Motivo o nota (opcional)',
                hintText: 'Ej. Ajuste de mercado',
                isDense: true,
              ),
            ),
            const SizedBox(height: 16),
            if (!_showHistory)
              TextButton.icon(
                onPressed: _loadHistory,
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('Ver trazabilidad de cambios'),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Historial de tasas', style: KwallTheme.fontTitle),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => setState(() => _showHistory = false),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (_history == null)
                const Center(child: CircularProgressIndicator())
              else if (_history!.isEmpty)
                Text(
                  'Sin cambios registrados aún.',
                  style: TextStyle(fontSize: 12, color: KwallTheme.textSecondary),
                )
              else
                ..._history!.map((entry) {
                  final prev = (entry['previous_rate'] as num?)?.toDouble();
                  final next = (entry['new_rate'] as num?)?.toDouble() ?? 1.0;
                  final date = (entry['created_at'] as String? ?? '').replaceAll('T', ' ').split('.').first;
                  final notes = entry['notes'] as String? ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: KwallTheme.surfaceContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prev == null
                                ? 'Inicial: 1 = $next ${widget.dominantCurrency}'
                                : '$prev -> $next ${widget.dominantCurrency}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                          if (notes.isNotEmpty)
                            Text(notes, style: const TextStyle(fontSize: 11)),
                          Text(date, style: TextStyle(fontSize: 10, color: KwallTheme.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Guardar'),
        ),
      ],
    );
  }
}
