import 'dart:convert';

class Account {
  final String id;
  final String name;
  final String type; // 'cash', 'bank', 'vault', 'credit'
  final double balance;
  final double minimumBalance;
  final double openingBalance;
  final String currency; // Moneda base
  final List<String> currencies; // Lista de monedas soportadas (base + secundarias 1:1)
  final String iconKey;
  final int colorValue;
  final bool isArchived;
  final DateTime createdAt;

  Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.minimumBalance = 0,
    double? openingBalance,
    this.currency = '\$',
    List<String>? currencies,
    this.iconKey = 'wallet',
    this.colorValue = 0xFF00FF9D,
    this.isArchived = false,
    required this.createdAt,
  })  : openingBalance = openingBalance ?? balance,
        currencies = (currencies != null && currencies.isNotEmpty)
            ? List.unmodifiable(currencies)
            : List.unmodifiable([currency]);

  Account copyWith({
    String? id,
    String? name,
    String? type,
    double? balance,
    double? minimumBalance,
    String? currency,
    List<String>? currencies,
    String? iconKey,
    int? colorValue,
    bool? isArchived,
    DateTime? createdAt,
  }) {
    final nextCurrency = currency ?? this.currency;
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      minimumBalance: minimumBalance ?? this.minimumBalance,
      openingBalance: openingBalance,
      currency: nextCurrency,
      currencies: currencies ??
          (currency != null && !this.currencies.contains(currency)
              ? [currency, ...this.currencies]
              : this.currencies),
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
      'minimum_balance': minimumBalance,
      'opening_balance': openingBalance,
      'currency': currency,
      'currencies': jsonEncode(currencies),
      'icon_key': iconKey,
      'color_value': colorValue,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    final baseCurrency = (map['currency'] as String?) ?? '\$';
    List<String> currenciesList = [];
    final rawCurrencies = map['currencies'];
    if (rawCurrencies is String && rawCurrencies.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawCurrencies);
        if (decoded is List) {
          currenciesList = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }
    if (currenciesList.isEmpty) {
      currenciesList = [baseCurrency];
    } else if (!currenciesList.contains(baseCurrency)) {
      currenciesList = [baseCurrency, ...currenciesList];
    }

    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      balance: (map['balance'] as num).toDouble(),
      minimumBalance: (map['minimum_balance'] as num?)?.toDouble() ?? 0,
      openingBalance: (map['opening_balance'] as num?)?.toDouble(),
      currency: baseCurrency,
      currencies: currenciesList,
      iconKey: (map['icon_key'] as String?) ?? 'wallet',
      colorValue: (map['color_value'] as int?) ?? 0xFF00FF9D,
      isArchived: (map['is_archived'] as int?) == 1,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  /// Convierte un monto hacia una moneda objetivo. Por defecto la tasa es 1 a 1 para monedas de la lista.
  double convert(double amount, String targetCurrency, {double rate = 1.0}) {
    if (targetCurrency == currency) return amount;
    return amount * rate;
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
