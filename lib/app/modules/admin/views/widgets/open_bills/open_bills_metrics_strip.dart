import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

class OpenBillsMetricsStrip extends StatelessWidget {
  final AdminController controller;

  const OpenBillsMetricsStrip({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final mode = controller.selectedActiveOrderMode.value;
      final list = controller.openBills;

      // When mode is Online
      if (mode == 'online') {
        final onlineList = controller.activeOnlineOrders;
        final unpaidList = onlineList.where((b) => !b.isPaid).toList();
        final unpaidAmount = unpaidList.fold<double>(0.0, (acc, b) => acc + b.total);
        final cookingCount = onlineList.where((b) => b.status.toLowerCase() == 'processing' || b.status.toLowerCase() == 'cooking').length;
        final readyCount = onlineList.where((b) => b.status.toLowerCase() == 'ready').length;
        final onlineTotal = onlineList.fold<double>(0.0, (acc, b) => acc + b.total);

        return _buildMetricsContainer([
          _buildMetricCard(
            label: 'Pesanan Online',
            value: '${onlineList.length} Pesanan',
            subtext: 'Self-order aktif berjalan',
            icon: Icons.phonelink_ring_rounded,
            iconColor: AppColors.secondary,
            iconBg: const Color(0xFFEEF2FF),
          ),
          _buildMetricCard(
            label: 'Menunggu Bayar',
            value: '${unpaidList.length} Pesanan',
            subtext: CurrencyFormatter.format(unpaidAmount),
            icon: Icons.hourglass_top_rounded,
            iconColor: const Color(0xFFEA580C),
            iconBg: const Color(0xFFFFF7ED),
          ),
          _buildMetricCard(
            label: 'Antrean Dapur',
            value: '$cookingCount Dimasak • $readyCount Siap',
            subtext: 'Proses penyajian pesanan',
            icon: Icons.soup_kitchen_rounded,
            iconColor: const Color(0xFF0284C7),
            iconBg: const Color(0xFFF0F9FF),
          ),
          _buildMetricCard(
            label: 'Total Nilai Online',
            value: CurrencyFormatter.format(onlineTotal),
            subtext: 'Potensi kas self-order',
            icon: Icons.payments_rounded,
            iconColor: const Color(0xFF059669),
            iconBg: const Color(0xFFECFDF5),
          ),
        ]);
      }

      // When mode is Tables (Dine-in)
      if (mode == 'tables') {
        final tableList = controller.activeTableBills;
        final tableTotal = tableList.fold<double>(0.0, (acc, b) => acc + b.total);
        final longStay = tableList.where((b) => b.elapsedMinutes >= 60).length;
        final totalItems = tableList.fold<int>(0, (acc, b) => acc + b.itemsCount);

        return _buildMetricsContainer([
          _buildMetricCard(
            label: 'Meja Belum Lunas',
            value: '${tableList.length} Meja',
            subtext: 'Tamu dine-in aktif',
            icon: Icons.table_restaurant_rounded,
            iconColor: AppColors.secondary,
            iconBg: const Color(0xFFEEF2FF),
          ),
          _buildMetricCard(
            label: 'Tagihan Tertunda',
            value: CurrencyFormatter.format(tableTotal),
            subtext: 'Dibayar sebelum checkout',
            icon: Icons.receipt_long_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
          ),
          _buildMetricCard(
            label: 'Durasi Tamu',
            value: longStay > 0 ? '$longStay Meja > 60m' : 'Semua < 1 Jam',
            subtext: longStay > 0 ? 'Duduk santai / nongkrong' : 'Aktivitas normal',
            icon: Icons.deck_rounded,
            iconColor: const Color(0xFF6366F1),
            iconBg: const Color(0xFFEEF2FF),
          ),
          _buildMetricCard(
            label: 'Menu Dinikmati',
            value: '$totalItems Menu',
            subtext: 'Total porsi tersaji di meja',
            icon: Icons.restaurant_menu_rounded,
            iconColor: const Color(0xFF0D9488),
            iconBg: const Color(0xFFF0FDFA),
          ),
        ]);
      }

      // Default mode == 'all' (Compatible with widget tests)
      final totalActive = controller.openBillsTotalActive.value;
      final totalAmount = controller.openBillsTotalAmount.value;
      final criticalCount = list.where((b) => b.elapsedMinutes >= 60).length;
      final selfOrderCount = list.where((b) => b.isSelfOrder).length;
      final posCount = list.where((b) => !b.isSelfOrder).length;

      return _buildMetricsContainer([
        _buildMetricCard(
          label: 'Meja Aktif',
          value: '$totalActive Meja',
          subtext: 'Pesanan belum lunas',
          icon: Icons.table_restaurant_rounded,
          iconColor: AppColors.secondary,
          iconBg: const Color(0xFFEEF2FF),
        ),
        _buildMetricCard(
          label: 'Tagihan Gantung',
          value: CurrencyFormatter.format(totalAmount),
          subtext: 'Potensi kas tertunda',
          icon: Icons.hourglass_top_rounded,
          iconColor: const Color(0xFFD97706),
          iconBg: const Color(0xFFFEF3C7),
        ),
        _buildMetricCard(
          label: 'Perlu Perhatian',
          value: criticalCount > 0 ? '$criticalCount Meja > 60m' : 'Semua < 1 Jam',
          subtext: criticalCount > 0 ? 'Waktu tunggu lama' : 'Pelayanan prima',
          icon: criticalCount > 0 ? Icons.alarm_on_rounded : Icons.check_circle_outline_rounded,
          iconColor: criticalCount > 0 ? const Color(0xFFDC2626) : const Color(0xFF059669),
          iconBg: criticalCount > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
        ),
        _buildMetricCard(
          label: 'Kanal Pesanan',
          value: '$selfOrderCount Online • $posCount POS',
          subtext: 'Komparasi saluran',
          icon: Icons.devices_rounded,
          iconColor: const Color(0xFF0EA5E9),
          iconBg: const Color(0xFFF0F9FF),
        ),
      ]);
    });
  }

  Widget _buildMetricsContainer(List<Widget> cards) {
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
                children: cards.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(width: 175, child: c),
                )).toList(),
              ),
            );
          }

          return Row(
            children: cards.map((c) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: c,
              ),
            )).toList(),
          );
        },
      ),
    );
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
