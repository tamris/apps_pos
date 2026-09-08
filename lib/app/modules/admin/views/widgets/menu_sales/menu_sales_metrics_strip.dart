import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
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
                      width: 175,
                      label: 'Total Porsi Terjual',
                      value: '${summary.totalQuantitySold} Porsi',
                      subtext: 'Akumulasi porsi terjual',
                      icon: Icons.restaurant_menu_rounded,
                      iconColor: const Color(0xFF4F46E5),
                      iconBg: const Color(0xFFEEF2FF),
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
                      iconColor: const Color(0xFFD97706),
                      iconBg: const Color(0xFFFEF3C7),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 175,
                      label: 'Varian Menu Aktif',
                      value: '${summary.totalUniqueItemsSold} Menu',
                      subtext: 'Varian menu aktif terjual',
                      icon: Icons.fastfood_rounded,
                      iconColor: const Color(0xFF0284C7),
                      iconBg: const Color(0xFFF0F9FF),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 190,
                      label: 'Kategori Terfavorit',
                      value:
                          topCategory != null ? topCategory.categoryName : '-',
                      subtext: topCategory != null
                          ? '${topCategory.revenueSharePercentage}% kontribusi'
                          : 'Belum ada data',
                      icon: Icons.category_rounded,
                      iconColor: const Color(0xFF059669),
                      iconBg: const Color(0xFFECFDF5),
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
                    subtext: 'Akumulasi porsi terjual',
                    icon: Icons.restaurant_menu_rounded,
                    iconColor: const Color(0xFF4F46E5),
                    iconBg: const Color(0xFFEEF2FF),
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
                    iconColor: const Color(0xFFD97706),
                    iconBg: const Color(0xFFFEF3C7),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Varian Menu Aktif',
                    value: '${summary.totalUniqueItemsSold} Menu',
                    subtext: 'Varian menu aktif terjual',
                    icon: Icons.fastfood_rounded,
                    iconColor: const Color(0xFF0284C7),
                    iconBg: const Color(0xFFF0F9FF),
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
                    iconColor: const Color(0xFF059669),
                    iconBg: const Color(0xFFECFDF5),
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
    required String subtext,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
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
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Text(
                  subtext,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
