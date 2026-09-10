import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

class OpenBillsEmptyState extends StatelessWidget {
  final AdminController controller;

  const OpenBillsEmptyState({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mode = controller.selectedActiveOrderMode.value;
      final hasSearchOrFilter = controller.openBillSearchQuery.value.isNotEmpty ||
          controller.selectedOpenBillFilter.value != 'all';

      if (hasSearchOrFilter) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.search_off_rounded,
                            size: 26,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Tidak Ada Meja Ditemukan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tidak ada tagihan atau pesanan yang cocok dengan filter atau kata kunci pencarian Anda.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondary,
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: () {
                            controller.openBillSearchQuery.value = '';
                            controller.openBillSearchController.clear();
                            controller.selectedOpenBillFilter.value = 'all';
                          },
                          icon: const Icon(Icons.restart_alt_rounded, size: 16),
                          label: const Text('Reset Filter Meja', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }

      final String emptyTitle = mode == 'online'
          ? 'Tidak Ada Pesanan Online Aktif'
          : 'Semua Meja Telah Lunas';

      final String emptySubtitle = mode == 'online'
          ? 'Saat ini semua pesanan online / self-order telah selesai diproses atau belum ada pesanan baru.'
          : 'Tidak ada tagihan meja aktif (open bill) yang belum diselesaikan saat ini.\nSemua pesanan tamu telah selesai dibayar.';

      return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF059669).withValues(alpha: 0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 32,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        emptyTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        emptySubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.secondary,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onPressed: () => controller.fetchOpenBills(),
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Perbarui Data Meja', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
