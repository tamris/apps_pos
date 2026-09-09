import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/constants/api_constants.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/data/models/cash_movement_model.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

class AdminCashFlowDetailDialog {
  static Future<void> show(BuildContext context, {required CashMovementModel movement}) async {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    if (isTablet) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 12,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 760),
            child: _DetailContent(dialogContext: dialogContext, movement: movement),
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
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.90,
          ),
          child: _DetailContent(dialogContext: sheetContext, movement: movement),
        ),
      );
    }
  }
}

class _DetailContent extends StatelessWidget {
  final BuildContext dialogContext;
  final CashMovementModel movement;

  const _DetailContent({
    required this.dialogContext,
    required this.movement,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();
    final isOut = movement.isOut;
    final accentColor = isOut ? const Color(0xFFDC2626) : const Color(0xFF059669);
    final accentBg = isOut ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5);

    // Full URL for receipt image
    String? imageUrl = movement.receiptImageUrl;
    if (imageUrl == null && movement.receiptImage != null && movement.receiptImage!.isNotEmpty) {
      imageUrl = '${ApiConstants.defaultStorageUrl}/${movement.receiptImage}';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Header (Pinned)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOut ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 13,
                      color: accentColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOut ? 'Kas Keluar' : 'Kas Masuk',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  movement.movementNumber,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
        ),

        // 2. Scrollable Body
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nominal Highlight Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isOut ? 'TOTAL PENGELUARAN' : 'TOTAL KAS MASUK',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: accentColor,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${isOut ? '- ' : '+ '}${CurrencyFormatter.format(movement.amount)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Transaction Detail Rows
                _buildInfoRow('Waktu Transaksi', movement.movementDateFormatted ?? movement.movementDate ?? '-'),
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                _buildInfoRow('Sumber Dana', movement.sourceLabel),
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                _buildInfoRow('Kategori', movement.categoryName),
                const Divider(height: 16, color: Color(0xFFF1F5F9)),
                _buildInfoRow('Petugas / Kasir', movement.cashierName),
                if (movement.shiftId != null) ...[
                  const Divider(height: 16, color: Color(0xFFF1F5F9)),
                  _buildInfoRow('Shift Terkait', 'Shift #${movement.shiftId}'),
                ],
                const Divider(height: 16, color: Color(0xFFF1F5F9)),

                // Keterangan / Notes
                const Text(
                  'Keterangan / Keperluan:',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    movement.notes.isNotEmpty ? movement.notes : 'Tidak ada catatan tambahan.',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A), height: 1.4),
                  ),
                ),
                const SizedBox(height: 16),

                // Bukti Foto Nota
                const Text(
                  'Foto Bukti Nota / Kwitansi:',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 6),
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: GestureDetector(
                      onTap: () => _openImageFullScreen(context, imageUrl!),
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              height: 200,
                              color: const Color(0xFFF1F5F9),
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              height: 120,
                              color: const Color(0xFFF8FAFC),
                              child: const Center(
                                child: Text('Gagal memuat gambar nota', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.all(8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fullscreen_rounded, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Perbesar', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_outlined, size: 28, color: Color(0xFF94A3B8)),
                        SizedBox(height: 6),
                        Text(
                          'Tidak ada foto nota yang dilampirkan',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 3. Footer Actions (Pinned)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                ),
                onPressed: () => _confirmDeleteMovement(context, controller),
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                label: const Text('Hapus Catatan', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1F5F9),
                  foregroundColor: const Color(0xFF334155),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Tutup', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteMovement(BuildContext context, AdminController controller) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Catatan Arus Kas?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus catatan ${movement.movementNumber} sebesar ${CurrencyFormatter.format(movement.amount)}? Tindakan ini akan mengupdate saldo kas terkait.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Catatan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await controller.deleteCashMovement(movement.id);
      if (success && dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
    }
  }

  void _openImageFullScreen(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Tutup',
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
