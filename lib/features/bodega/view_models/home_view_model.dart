import 'dart:math' as math;

import '../../../core/mvvm/view_model.dart';

import '../../../core/contracts/app_repositories.dart';
import '../../../core/services/widget_sync_service.dart';
import '../../journal/models/journal_models.dart';
import '../models/account.dart';
import '../models/budget_model.dart';
import '../models/category_model.dart';
import '../models/finance_overview.dart';
import '../models/planned_expense.dart';
import '../models/transaction_record.dart';

class HomeViewModel extends ViewModel {
  final FinanceRepository finance;
  final JournalRepository journal;
  final SettingsRepository preferences;
  HomeViewModel(this.finance, this.journal, this.preferences) {
    for (final source in {
      finance.changes,
      journal.changes,
      preferences.changes,
    }) {
      observe(source, load);
    }
  }
  int _xp = 0;
  int _reward = 0;
  bool _loaded = false;
  List<Account> _accounts = const [];
  List<TransactionRecord> _transactions = const [];
  Map<String, CategoryModel> _categories = const {};
  List<PlannedExpense> _plans = const [];
  List<PersonalNote> _notes = const [];
  List<Habit> _habits = const [];
  Map<String, String> _settings = const {};
  Map<BudgetPeriod, double> _allocations = const {};
  BudgetModel? _budget;
  Map<BudgetPeriod, double> _spent = const {};
  BudgetPeriod _period = BudgetPeriod.monthly;
  String? _filter;

  List<Account> get accounts => _accounts;
  List<TransactionRecord> get transactions => _transactions;
  Map<String, CategoryModel> get categories => _categories;
  List<PersonalNote> get notes => _notes;
  List<Habit> get habits => _habits;
  Map<String, String> get settings => _settings;
  BudgetModel? get budget => _budget;
  BudgetPeriod get period => _period;
  double get spent => _spent[_period] ?? 0;
  String? get filter => _filter;
  int get xp => _xp;
  String get currency => _settings['currency'] ?? '\$';
  double get balance => _accounts.fold(0, (sum, a) => sum + a.balance);
  double get reserves => _accounts.fold(0, (sum, a) => sum + a.minimumBalance);
  double get committed => plannedTotal(
    _plans,
    DateTime.now(),
    DateTime.now().add(const Duration(days: 30)),
    includeOverdue: true,
  );
  double get weeklyCommitments {
    final week = periodRange(BudgetPeriod.weekly, DateTime.now());
    return plannedTotal(
      _plans,
      week.start,
      week.end.subtract(const Duration(days: 1)),
    );
  }

  double get available => math.max(0, balance - reserves - committed);
  String get budgetMode => _settings['budget_mode'] ?? 'assigned';
  double get share =>
      (double.tryParse(_settings['budget_share'] ?? '') ?? 100).clamp(1, 100);
  double get limit => budgetMode == 'available'
      ? flexibleBudget(
          spent: spent,
          balance: balance,
          reserves: reserves,
          commitments: committed,
          share: share,
        )
      : _allocations[_period] ??
            (_budget == null ? 0 : budgetLimit(_budget!, _period));

  void selectAccount(String? id) {
    _filter = id != null && _filter != id ? id : null;
    _reward = 0;
    changed();
    load();
  }

  void selectPeriod(BudgetPeriod period) {
    _period = period;
    _reward = 0;
    changed();
  }

  int takeReward() {
    final reward = _reward;
    _reward = 0;
    return reward;
  }

  int get completedHabitsToday =>
      _habits.where((h) => h.logFor(DateTime.now())?.completed == true).length;
  int get totalHabitsToday => _habits.length;
  int get pendingHabitsCount => _habits
      .where((h) => h.logFor(DateTime.now())?.completed != true)
      .length;

