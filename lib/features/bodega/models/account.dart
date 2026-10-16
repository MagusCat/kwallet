class Account {
  final String id;
  final String name;
  final String type; // 'cash', 'bank', 'vault', 'credit'
  final double balance;
  final String currency;
  final String iconKey;
  final int colorValue;
  final bool isArchived;
  final DateTime createdAt;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.currency = '\$',
    this.iconKey = 'wallet',
    this.colorValue = 0xFF00FF9D,
    this.isArchived = false,
    required this.createdAt,
  });

  Account copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    String? currency,
    String? iconKey,
    int? colorValue,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'balance': balance,
      'currency': currency,
      'icon_key': iconKey,
      'color_value': colorValue,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      balance: (map['balance'] as num).toDouble(),
      currency: (map['currency'] as String?) ?? '\$',
      iconKey: (map['icon_key'] as String?) ?? 'wallet',
      colorValue: (map['color_value'] as int?) ?? 0xFF00FF9D,
      isArchived: (map['is_archived'] as int?) == 1,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  String get typeLabel {
    switch (type) {
      case 'cash':
        return 'Bolsillo / Efectivo';
      case 'bank':
        return 'Banco Principal';
      case 'vault':
        return 'Hucha Secreta';
      case 'credit':
        return 'Tarjeta / Crédito';
      default:
        return 'Bóveda';
    }
  }
}
