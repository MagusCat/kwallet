import '../../../core/contracts/app_repositories.dart';
import '../../../core/models/amount.dart';
import '../../../core/mvvm/view_model.dart';
import '../models/finance_overview.dart';

class BudgetEditorViewModel extends ViewModel {
  final FinanceRepository repository;
  BudgetEditorViewModel(this.repository);
  double previewAmount(String text) => parseAmount(text) ?? 0;
  Future<bool> save(
    BudgetPeriod period,
    String amountText,
    String mode,
    double share,
  ) {
    final amount = parseAmount(amountText);
    if (mode == 'assigned' && (amount == null || amount < 0)) {
      return Future.value(fail('Escribe un monto válido.'));
    }
    return perform(
      () => repository.allocateBudget(
        period,
        DateTime.now(),
        mode == 'assigned' ? amount : null,
        mode: mode,
        share: share,
      ),
    );
  }
}