  List<({PersonalNote note, int index, NoteItem item})> get pendingTasks {
    final result = <({PersonalNote note, int index, NoteItem item})>[];
    for (final note in _notes) {
      if (note.kind == 'list') {
        for (var i = 0; i < note.items.length; i++) {
          if (!note.items[i].done) {
            result.add((note: note, index: i, item: note.items[i]));
          }
        }
      }
    }
    return result;
  }

  List<PlannedExpense> get upcomingPlans {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final limit = today.add(const Duration(days: 30));
    return _plans
        .where((p) => !p.dueDate.isBefore(today) && !p.dueDate.isAfter(limit))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  Future<bool> voidMovement(TransactionRecord tx) =>
      perform(() => finance.deleteTransaction(tx));

  Future<bool> completeHabit(Habit habit, [DateTime? day]) async {
    final ok = await perform(
      () => journal.logHabitDays(
        [habit.id],
        [day ?? DateTime.now()],
        completed: true,
        mood: 'happy',
      ),
    );
    if (ok) {
      _syncWidget();
    }
    return ok;
  }

  Future<bool> checkNote(PersonalNote note, int index, bool done) => perform(
    () => journal.setNoteItem(
      note.id,
      index,
      done,
      expectedText: note.items[index].text,
    ),
  );

  Future<bool> petCompanion([int points = 2]) async {
    bool awarded = false;
    await perform(() async {
      awarded = await journal.awardAffection(points);
    });
    if (awarded) {
      _syncWidget();
    }
    return awarded;
  }

  void _syncWidget() {
    WidgetSyncService.syncWidget(
      petName: _settings['pet_name'] ?? 'Mishi',
      xp: _xp,
      completedHabits: completedHabitsToday,
      totalHabits: totalHabitsToday,
      pendingHabits: pendingHabitsCount,
      statusMessage: pendingHabitsCount > 0
          ? 'Tienes $pendingHabitsCount ${pendingHabitsCount == 1 ? "hábito pendiente" : "hábitos pendientes"} hoy.'
          : (totalHabitsToday > 0
              ? 'Todos tus hábitos completados hoy.'
              : 'Todo al día y organizado.'),
      petStyle: _settings['pet_style'] ?? 'classic',
      themePalette: _settings['palette'] ?? 'forest',
    );
  }

  Future<void> load() async {
    final version = beginRequest();
    try {
      final pendingAffection = await WidgetSyncService.consumePendingAffection();
      if (pendingAffection > 0) {
        await journal.awardAffection(pendingAffection);
      }
      final now = DateTime.now();
      final accounts = await finance.getAccounts();
      final filter = accounts.any((a) => a.id == _filter) ? _filter : null;
      final transactions = await finance.getTransactions(
        accountId: filter,
        limit: 5,
      );
      final categories = await finance.getCategories();
      final budget = await finance.getCurrentBudget();
      final plans = await finance.getPlannedExpenses(includeCompleted: false);
      final settings = await preferences.getSettings();
      final allocations = await finance.getBudgetAllocations(now);
      final xp = await journal.getExperience();
      final notes = await journal.getNotes();
      final habits = await journal.getHabits();
      final spent = await finance.getPeriodSpending(now);
      if (!isCurrent(version)) return;
      _reward = _loaded ? math.max(0, xp - _xp) : 0;
      _accounts = List.unmodifiable(accounts);
      _filter = filter;
      _transactions = List.unmodifiable(transactions);
      _categories = Map.unmodifiable({for (final c in categories) c.id: c});
      _budget = budget;
      _plans = List.unmodifiable(plans);
      _settings = Map.unmodifiable(settings);
      _allocations = Map.unmodifiable(allocations);
      _spent = Map.unmodifiable(spent);
      _notes = List.unmodifiable(notes);
      _habits = List.unmodifiable(habits);
      _xp = xp;
      _loaded = true;
      error = null;
      changed();
      _syncWidget();
    } catch (_) {
      if (isCurrent(version)) {
        _reward = 0;
        error = 'No se pudieron cargar tus datos.';
        changed();
      }
    }
  }
}
