import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

class MenuSalesMetricsStrip extends GetView<AdminController> {
  const MenuSalesMetricsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final summary = controller.menuSalesSummary.value;
      final topCategory = controller.menuSalesCategories.isNotEmpty
          ? controller.menuSalesCategories.first
          : null;

      return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;
            if (isNarrow) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMetricCard(
                      width: 165,
                      label: 'Total Porsi Terjual',
                      value: '${summary.totalQuantitySold} Porsi',
                      icon: Icons.restaurant_menu_rounded,
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 195,
                      label: 'Menu Terlaris #1',
                      value: summary.topSellingProduct?.name ?? '-',
                      subtext: summary.topSellingProduct != null
                          ? '${summary.topSellingProduct!.quantitySold} porsi terjual'
                          : 'Belum ada data',
                      icon: Icons.emoji_events_rounded,
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 165,
                      label: 'Varian Menu Aktif',
                      value: '${summary.totalUniqueItemsSold} Menu',
                      icon: Icons.fastfood_rounded,
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 190,
                      label: 'Kategori Terfavorit',
                      value: topCategory != null ? topCategory.categoryName : '-',
                      subtext: topCategory != null
                          ? '${topCategory.revenueSharePercentage}% kontribusi'
                          : 'Belum ada data',
                      icon: Icons.category_rounded,
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: 'Total Porsi Terjual',
                    value: '${summary.totalQuantitySold} Porsi',
                    icon: Icons.restaurant_menu_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Menu Terlaris #1',
                    value: summary.topSellingProduct?.name ?? '-',
                    subtext: summary.topSellingProduct != null
                        ? '${summary.topSellingProduct!.quantitySold} porsi terjual'
                        : 'Belum ada data',
                    icon: Icons.emoji_events_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Varian Menu Aktif',
                    value: '${summary.totalUniqueItemsSold} Menu',
                    icon: Icons.fastfood_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Kategori Terfavorit',
                    value: topCategory != null ? topCategory.categoryName : '-',
                    subtext: topCategory != null
                        ? '${topCategory.revenueSharePercentage}% kontribusi'
                        : 'Belum ada data',
                    icon: Icons.category_rounded,
                  ),
                ),
              ],
            );
          },
        ),
      );
    });
  }

  Widget _buildMetricCard({
    double? width,
    required String label,
    required String value,
    String? subtext,
    required IconData icon,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondarySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: AppColors.secondary,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (subtext != null && subtext.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtext,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
