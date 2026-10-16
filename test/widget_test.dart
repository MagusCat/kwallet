import 'package:flutter_test/flutter_test.dart';
import 'package:kwall/core/theme/kwall_theme.dart';
import 'package:kwall/features/bodega/models/account.dart';

void main() {
  test('Account model serialization and currency format test', () {
    final now = DateTime.now();
    final acc = Account(
      id: 'acc_1',
      name: 'Bolsillo',
      type: 'cash',
      balance: 150.75,
      createdAt: now,
    );

    expect(acc.name, 'Bolsillo');
    expect(acc.balance, 150.75);
    expect(KwallTheme.formatCurrency(acc.balance), '\$150.75');

    final map = acc.toMap();
    final restored = Account.fromMap(map);
    expect(restored.id, acc.id);
    expect(restored.balance, acc.balance);
  });
}
