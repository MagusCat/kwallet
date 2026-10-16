import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_service.dart';
import '../../../core/theme/kwall_theme.dart';
import '../../../core/widgets/game_hud_widgets.dart';
import '../models/category_model.dart';

class CategoriesSheet extends StatefulWidget {
  final String type; // 'expense' or 'income'

  const CategoriesSheet({super.key, this.type = 'expense'});

  @override
  State<CategoriesSheet> createState() => _CategoriesSheetState();
}

class _CategoriesSheetState extends State<CategoriesSheet> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedIconKey = 'food';
  int _selectedColor = 0xFF10B981;
  late String _currentType;

  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  final List<Map<String, dynamic>> _availableIcons = [
    {'key': 'food', 'icon': Icons.restaurant_rounded, 'label': 'Comida'},
    {'key': 'home', 'icon': Icons.home_rounded, 'label': 'Hogar'},
    {'key': 'transport', 'icon': Icons.directions_car_rounded, 'label': 'Transporte'},
    {'key': 'game', 'icon': Icons.sports_esports_rounded, 'label': 'Ocio'},
    {'key': 'potion', 'icon': Icons.medical_services_rounded, 'label': 'Salud'},
    {'key': 'loot', 'icon': Icons.shopping_bag_rounded, 'label': 'Compras'},
    {'key': 'energy', 'icon': Icons.bolt_rounded, 'label': 'Servicios'},
    {'key': 'fish', 'icon': Icons.pets_rounded, 'label': 'Mascotas'},
    {'key': 'quest', 'icon': Icons.work_rounded, 'label': 'Trabajo'},
    {'key': 'gift', 'icon': Icons.card_giftcard_rounded, 'label': 'Regalos'},
    {'key': 'gem', 'icon': Icons.savings_rounded, 'label': 'Ahorro'},
    {'key': 'boss', 'icon': Icons.warning_rounded, 'label': 'Imprevisto'},
  ];

  final List<int> _availableColors = [
    0xFF10B981, // Emerald
    0xFF3B82F6, // Blue
    0xFF8B5CF6, // Purple
    0xFFEC4899, // Pink
    0xFFF59E0B, // Amber
    0xFF06B6D4, // Cyan
    0xFFF97316, // Orange
    0xFFEF4444, // Red
    0xFF64748B, // Slate
  ];

  @override
  void initState() {
    super.initState();
    _currentType = widget.type;
    _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseService.instance.getCategories(type: _currentType);
    if (mounted) {
      setState(() {
        _categories = cats;
        _isLoading = false;
      });
    }
  }

  Future<void> _addCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un nombre para la categoría')),
      );
      return;
    }

    final newCat = CategoryModel(
      id: const Uuid().v4(),
      name: name,
      type: _currentType,
      iconKey: _selectedIconKey,
      colorValue: _selectedColor,
      isDefault: false,
    );

    await DatabaseService.instance.createCategory(newCat);
    _nameController.clear();
    await _loadCategories();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Categoría "$name" creada'),
          backgroundColor: KwallTheme.surfaceElevated,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KwallTheme.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gestionar Categorías',
                  style: KwallTheme.fontTitle.copyWith(fontSize: 18),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: KwallTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Type Toggle
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: const Center(child: Text('Gastos')),
                    selected: _currentType == 'expense',
                    selectedColor: KwallTheme.accent.withValues(alpha: 0.2),
                    backgroundColor: KwallTheme.surfaceContainer,
                    checkmarkColor: KwallTheme.accent,
                    labelStyle: TextStyle(
                      color: _currentType == 'expense' ? KwallTheme.accent : KwallTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() => _currentType = 'expense');
                      _loadCategories();
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilterChip(
                    label: const Center(child: Text('Ingresos')),
                    selected: _currentType == 'income',
                    selectedColor: KwallTheme.accent.withValues(alpha: 0.2),
                    backgroundColor: KwallTheme.surfaceContainer,
                    checkmarkColor: KwallTheme.accent,
                    labelStyle: TextStyle(
                      color: _currentType == 'income' ? KwallTheme.accent : KwallTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() => _currentType = 'income');
                      _loadCategories();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // New category form
            Text(
              'CREAR NUEVA CATEGORÍA',
              style: KwallTheme.fontBody.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: KwallTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: const TextStyle(color: KwallTheme.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Ej. Gimnasio, Libros, Streaming...',
                      hintStyle: TextStyle(color: KwallTheme.textMuted, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ExpressiveButton(
                  onPressed: _addCategory,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: const Icon(Icons.add_rounded, color: Colors.black),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Icon Picker
            Text(
              'Icono',
              style: KwallTheme.fontBody.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: KwallTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _availableIcons.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final item = _availableIcons[i];
                  final isSelected = _selectedIconKey == item['key'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIconKey = item['key'] as String),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? KwallTheme.accent.withValues(alpha: 0.2) : KwallTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? KwallTheme.accent : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        item['icon'] as IconData,
                        size: 20,
                        color: isSelected ? KwallTheme.accent : KwallTheme.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),

            // Color Picker
            Text(
              'Color',
              style: KwallTheme.fontBody.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: KwallTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _availableColors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final c = _availableColors[i];
                  final isSelected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 2.5)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Existing categories list
            Text(
              'CATEGORÍAS EXISTENTES (${_categories.length})',
              style: KwallTheme.fontBody.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: KwallTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  return Chip(
                    avatar: Icon(cat.iconData, size: 16, color: Color(cat.colorValue)),
                    label: Text(
                      cat.name,
                      style: const TextStyle(fontSize: 12, color: KwallTheme.textPrimary),
                    ),
                    backgroundColor: KwallTheme.surfaceContainer,
                    side: const BorderSide(color: KwallTheme.border),
                    deleteIcon: cat.isDefault
                        ? null
                        : const Icon(Icons.close_rounded, size: 14, color: KwallTheme.textMuted),
                    onDeleted: cat.isDefault
                        ? null
                        : () async {
                            await DatabaseService.instance.deleteCategory(cat.id);
                            await _loadCategories();
                          },
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
