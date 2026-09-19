import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

class IngredientMetricsStrip extends StatelessWidget {
  final AdminController controller;

  const IngredientMetricsStrip({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Obx(() {
        final summary = controller.ingredientSummary.value;
        final hasLoadedIngredients = controller.ingredients.isNotEmpty;
        final totalIngredients = hasLoadedIngredients
            ? controller.ingredients.length
            : (summary.totalIngredients > 0 ? summary.totalIngredients : 0);
        final lowStock = hasLoadedIngredients
            ? controller.ingredients.where((i) => i.isLowStock).length
            : summary.lowStockCount;
        final outOfStock = hasLoadedIngredients
            ? controller.ingredients.where((i) => i.isOutOfStock).length
            : summary.outOfStockCount;
        final debtCount = hasLoadedIngredients
            ? controller.ingredients.where((i) => i.isDebtStock).length
            : 0;
        final safeCount = hasLoadedIngredients
            ? controller.ingredients.where((i) => i.isSafe).length
            : summary.safeStockCount;
        final totalValue = hasLoadedIngredients
            ? controller.ingredients.fold(0.0, (sum, i) => sum + i.totalInventoryValue)
            : summary.totalInventoryValue;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 650;

            final card1 = _buildMetricCard(
              label: 'Valuasi Inventaris',
              value: CurrencyFormatter.format(totalValue),
              subtitle: 'Total aset bahan baku',
              icon: Icons.account_balance_wallet_outlined,
              color: const Color(0xFF4F46E5),
              bgColor: const Color(0xFFEEF2FF),
              cardWidth: isNarrow ? 195 : null,
            );

            final card2 = _buildMetricCard(
              label: 'Total Bahan Baku',
              value: '$totalIngredients Item',
              subtitle: '$safeCount stok dalam batas aman',
              icon: Icons.inventory_2_outlined,
              color: const Color(0xFF334155),
              bgColor: const Color(0xFFF1F5F9),
              cardWidth: isNarrow ? 195 : null,
            );

            final card3 = _buildMetricCard(
              label: 'Stok Menipis',
              value: '$lowStock Bahan',
              subtitle: lowStock > 0 ? 'Perlu segera restock' : 'Semua stok tercukupi',
              icon: lowStock > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
              color: lowStock > 0 ? const Color(0xFFD97706) : const Color(0xFF059669),
              bgColor: lowStock > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
              cardWidth: isNarrow ? 195 : null,
            );

            final card4 = _buildMetricCard(
              label: debtCount > 0 ? 'Hutang / Habis' : 'Stok Habis',
              value: '$outOfStock Bahan',
              subtitle: debtCount > 0
                  ? '$debtCount bahan hutang restock'
                  : (outOfStock > 0 ? 'Habis / out of stock' : 'Tidak ada bahan habis'),
              icon: debtCount > 0
                  ? Icons.assignment_late_outlined
                  : (outOfStock > 0 ? Icons.error_outline_rounded : Icons.verified_outlined),
              color: outOfStock > 0 ? AppColors.danger : const Color(0xFF059669),
              bgColor: outOfStock > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
              cardWidth: isNarrow ? 195 : null,
            );

            if (isNarrow) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    card1,
                    const SizedBox(width: 10),
                    card2,
                    const SizedBox(width: 10),
                    card3,
                    const SizedBox(width: 10),
                    card4,
                  ],
                ),
              );
            }

            return Row(
              children: [
                Expanded(child: card1),
                const SizedBox(width: 10),
                Expanded(child: card2),
                const SizedBox(width: 10),
                Expanded(child: card3),
                const SizedBox(width: 10),
                Expanded(child: card4),
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
