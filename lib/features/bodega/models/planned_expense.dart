class PlannedExpense {
  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String recurrence; // 'one_time', 'monthly', 'yearly'
  final String categoryId;
  final String? accountId;
  final bool isCompleted;
  final String note;
  final String? iconKey;
  final DateTime createdAt;
  final int recurrenceDay;

  PlannedExpense({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    this.recurrence = 'monthly',
    required this.categoryId,
    this.accountId,
    this.isCompleted = false,
    this.note = '',
    this.iconKey,
    required this.createdAt,
    int? recurrenceDay,
  }) : recurrenceDay = recurrenceDay ?? dueDate.day;

  PlannedExpense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    String? recurrence,
    String? categoryId,
    String? accountId,
    bool? isCompleted,
    String? note,
    String? iconKey,
    DateTime? createdAt,
  }) {
    return PlannedExpense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      recurrence: recurrence ?? this.recurrence,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      isCompleted: isCompleted ?? this.isCompleted,
      note: note ?? this.note,
      iconKey: iconKey ?? this.iconKey,
      createdAt: createdAt ?? this.createdAt,
      recurrenceDay: recurrenceDay,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'recurrence': recurrence,
      'category_id': categoryId,
      'account_id': accountId,
      'is_completed': isCompleted ? 1 : 0,
      'note': note,
      'icon_key': iconKey,
      'created_at': createdAt.toIso8601String(),
      'recurrence_day': recurrenceDay,
    };
  }

  factory PlannedExpense.fromMap(Map<String, dynamic> map) {
    return PlannedExpense(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      dueDate:
          DateTime.tryParse(map['due_date'] as String? ?? '') ?? DateTime.now(),
      recurrence: (map['recurrence'] as String?) ?? 'monthly',
      categoryId: (map['category_id'] as String?) ?? 'cat_other',
      accountId: map['account_id'] as String?,
      isCompleted: (map['is_completed'] as int?) == 1,
      note: (map['note'] as String?) ?? '',
      iconKey: map['icon_key'] as String?,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      recurrenceDay: map['recurrence_day'] as int?,
    );
  }

  String get recurrenceLabel {
    switch (recurrence) {
      case 'one_time':
        return 'Único plazo';
      case 'monthly':
        return 'Mensual recurrente';
      case 'weekly':
        return 'Semanal recurrente';
      case 'yearly':
        return 'Anual recurrente';
      default:
        return 'Planificado';
    }
  }

  DateTime? nextDate(DateTime date) {
    if (recurrence == 'weekly') {
      return DateTime(date.year, date.month, date.day + 7);
    }
    if (recurrence != 'monthly' && recurrence != 'yearly') return null;
    final month = DateTime(
      date.year + (recurrence == 'yearly' ? 1 : 0),
      date.month + (recurrence == 'monthly' ? 1 : 0),
    );
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    return DateTime(month.year, month.month, recurrenceDay.clamp(1, lastDay));
  }

  Iterable<DateTime> datesBetween(
    DateTime start,
    DateTime end, {
    bool includeOverdue = false,
  }) sync* {
    if (isCompleted) return;
    var date = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final from = DateTime(start.year, start.month, start.day);
    final until = DateTime(end.year, end.month, end.day);
    while (!date.isAfter(until)) {
      if (!date.isBefore(from) || includeOverdue) yield date;
      final next = nextDate(date);
      if (next == null) break;
      date = next;
    }
  }

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return target.difference(today).inDays;
  }
}
