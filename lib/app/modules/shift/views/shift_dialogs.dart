import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/shift_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

import 'package:flutter/services.dart';

class ShiftDialogs {
  /// Modal Buka Shift Kasir (Input Modal Awal)
  static Future<bool> showStartShiftDialog(BuildContext context, {bool dismissible = true}) async {
    final controller = Get.find<ShiftController>();
    final amountController = TextEditingController(text: '100.000');
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: dismissible,
      builder: (dialogContext) => PopScope(
        canPop: dismissible,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lock_open_rounded, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Buka Shift Kasir',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Mulai sesi operasional kasir baru',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (dismissible)
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Masukkan jumlah uang modal awal (uang kembalian) di laci kasir saat ini:',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),

                  // Input Nominal Berformat Rupiah
                  TextFormField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    autofocus: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Modal Awal Kasir',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.payments_rounded, color: AppColors.primary, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Rp',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => amountController.clear(),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Wajib diisi';
                      final num = double.tryParse(val.replaceAll(RegExp(r'[^0-9]'), ''));
                      if (num == null || num < 0) return 'Nominal tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // 4 Tombol Pilihan Nominal Cepat (2 Baris x 2 Kolom - Nyaman & Rapi di HP)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildQuickNominalButton(amountController, 50000)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildQuickNominalButton(amountController, 100000)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildQuickNominalButton(amountController, 200000)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildQuickNominalButton(amountController, 500000)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (dismissible)
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          child: const Text('Batal'),
                        ),
                      const SizedBox(width: 8),
                      Obx(() => ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: controller.isLoading.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: Text(
                              controller.isLoading.value ? 'Membuka...' : 'Buka Shift',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: controller.isLoading.value
                                ? null
                                : () async {
                                    if (formKey.currentState!.validate()) {
                                      final raw = amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
                                      final amount = double.tryParse(raw) ?? 0;
                                      final success = await controller.startShift(amount);
                                      if (success && dialogContext.mounted) {
                                        Navigator.of(dialogContext).pop(true);
                                      }
                                    }
                                  },
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return result ?? false;
  }

  /// Dialog Ringkasan Shift Aktif Kasir
  static Future<void> showShiftSummaryDialog(BuildContext context) async {
    final controller = Get.find<ShiftController>();

    // Jika belum ada shift aktif sama sekali di memori/cache, langsung arahkan ke buka shift
    if (!controller.hasActiveShift.value && controller.currentShift.value == null) {
      await showStartShiftDialog(context);
      return;
    }

    // Trigger update data terbaru di latar belakang (background sync)
    controller.fetchCurrentShift();

    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            final shift = controller.currentShift.value;

            if (shift == null) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 36.0),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(strokeWidth: 2.5),
                      SizedBox(height: 16),
                      Text(
                        'Memuat data shift kasir...',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Dialog
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.query_stats_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ringkasan Shift Kasir',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Detail operasional & perputaran kas',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.success.withAlpha(80)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: AppColors.success),
                          SizedBox(width: 5),
                          Text(
                            'Shift Aktif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Card 1: Info Mulai & Modal Awal
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Column(
                    children: [
                      _buildRow('Mulai Shift', DateFormatter.formatDateTime(shift.startTime)),
                      const Divider(height: 14),
                      _buildRow('Modal Awal', CurrencyFormatter.format(shift.startingCash)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Card 2: Rincian Penjualan
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Column(
                    children: [
                      _buildRow('Penjualan Tunai (Cash)', CurrencyFormatter.format(shift.cashSales)),
                      const SizedBox(height: 6),
                      _buildRow('Penjualan QRIS', CurrencyFormatter.format(shift.qrisSales)),
                      const SizedBox(height: 6),
                      _buildRow('Penjualan Transfer Bank', CurrencyFormatter.format(shift.transferSales)),
                      const Divider(height: 16),
                      _buildRow('Total Omset Penjualan', CurrencyFormatter.format(shift.totalSales), isBold: true),
                      const SizedBox(height: 4),
                      _buildRow(
                        'Total Transaksi Selesai',
                        '${shift.totalTransactions} Transaksi',
                        isBold: true,
                        valueColor: AppColors.primaryDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Card 3: Highlight Kas di Laci Kasir
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withAlpha(90), width: 1.2),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimasi Kas di Laci',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '(Modal Awal + Tunai)',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Text(
                        CurrencyFormatter.format(shift.expectedCash),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Aksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.lock_clock_rounded, size: 18),
                      label: const Text('Tutup Shift', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();
                        if (context.mounted) {
                          await showEndShiftDialog(context);
                        }
                      },
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  /// Modal Tutup Shift Kasir (Input Uang Fisik Riil & Hitung Selisih)
  static Future<bool> showEndShiftDialog(BuildContext context) async {
    final controller = Get.find<ShiftController>();

    // Pastikan ada data shift aktif
    if (controller.currentShift.value == null) {
      await controller.fetchCurrentShift();
      if (!context.mounted) return false;
    }

    final shift = controller.currentShift.value;
    if (shift == null) {
      AppSnackbar.info('Informasi', 'Tidak ada shift aktif untuk ditutup.');
      return false;
    }

    // Default pre-fill dengan uang kas yang seharusnya agar langsung "Pas"
    final initialCashInt = shift.expectedCash.toInt();
    final cashController = TextEditingController(
      text: initialCashInt > 0 ? CurrencyFormatter.formatWithoutSymbol(initialCashInt) : '',
    );
    final RxDouble actualCash = shift.expectedCash.obs;
    final RxBool hasInput = (initialCashInt > 0).obs;
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warningSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lock_clock_rounded, color: AppColors.warning, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tutup Shift Kasir',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Hitung fisik uang tunai di laci kasir',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Info Card Shift
                  Obx(() {
                    final current = controller.currentShift.value ?? shift;
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withAlpha(60)),
                      ),
                      child: Column(
                        children: [
                          _buildRow('Mulai Shift', DateFormatter.formatDateTime(current.startTime)),
                          const Divider(height: 12),
                          _buildRow('Modal Awal', CurrencyFormatter.format(current.startingCash)),
                          _buildRow('Penjualan Tunai', CurrencyFormatter.format(current.cashSales)),
                          _buildRow('Penjualan Non-Tunai', CurrencyFormatter.format(current.qrisSales + current.transferSales)),
                          const Divider(height: 12),
                          _buildRow(
                            'Total Kas Seharusnya',
                            CurrencyFormatter.format(current.expectedCash),
                            isBold: true,
                            valueColor: AppColors.primary,
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 18),

                  const Text(
                    'Uang fisik kasir di laci:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  // Input Uang Fisik Kasir Berformat Rupiah
                  TextFormField(
                    controller: cashController,
                    keyboardType: TextInputType.number,
                    autofocus: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Uang Fisik Kasir',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.payments_rounded, color: AppColors.warning, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Rp',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          cashController.clear();
                          actualCash.value = 0;
                          hasInput.value = false;
                        },
                      ),
                    ),
                    onChanged: (val) {
                      final raw = val.replaceAll(RegExp(r'[^0-9]'), '');
                      if (raw.isEmpty) {
                        actualCash.value = 0;
                        hasInput.value = false;
                      } else {
                        actualCash.value = double.tryParse(raw) ?? 0;
                        hasInput.value = true;
                      }
                    },
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Wajib mengisi uang fisik kasir';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),

                  // Tombol Cepat: Uang Pas Sesuai Sistem (Sama Rata)
                  Obx(() {
                    final current = controller.currentShift.value ?? shift;
                    return Material(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          final amt = current.expectedCash.toInt();
                          cashController.text = CurrencyFormatter.formatWithoutSymbol(amt);
                          actualCash.value = current.expectedCash;
                          hasInput.value = true;
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.primary.withAlpha(60)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Set Uang Pas: ${CurrencyFormatter.format(current.expectedCash)}',
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),

                  // 4 Tombol Pilihan Nominal Cepat (2 Baris x 2 Kolom)
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildQuickCashButton(cashController, actualCash, hasInput, 50000)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildQuickCashButton(cashController, actualCash, hasInput, 100000)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildQuickCashButton(cashController, actualCash, hasInput, 200000)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildQuickCashButton(cashController, actualCash, hasInput, 500000)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Selisih Kas Live Preview
                  Obx(() {
                    final current = controller.currentShift.value ?? shift;

                    if (!hasInput.value) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.infoSoft,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.info.withAlpha(60)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: AppColors.info),
                            SizedBox(width: 8),
                            Text(
                              'Masukkan nominal fisik untuk menghitung selisih',
                              style: TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }

                    final diff = actualCash.value - current.expectedCash;
                    Color diffColor = AppColors.success;
                    String statusText = 'Pas (Sesuai)';

                    if (diff > 0) {
                      diffColor = AppColors.info;
                      statusText = 'Lebih (+${CurrencyFormatter.format(diff)})';
                    } else if (diff < 0) {
                      diffColor = AppColors.danger;
                      statusText = 'Kurang (${CurrencyFormatter.format(diff)})';
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: diffColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: diffColor.withAlpha(102)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status Selisih Kas:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            statusText,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: diffColor),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Kasir (Opsional)',
                      hintText: 'Misal: Selisih karena pembulatan diskon',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 8),
                      Obx(() => ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.warning,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: controller.isLoading.value
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.lock_clock_rounded, size: 18),
                            label: Text(
                              controller.isLoading.value ? 'Menutup Shift...' : 'Tutup Shift',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: controller.isLoading.value
                                ? null
                                : () async {
                                    if (formKey.currentState!.validate()) {
                                      final raw = cashController.text.replaceAll(RegExp(r'[^0-9]'), '');
                                      final amount = double.tryParse(raw) ?? 0;
                                      final notes = notesController.text.trim();
                                      
                                      // Tutup dialog shift terlebih dahulu agar tidak menumpuk di layar
                                      if (dialogContext.mounted) {
                                        Navigator.of(dialogContext).pop(true);
                                      }
                                      
                                      await controller.endShift(amount, notes);
                                    }
                                  },
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return result ?? false;
  }

  static Widget _buildRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: valueColor ?? (isBold ? AppColors.textPrimary : AppColors.textSecondary),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildQuickNominalButton(TextEditingController controller, int amt) {
    final formattedVal = CurrencyFormatter.formatWithoutSymbol(amt);
    return Material(
      color: AppColors.primarySoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => controller.text = formattedVal,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withAlpha(60), width: 1.2),
          ),
          alignment: Alignment.center,
          child: Text(
            CurrencyFormatter.format(amt),
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildQuickCashButton(
    TextEditingController controller,
    RxDouble actualCash,
    RxBool hasInput,
    int amt,
  ) {
    final formattedVal = CurrencyFormatter.formatWithoutSymbol(amt);
    return Material(
      color: AppColors.lightBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          controller.text = formattedVal;
          actualCash.value = amt.toDouble();
          hasInput.value = true;
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.lightBorder, width: 1.2),
          ),
          alignment: Alignment.center,
          child: Text(
            CurrencyFormatter.format(amt),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
