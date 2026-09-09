import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cash_movement_model.dart';
import '../controllers/cash_flow_controller.dart';
import 'cash_movement_dialog.dart';

class ShiftMovementsHistoryDialog {
  /// Buka dialog daftar riwayat mutasi kas pada shift aktif
  static Future<void> show(BuildContext context) async {
    final cashFlowController = Get.isRegistered<CashFlowController>()
        ? Get.find<CashFlowController>()
        : Get.put(CashFlowController());

    // Fetch riwayat mutasi kas terbaru
    cashFlowController.fetchCurrentShiftMovements();

    final isTablet = MediaQuery.of(context).size.width >= 768;

    if (isTablet) {
      await showDialog(
        context: context,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 12,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 700),
            child: _HistoryContent(dialogContext: dialogContext),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
          ),
          child: _HistoryContent(dialogContext: sheetContext, isSheet: true),
        ),
      );
    }
  }
}

class _HistoryContent extends StatelessWidget {
  final BuildContext dialogContext;
  final bool isSheet;

  const _HistoryContent({
    required this.dialogContext,
    this.isSheet = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CashFlowController>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isSheet) ...[
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],

        // Header Dialog
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: const Icon(
                  Icons.history_edu_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Arus Kas Shift',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Semua pencatatan kas masuk & kas keluar shift saat ini',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Segarkan',
                icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.textSecondary),
                onPressed: () => controller.fetchCurrentShiftMovements(),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.lightBorder),

        // Summary Bar (Total Masuk vs Total Keluar)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Obx(() {
            final double inVal = controller.currentTotalIn.value;
            final double outVal = controller.currentTotalOut.value;
            final double netVal = inVal - outVal;

            return Row(
              children: [
                // Card Masuk
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withAlpha(50)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Kas Masuk',
                          style: TextStyle(fontSize: 10.5, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '+${CurrencyFormatter.format(inVal)}',
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Card Keluar
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft.withAlpha(80),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withAlpha(60)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Kas Keluar',
                          style: TextStyle(fontSize: 10.5, color: AppColors.danger, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '-${CurrencyFormatter.format(outVal)}',
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.danger),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Card Net
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dampak Laci',
                          style: TextStyle(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            netVal >= 0 ? '+${CurrencyFormatter.format(netVal)}' : '-${CurrencyFormatter.format(netVal.abs())}',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: netVal >= 0 ? AppColors.textPrimary : AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ),

        // List Mutasi Scrollable
        Expanded(
          child: Obx(() {
            if (controller.isLoadingMovements.value) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(strokeWidth: 2.5),
                    SizedBox(height: 12),
                    Text('Memuat riwayat kas...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              );
            }

            final items = controller.currentMovements;
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.receipt_outlined, size: 36, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Belum Ada Mutasi Kas',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pencatatan pengeluaran atau kas masuk pada shift ini akan tampil di sini.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Catat Arus Kas Sekarang', style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          CashMovementDialog.show(dialogContext);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildMovementItem(context, item, controller);
              },
            );
          }),
        ),

        // Footer Quick Add
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.lightBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: AppColors.danger),
                    foregroundColor: AppColors.danger,
                  ),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                  label: const Text('Kas Keluar (Petty)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await CashMovementDialog.show(dialogContext, initialType: 'out');
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                  label: const Text('Kas Masuk (In)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    await CashMovementDialog.show(dialogContext, initialType: 'in');
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMovementItem(BuildContext context, CashMovementModel item, CashFlowController controller) {
    final isOut = item.isOut;
    final color = isOut ? AppColors.danger : AppColors.primary;
    final bgColor = isOut ? AppColors.dangerSoft.withAlpha(60) : AppColors.primarySoft.withAlpha(70);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Avatar
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOut ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),

          // Detail Keterangan
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        item.categoryName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      isOut ? '-${CurrencyFormatter.format(item.amount)}' : '+${CurrencyFormatter.format(item.amount)}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  item.notes,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      item.movementDateFormatted ?? item.movementNumber,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    const SizedBox(width: 6),
                    Text(
                      item.cashierName,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action: Cetak Slip & Preview Gambar
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.hasReceiptImage)
                IconButton(
                  tooltip: 'Lihat Foto Nota',
                  icon: const Icon(Icons.image_outlined, size: 18, color: AppColors.primary),
                  onPressed: () => _showReceiptImagePreview(context, item),
                ),
              IconButton(
                tooltip: 'Cetak Ulang Bukti',
                icon: const Icon(Icons.print_outlined, size: 18, color: AppColors.textSecondary),
                onPressed: () => controller.reprintMovementSlip(item.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReceiptImagePreview(BuildContext context, CashMovementModel item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Bukti Nota: ${item.categoryName}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  item.receiptImageUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(24),
                    color: Colors.grey.shade100,
                    child: const Center(
                      child: Text('Gagal memuat gambar bukti nota.', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                item.notes,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
