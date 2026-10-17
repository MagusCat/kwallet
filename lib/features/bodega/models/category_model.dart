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
}
