class BudgetModel {
  final String id;
  final int month;
  final int year;
  final double monthlyLimit;
  final double? weeklyLimit;
  final double? dailyLimit;
  final DateTime createdAt;

  BudgetModel({
    required this.id,
    required this.month,
    required this.year,
    required this.monthlyLimit,
    this.weeklyLimit,
    this.dailyLimit,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'month': month,
      'year': year,
      'monthly_limit': monthlyLimit,
      'weekly_limit': weeklyLimit,
      'daily_limit': dailyLimit,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'] as String,
      month: map['month'] as int,
      year: map['year'] as int,
      monthlyLimit: (map['monthly_limit'] as num).toDouble(),
      weeklyLimit: (map['weekly_limit'] as num?)?.toDouble(),
      dailyLimit: (map['daily_limit'] as num?)?.toDouble(),
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
