import '../../../features/bodega/models/spending_summary.dart';
import '../../../features/bodega/models/category_model.dart';
import '../database_context.dart';

mixin InsightsRepository on DatabaseContext {
  Future<List<DailySpend>> getDailySpendingLast7Days() async {
    final db = await database;
    final now = DateTime.now();
    final List<DailySpend> result = [];

    const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      final start = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        0,
        0,
        0,
      ).toIso8601String();
      final end = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
        23,
        59,
        59,
      ).toIso8601String();

      final rows = await db.rawQuery(
        "SELECT SUM(amount) as total FROM transactions WHERE type = 'expense' AND date BETWEEN ? AND ?",
        [start, end],
      );

      final total = (rows.first['total'] as num?)?.toDouble() ?? 0.0;
      final dayLabel = weekdays[targetDate.weekday - 1];

      result.add(
        DailySpend(
          date: targetDate,
          dayLabel: i == 0 ? 'Hoy' : dayLabel,
          amount: total,
        ),
      );
    }

    return result;
  }

  Future<List<CategoryBreakdown>> getCategorySpendingBreakdown(
    int month,
    int year,
  ) async {
    final db = await database;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();

    final totalSpentResult = await db.rawQuery(
      "SELECT SUM(amount) as grand_total FROM transactions WHERE type = 'expense' AND date BETWEEN ? AND ?",
      [start, end],
    );
    final grandTotal =
        (totalSpentResult.first['grand_total'] as num?)?.toDouble() ?? 0.0;
    if (grandTotal <= 0) return [];

    final rows = await db.rawQuery(
      "SELECT category_id, SUM(amount) as total FROM transactions WHERE type = 'expense' AND date BETWEEN ? AND ? GROUP BY category_id ORDER BY total DESC",
      [start, end],
    );

    final categories = (await db.query('categories'))
        .map(CategoryModel.fromMap);
    final catMap = {for (var c in categories) c.id: c};

    final List<CategoryBreakdown> breakdown = [];
    for (final r in rows) {
      final catId = r['category_id'] as String;
      final total = (r['total'] as num).toDouble();
      final cat =
          catMap[catId] ??
          CategoryModel(
            id: catId,
            name: 'Varios',
            type: 'expense',
            iconKey: 'tag',
            colorValue: 0xFF625B52,
          );

      breakdown.add(
        CategoryBreakdown(
          category: cat,
          amount: total,
          percentage: (total / grandTotal) * 100,
        ),
      );
    }
    return breakdown;
  }
}
