import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import '../products/admin_product_form_dialog.dart';

class HppHealthBanner extends StatelessWidget {
  final AdminController controller;

  const HppHealthBanner({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Obx(() {
      final summary = controller.hppSummary.value;
      final isHealthy = summary.isMarginHealthy;
      final avgMargin = summary.averageMarginPercent;
      final avgFoodCost = summary.averageFoodCostPercent;
      final lowCount = summary.lowMarginCount;
      final lowProducts = summary.lowMarginProducts;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Metrics Strip
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;

                if (isNarrow) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildKpiCard(
                          title: 'Rata-rata Margin Cafe',
                          value: '${avgMargin.toStringAsFixed(1)}%',
                          subtitle: isHealthy ? 'Margin Sehat (Target >= 50%)' : 'Di Bawah Target (< 50%)',
                          icon: Icons.pie_chart_rounded,
                          color: isHealthy ? AppColors.primary : AppColors.warning,
                          bgColor: isHealthy ? AppColors.primarySoft : AppColors.warningSoft,
                        ),
                        const SizedBox(width: 10),
                        _buildKpiCard(
                          title: 'Rata-rata Food Cost',
                          value: '${avgFoodCost.toStringAsFixed(1)}%',
                          subtitle: 'Persentase biaya bahan baku',
                          icon: Icons.kitchen_rounded,
                          color: AppColors.secondary,
                          bgColor: AppColors.secondarySoft,
                        ),
                        const SizedBox(width: 10),
                        _buildKpiCard(
                          title: 'Menu Margin Kritis',
                          value: '$lowCount Menu',
                          subtitle: lowCount > 0 ? 'Margin di bawah 35%' : 'Seluruh menu aman',
                          icon: Icons.warning_amber_rounded,
                          color: lowCount > 0 ? AppColors.danger : AppColors.primary,
                          bgColor: lowCount > 0 ? AppColors.dangerSoft : AppColors.primarySoft,
                        ),
                        const SizedBox(width: 10),
                        _buildKpiCard(
                          title: 'Total Menu Aktif',
                          value: '${summary.totalActiveProducts} Menu',
                          subtitle: 'Produk yang terpantau HPP',
                          icon: Icons.checklist_rounded,
                          color: const Color(0xFF0D9488),
                          bgColor: const Color(0xFFCCFBF1),
                        ),
                      ],
                    ),
                  );
                }

                return Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Rata-rata Margin Cafe',
                        value: '${avgMargin.toStringAsFixed(1)}%',
                        subtitle: isHealthy ? 'Margin Sehat (>= 50%)' : 'Perlu Perhatian (< 50%)',
                        icon: Icons.pie_chart_rounded,
                        color: isHealthy ? AppColors.primary : AppColors.warning,
                        bgColor: isHealthy ? AppColors.primarySoft : AppColors.warningSoft,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Rata-rata Food Cost',
                        value: '${avgFoodCost.toStringAsFixed(1)}%',
                        subtitle: 'Persentase biaya bahan baku',
                        icon: Icons.kitchen_rounded,
                        color: AppColors.secondary,
                        bgColor: AppColors.secondarySoft,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Menu Margin Kritis',
                        value: '$lowCount Menu',
                        subtitle: lowCount > 0 ? 'Margin di bawah 35%' : 'Seluruh menu aman',
                        icon: Icons.warning_amber_rounded,
                        color: lowCount > 0 ? AppColors.danger : AppColors.primary,
                        bgColor: lowCount > 0 ? AppColors.dangerSoft : AppColors.primarySoft,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildKpiCard(
                        title: 'Total Menu Aktif',
                        value: '${summary.totalActiveProducts} Menu',
                        subtitle: 'Produk yang terpantau HPP',
                        icon: Icons.checklist_rounded,
                        color: const Color(0xFF0D9488),
                        bgColor: const Color(0xFFCCFBF1),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Row 2: Low Margin Products Warning Strip (if any exists)
            if (lowProducts.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notification_important_rounded, color: AppColors.danger, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Peringatan Menu Margin Kritis (< 35%)',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.danger),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Menu-menu berikut memiliki margin keuntungan tipis yang berisiko tergerus kenaikan harga bahan. Disarankan menaikkan harga jual atau optimasi gramasi resep:',
                      style: TextStyle(fontSize: 11, color: Color(0xFF7F1D1D)),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: lowProducts.map((item) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFECACA)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                    Text(
                                      'Jual: ${currencyFormat.format(item.price)} • HPP: ${currencyFormat.format(item.hargaBeli)}',
                                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.dangerSoft,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${item.marginPercent.toStringAsFixed(1)}%',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.danger),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: () {
                                    final found = controller.products.firstWhereOrNull((p) => p.id == item.id);
                                    if (found != null) {
                                      AdminProductFormDialog.show(context, product: found);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: const Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.edit_rounded, size: 14, color: Color(0xFF475569)),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 165),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
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
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.9),
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
