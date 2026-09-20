import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import 'product_skeleton.dart';

class ProductMetricsStrip extends StatelessWidget {
  final AdminController controller;

  const ProductMetricsStrip({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Obx(() {
        if (controller.isLoadingProducts.value && controller.products.isEmpty) {
          return const ProductMetricsSkeleton();
        }

        final totalActive = controller.products.where((p) => p.isActive).length;
        final totalCategories = controller.productCategories.length;

        double totalMargin = 0;
        int withMarginCount = 0;
        int lowMarginCount = 0;

        for (final p in controller.products) {
          if (p.price > 0 && p.isActive) {
            totalMargin += p.marginPercent;
            withMarginCount++;
            if (p.marginPercent < 35.0) {
              lowMarginCount++;
            }
          }
        }

        final avgMargin = withMarginCount > 0 ? (totalMargin / withMarginCount) : 0.0;
        final isMarginHealthy = avgMargin >= 45.0;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;

            if (isNarrow) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildMetricCard(
                      label: 'Menu Aktif',
                      value: '$totalActive Produk',
                      subtitle: 'Dari total ${controller.totalProductCount.value > 0 ? controller.totalProductCount.value : controller.products.length} menu',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF334155),
                      bgColor: const Color(0xFFF1F5F9),
                      cardWidth: 195,
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      label: 'Rata-rata Margin',
                      value: '${avgMargin.toStringAsFixed(1)}%',
                      subtitle: isMarginHealthy ? 'Sangat Sehat (>= 45%)' : 'Perlu Evaluasi (< 45%)',
                      icon: Icons.trending_up_rounded,
                      color: isMarginHealthy ? const Color(0xFF059669) : const Color(0xFFD97706),
                      bgColor: isMarginHealthy ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                      cardWidth: 195,
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      label: 'Margin Tipis (<35%)',
                      value: '$lowMarginCount Menu',
                      subtitle: lowMarginCount == 0 ? 'Semua menu sehat' : 'Perlu penyesuaian harga',
                      icon: lowMarginCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                      color: lowMarginCount > 0 ? AppColors.danger : const Color(0xFF059669),
                      bgColor: lowMarginCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                      cardWidth: 195,
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      label: 'Kategori Menu',
                      value: '$totalCategories Kategori',
                      subtitle: 'Klasifikasi produk cafe',
                      icon: Icons.category_outlined,
                      color: const Color(0xFF334155),
                      bgColor: const Color(0xFFF1F5F9),
                      cardWidth: 195,
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: 'Menu Aktif',
                    value: '$totalActive Produk',
                    subtitle: 'Dari ${controller.totalProductCount.value > 0 ? controller.totalProductCount.value : controller.products.length} total menu',
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF334155),
                    bgColor: const Color(0xFFF1F5F9),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Rata-rata Margin',
                    value: '${avgMargin.toStringAsFixed(1)}%',
                    subtitle: isMarginHealthy ? 'Sangat Sehat (>= 45%)' : 'Perlu Evaluasi (< 45%)',
                    icon: Icons.trending_up_rounded,
                    color: isMarginHealthy ? const Color(0xFF059669) : const Color(0xFFD97706),
                    bgColor: isMarginHealthy ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Margin Tipis (<35%)',
                    value: '$lowMarginCount Menu',
                    subtitle: lowMarginCount == 0 ? 'Semua menu sehat' : 'Perlu penyesuaian harga',
                    icon: lowMarginCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                    color: lowMarginCount > 0 ? AppColors.danger : const Color(0xFF059669),
                    bgColor: lowMarginCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Kategori Menu',
                    value: '$totalCategories Kategori',
                    subtitle: 'Klasifikasi produk cafe',
                    icon: Icons.category_outlined,
                    color: const Color(0xFF334155),
                    bgColor: const Color(0xFFF1F5F9),
                  ),
                ),
              ],
            );
          },
        );
      }),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
    double? cardWidth,
  }) {
    return Container(
      width: cardWidth,
      constraints: cardWidth == null ? const BoxConstraints(minWidth: 165) : null,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color == AppColors.danger ? AppColors.danger : const Color(0xFF94A3B8),
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
