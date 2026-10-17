import 'package:flutter/material.dart';

import '../theme/kwall_theme.dart';

class ContentWidth extends StatelessWidget {
  final Widget child;
  final double width;
  const ContentWidth({super.key, required this.child, this.width = 800});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: child,
    ),
  );
}

class LedgerPanel extends StatelessWidget {
  final Widget child;
  const LedgerPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Material(
    color: KwallTheme.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: KwallTheme.border.withValues(alpha: .65)),
    ),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}

class CommitmentAlert extends StatelessWidget {
  final double balance;
  final double committed;
  final String currency;
  const CommitmentAlert({
    super.key,
    required this.balance,
    required this.committed,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (committed <= balance) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: LedgerPanel(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: KwallTheme.expenseRed),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Te faltan ${KwallTheme.formatCurrency(committed - balance, currency)}',
                    style: KwallTheme.fontTitle.copyWith(
                      color: KwallTheme.expenseRed,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pagos vencidos y próximos 30 días',
                    style: TextStyle(color: KwallTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SheetBody extends StatelessWidget {
  final Widget child;
  const SheetBody({super.key, required this.child});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: ContentWidth(
      width: 560,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(padding: EdgeInsets.all(20), child: child),
      ),
    ),
  );
}

void showFailure(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        error is String
            ? error
            : 'No se pudo guardar. Revisa los datos e inténtalo otra vez.',
      ),
    ),
  );
}
