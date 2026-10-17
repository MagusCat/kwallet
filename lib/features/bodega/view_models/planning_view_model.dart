import '../../../core/contracts/app_repositories.dart';
import '../../../core/models/date_span.dart';
import '../../../core/mvvm/view_model.dart';
import '../models/account.dart';
import '../models/category_model.dart';
import '../models/finance_overview.dart';
import '../models/planned_expense.dart';

class PlanningViewModel extends ViewModel {
  final FinanceRepository repository;
  final SettingsRepository preferences;
  List<PlannedExpense> plans = const [];
  List<Account> accounts = const [];
  List<CategoryModel> categories = const [];
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  DateSpan range = DateSpan(dateOnly(DateTime.now()), dateOnly(DateTime.now()));
  bool loading = true;
  bool rangeMode = false;
  DateTime? rangeAnchor;
  PlanningViewModel(this.repository, this.preferences) {
    for (final source in {repository.changes, preferences.changes}) {
      observe(source, load);
    }
  }
  double get balance => accounts.fold(0, (sum, a) => sum + a.balance);
  double get committed => plannedTotal(
    plans,
    dateOnly(DateTime.now()),
    DateTime.now().add(const Duration(days: 30)),
    includeOverdue: true,
  );
  List<PlannedExpense> get overdue => plans
      .where(
        (p) =>
            !p.isCompleted &&
            dateOnly(p.dueDate).isBefore(dateOnly(DateTime.now())),
      )
      .toList();
  List<({PlannedExpense plan, DateTime date})> get entries => [
    for (final plan in plans)
      for (final date in plan.datesBetween(range.start, range.end))
        (plan: plan, date: date),
  ]..sort((a, b) => a.date.compareTo(b.date));
  Future<void> load({bool restoreRange = false}) async {
    final request = beginRequest();
    try {
      final nextPlans = await repository.getPlannedExpenses();
      final nextAccounts = await repository.getAccounts();
      final nextCategories = await repository.getCategories(type: 'expense');
      final settings = restoreRange
          ? await preferences.getSettings()
          : <String, String>{};
      if (!isCurrent(request)) return;
      plans = List.unmodifiable(nextPlans);
      accounts = List.unmodifiable(nextAccounts);
      categories = List.unmodifiable(nextCategories);
      loading = false;
      error = null;
      final start = DateTime.tryParse(settings['plan_range_start'] ?? '');
      final end = DateTime.tryParse(settings['plan_range_end'] ?? '');
      if (start != null && end != null && !end.isBefore(start)) {
        range = DateSpan(dateOnly(start), dateOnly(end));
        rangeMode = dateOnly(start) != dateOnly(end);
        month = DateTime(start.year, start.month);
      }
      changed();
    } catch (_) {
      if (isCurrent(request)) {
        loading = false;
        fail('No se pudo cargar la planificación.');
      }
    }
  }

  Future<void> selectRange(
    DateTime start,
    DateTime end, {
    bool preserveMode = false,
  }) async {
    range = DateSpan(dateOnly(start), dateOnly(end));
    if (!preserveMode) rangeMode = dateOnly(start) != dateOnly(end);
    month = DateTime(start.year, start.month);
    changed();
    try {
      await preferences.saveSettings({
        'plan_range_start': start.toIso8601String(),
        'plan_range_end': end.toIso8601String(),
      });
    } catch (_) {
      fail('No se pudo guardar la selección. Reintenta.');
    }
  }

  void setMonth(DateTime value) {
    month = value;
    changed();
  }

  void setRangeMode(bool value) {
    rangeMode = value;
    rangeAnchor = null;
    changed();
  }

  void tapDate(DateTime date) {
    if (!rangeMode || rangeAnchor == null) {
      rangeAnchor = rangeMode ? date : null;
      selectRange(date, date, preserveMode: true);
    } else {
      final anchor = rangeAnchor!;
      rangeAnchor = null;
      selectRange(
        date.isBefore(anchor) ? date : anchor,
        date.isBefore(anchor) ? anchor : date,
        preserveMode: true,
      );
    }
  }

  Future<bool> pay(PlannedExpense plan, String? account) {
    if (plan.amount > 0 && account == null) {
      return Future.value(fail('Añade una cuenta antes de registrar el pago.'));
    }
    return perform(
      () => repository.payPlannedExpense(
        plan.id,
        account ?? plan.accountId ?? '',
        expectedDueDate: plan.dueDate,
      ),
    );
  }

  Future<bool> remove(PlannedExpense plan) =>
      perform(() => repository.deletePlannedExpense(plan.id));
}
