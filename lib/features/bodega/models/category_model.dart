import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String name;
  final String type; // 'expense' or 'income'
  final String iconKey;
  final int colorValue;
  final bool isDefault;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.colorValue,
    this.isDefault = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon_key': iconKey,
      'color_value': colorValue,
      'is_default': isDefault ? 1 : 0,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      iconKey: map['icon_key'] as String? ?? 'tag',
      colorValue: map['color_value'] as int? ?? 0xFF00FF9D,
      isDefault: (map['is_default'] as int?) == 1,
    );
  }

  /// Maps iconKey to high-fidelity icons (No Emojis!)
  IconData get iconData {
    switch (iconKey) {
      case 'fish':
        return Icons.set_meal_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'home':
        return Icons.fort_rounded;
      case 'game':
        return Icons.sports_esports_rounded;
      case 'potion':
        return Icons.medication_liquid_rounded;
      case 'boss':
        return Icons.warning_amber_rounded;
      case 'energy':
        return Icons.bolt_rounded;
      case 'loot':
        return Icons.shopping_bag_rounded;
      case 'transport':
        return Icons.rocket_launch_rounded;
      case 'quest':
        return Icons.military_tech_rounded;
      case 'gift':
        return Icons.redeem_rounded;
      case 'gem':
        return Icons.diamond_rounded;
      case 'coins':
        return Icons.monetization_on_rounded;
      case 'transfer':
        return Icons.sync_alt_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
