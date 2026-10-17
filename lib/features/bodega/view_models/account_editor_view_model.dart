import 'package:uuid/uuid.dart';

import '../../../core/contracts/app_repositories.dart';
import '../../../core/models/amount.dart';
import '../../../core/mvvm/view_model.dart';
import '../models/account.dart';

class AccountEditorViewModel extends ViewModel {
  final FinanceRepository repository;
  AccountEditorViewModel(this.repository);
  Future<bool> save({
    Account? original,
    required String name,
    required String balanceText,
    required String minimumText,
    required String type,
    required String currency,
    required int color,
  }) {
    final balance = parseAmount(balanceText);
    final minimum = parseAmount(minimumText);
    if (name.trim().isEmpty ||
        balance == null ||
        minimum == null ||
        minimum < 0) {
      return Future.value(fail('Completa el nombre, saldo y mínimo válido.'));
    }
    final account =
        original?.copyWith(
          name: name.trim(),
          type: type,
          minimumBalance: minimum,
        ) ??
        Account(
          id: const Uuid().v4(),
          name: name.trim(),
          type: type,
          balance: balance,
          minimumBalance: minimum,
          currency: currency,
          colorValue: color,
          createdAt: DateTime.now(),
        );
    return perform(
      () => original == null
          ? repository.createAccount(account)
          : repository.updateAccount(account),
    );
  }
}
