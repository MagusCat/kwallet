class BudgetModel {
  final String id;
  final int month;
  final int year;
  final double monthlyLimit;
  final DateTime createdAt;

  BudgetModel({
    required this.id,
    required this.month,
    required this.year,
    required this.monthlyLimit,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'year': year,
      'monthly_limit': monthlyLimit,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      month: map['month'] as int,
      year: map['year'] as int,
      monthlyLimit: (map['monthly_limit'] as num).toDouble(),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
