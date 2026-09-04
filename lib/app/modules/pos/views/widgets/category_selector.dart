import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/pos_controller.dart';
import '../../../../core/theme/app_colors.dart';

class CategorySelector extends GetView<PosController> {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedId = controller.selectedCategoryId.value;
      final totalAllProducts = controller.products.length;

      return SizedBox(
        height: 44,
        child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // "Semua Menu" Pill
            _buildCategoryChip(
              id: 0,
              label: 'Semua Menu',
              count: totalAllProducts,
              isSelected: selectedId == 0,
              icon: Icons.grid_view_rounded,
            ),
            const SizedBox(width: 8),

            // Dynamic categories from backend
            ...controller.categories.map((cat) {
              final isSelected = selectedId == cat.id;
              final categoryItemCount = controller.products
                  .where((p) => p.categoryId == cat.id)
                  .length;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildCategoryChip(
                  id: cat.id,
                  label: cat.name,
                  count: categoryItemCount,
                  isSelected: isSelected,
                  icon: _getCategoryIcon(cat.name),
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildCategoryChip({
    required int id,
    required String label,
    required int count,
    required bool isSelected,
    required IconData icon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [AppColors.primaryLight, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isSelected ? null : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSelected ? AppColors.primaryDark.withAlpha(120) : AppColors.lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: AppColors.primary.withAlpha(75),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          else
            BoxShadow(
              color: Colors.black.withAlpha(4),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            HapticFeedback.selectionClick();
            controller.selectCategory(id);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withAlpha(60)
                          : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? null
                          : Border.all(color: AppColors.lightBorder, width: 0.8),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Otomatis memilih icon sesuai nama kategori
  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('kopi') || name.contains('coffee') || name.contains('espresso')) {
      return Icons.coffee_rounded;
    } else if (name.contains('teh') || name.contains('tea')) {
      return Icons.emoji_food_beverage_rounded;
    } else if (name.contains('minum') ||
        name.contains('drink') ||
        name.contains('beverage') ||
        name.contains('jus') ||
        name.contains('juice') ||
        name.contains('soda')) {
      return Icons.local_bar_rounded;
    } else if (name.contains('makan') ||
        name.contains('food') ||
        name.contains('nasi') ||
        name.contains('mie') ||
        name.contains('ayam') ||
        name.contains('rice')) {
      return Icons.restaurant_rounded;
    } else if (name.contains('snack') ||
        name.contains('cemil') ||
        name.contains('goreng') ||
        name.contains('finger') ||
        name.contains('bites') ||
        name.contains('kentang')) {
      return Icons.lunch_dining_rounded;
    } else if (name.contains('dessert') ||
        name.contains('cake') ||
        name.contains('kue') ||
        name.contains('roti') ||
        name.contains('pastry') ||
        name.contains('manis') ||
        name.contains('ice cream') ||
        name.contains('es krim')) {
      return Icons.cake_rounded;
    } else if (name.contains('paket') ||
        name.contains('promo') ||
        name.contains('combo') ||
        name.contains('hemat')) {
      return Icons.local_offer_rounded;
    }
    return Icons.category_rounded;
  }
}
