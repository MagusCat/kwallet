class MonthlyMovementSummary {
  final String month;
  final double income;
  final double expense;
  const MonthlyMovementSummary({
    required this.month,
    required this.income,
    required this.expense,
  });
  factory MonthlyMovementSummary.fromMap(Map<String, Object?> row) =>
      MonthlyMovementSummary(
        month: row['month'] as String,
        income: (row['income'] as num).toDouble(),
        expense: (row['expense'] as num).toDouble(),
      );
}
