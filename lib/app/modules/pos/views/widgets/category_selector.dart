import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/pos_controller.dart';
import '../../../../core/theme/app_colors.dart';

class CategorySelector extends GetView<PosController> {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selectedId = controller.selectedCategoryId.value;

      return SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // "Semua" Pill
            _buildCategoryChip(
              id: 0,
              label: 'Semua Menu',
              isSelected: selectedId == 0,
              icon: Icons.restaurant_menu_rounded,
            ),
            const SizedBox(width: 8),

            // Dynamic categories from backend
            ...controller.categories.map((cat) {
              final isSelected = selectedId == cat.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: _buildCategoryChip(
                  id: cat.id,
                  label: cat.name,
                  isSelected: isSelected,
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
    required bool isSelected,
    IconData? icon,
  }) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => controller.selectCategory(id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.lightBorder,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
