import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';
import '../../../../data/models/admin_open_bill_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/skeletons/list_item_skeleton.dart';

class AdminOpenBillsTab extends GetView<AdminController> {
  const AdminOpenBillsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Summary Header Card
        _buildSummaryHeader(),

        // 2. Responsive Open Bills Grid / List
        Expanded(
          child: Obx(() {
            if (controller.isLoadingOpenBills.value && controller.openBills.isEmpty) {
              return const ListItemSkeleton();
            }

            if (controller.openBills.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: AppColors.successSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.success),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Semua Meja Telah Lunas',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Tidak ada tagihan meja terbuka (open bill) yang masih gantung saat ini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.secondarySoft,
                          foregroundColor: AppColors.secondary,
                        ),
                        onPressed: () => controller.fetchOpenBills(),
                        icon: const Icon(Icons.refresh_rounded),
                        tooltip: 'Segarkan',
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.secondary,
              onRefresh: () => controller.fetchOpenBills(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 768;

                  if (isTablet) {
                    final crossAxisCount = constraints.maxWidth >= 1200 ? 3 : 2;
                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 135,
                      ),
                      itemCount: controller.openBills.length,
                      itemBuilder: (context, i) {
                        final b = controller.openBills[i];
                        return _buildOpenBillCard(context, b);
                      },
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: controller.openBills.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final b = controller.openBills[i];
                      return _buildOpenBillCard(context, b);
                    },
                  );
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Summary Header
  // ---------------------------------------------------------------------------
  Widget _buildSummaryHeader() {
    return Obx(() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.lightBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.table_restaurant_rounded, color: AppColors.secondary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Meja Aktif (Open Bills)',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${controller.openBillsTotalActive.value} Meja Belum Bayar',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              Container(height: 36, width: 1, color: AppColors.lightBorder),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Total Tagihan Gantung',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CurrencyFormatter.format(controller.openBillsTotalAmount.value),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.warning),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Open Bill Card
  // ---------------------------------------------------------------------------
  Widget _buildOpenBillCard(BuildContext context, AdminOpenBillModel b) {
    final bool isLongWait = b.elapsedMinutes >= 60;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isLongWait ? AppColors.warning.withValues(alpha: 0.5) : AppColors.lightBorder,
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Table Badge
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isLongWait ? AppColors.warningSoft : AppColors.secondarySoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isLongWait ? AppColors.warning.withValues(alpha: 0.4) : AppColors.secondaryLight.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'MEJA',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isLongWait ? AppColors.warning : AppColors.secondary,
                    ),
                  ),
                  Text(
                    b.tableNumber,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isLongWait ? AppColors.warning : AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Bill Meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          b.customerName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                      ),
                      if (b.isSelfOrder) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.secondarySoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Online', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'No. ${b.invoiceNumber} • Kasir: ${b.cashierName}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: isLongWait ? AppColors.warning : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        b.elapsedMinutes > 0 ? '${b.elapsedMinutes} menit lalu' : 'Baru saja',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isLongWait ? FontWeight.bold : FontWeight.normal,
                          color: isLongWait ? Colors.brown.shade800 : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '•  ${b.itemsCount} item',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Total Amount + Status Pill
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  CurrencyFormatter.format(b.total),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'OPEN BILL',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.warning),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
