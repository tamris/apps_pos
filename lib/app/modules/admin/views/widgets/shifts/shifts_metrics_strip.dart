import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

class ShiftsMetricsStrip extends StatelessWidget {
  final AdminController controller;

  const ShiftsMetricsStrip({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final list = controller.shifts;
      final totalShifts = list.length;
      final activeShifts = list.where((s) => s.isOpen).length;
      final totalCashierSales = list.fold<double>(0.0, (sum, s) => sum + s.totalSales);
      final discrepancyCount = list.where((s) => !s.isOpen && (s.isShortage || s.isOverage)).length;

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
                      width: 170,
                      label: 'Total Shift',
                      value: '$totalShifts Sesi',
                      subtext: 'Rekaman audit kasir',
                      icon: Icons.assignment_rounded,
                      iconColor: AppColors.secondary,
                      iconBg: const Color(0xFFEEF2FF),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 185,
                      label: 'Total Omzet Kasir',
                      value: CurrencyFormatter.format(totalCashierSales),
                      subtext: 'Akumulasi penjualan',
                      icon: Icons.payments_rounded,
                      iconColor: const Color(0xFF10B981),
                      iconBg: const Color(0xFFECFDF5),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 170,
                      label: 'Shift Aktif',
                      value: '$activeShifts Kasir',
                      subtext: activeShifts > 0 ? 'Laci kasir buka' : 'Tidak ada shift aktif',
                      icon: Icons.storefront_rounded,
                      iconColor: const Color(0xFF0EA5E9),
                      iconBg: const Color(0xFFF0F9FF),
                    ),
                    const SizedBox(width: 10),
                    _buildMetricCard(
                      width: 180,
                      label: 'Audit Arus Kas',
                      value: discrepancyCount > 0 ? '$discrepancyCount Ada Selisih' : 'Kas 100% Pas',
                      subtext: discrepancyCount > 0 ? 'Periksa selisih fisik' : 'Semua laci sesuai',
                      icon: discrepancyCount > 0 ? Icons.warning_amber_rounded : Icons.verified_rounded,
                      iconColor: discrepancyCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                      iconBg: discrepancyCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    label: 'Total Shift',
                    value: '$totalShifts Sesi',
                    subtext: 'Rekaman audit kasir',
                    icon: Icons.assignment_rounded,
                    iconColor: AppColors.secondary,
                    iconBg: const Color(0xFFEEF2FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Total Omzet Kasir',
                    value: CurrencyFormatter.format(totalCashierSales),
                    subtext: 'Akumulasi penjualan',
                    icon: Icons.payments_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFFECFDF5),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Shift Aktif',
                    value: '$activeShifts Kasir',
                    subtext: activeShifts > 0 ? 'Laci kasir buka' : 'Tidak ada shift aktif',
                    icon: Icons.storefront_rounded,
                    iconColor: const Color(0xFF0EA5E9),
                    iconBg: const Color(0xFFF0F9FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    label: 'Audit Arus Kas',
                    value: discrepancyCount > 0 ? '$discrepancyCount Ada Selisih' : 'Kas 100% Pas',
                    subtext: discrepancyCount > 0 ? 'Periksa selisih fisik' : 'Semua laci sesuai',
                    icon: discrepancyCount > 0 ? Icons.warning_amber_rounded : Icons.verified_rounded,
                    iconColor: discrepancyCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
                    iconBg: discrepancyCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
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
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                Text(
                  subtext,
                  style: const TextStyle(
                    fontSize: 9.5,
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
