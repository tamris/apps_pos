import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/shift_controller.dart';
import '../../../data/services/offline_sync_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/providers/api_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import 'cash_movement_dialog.dart';
import 'shift_movements_history_dialog.dart';

import 'package:flutter/services.dart';

class ShiftDialogs {
  /// Modal Buka Shift Kasir (Input Modal Awal)
  static Future<bool> showStartShiftDialog(BuildContext context, {bool dismissible = true}) async {
    // GUARD KUNCI: Cek apakah masih ada shift sebelumnya yang ditutup secara offline dan belum tersinkronisasi
    if (Get.isRegistered<StorageService>()) {
      final storageService = Get.find<StorageService>();
      final closedShifts = storageService.getOfflineClosedShifts();

      if (closedShifts.isNotEmpty) {
        // Coba sinkronisasi kilat di background jika koneksi online
        if (Get.isRegistered<OfflineSyncService>()) {
          final syncService = Get.find<OfflineSyncService>();
          final apiProvider = Get.isRegistered<ApiProvider>() ? Get.find<ApiProvider>() : null;
          final isOnline = (apiProvider?.isOnline.value ?? false) && !storageService.isOfflineToken;

          if (isOnline && !syncService.isSyncing.value) {
            await syncService.syncPendingTransactions(isSilent: true);
          }
        }

        // Re-check setelah upaya sinkronisasi
        final remainingClosed = storageService.getOfflineClosedShifts();
        if (remainingClosed.isNotEmpty) {
          if (!context.mounted) return false;
          // Buka dialog edukasi: Wajib Sinkronkan Shift Sebelumnya!
          return await showPendingSyncRequiredDialog(
            context,
            closedShift: remainingClosed.first,
            dismissible: dismissible,
          );
        }
      }
    }

    if (!context.mounted) return false;

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
                      if (controller.isConnectionOffline) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.warningSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.warning.withAlpha(80)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wifi_off_rounded, size: 10, color: AppColors.warningDark),
                              SizedBox(width: 4),
                              Text(
                                'Mode Offline',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warningDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (dismissible)
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: AppColors.textSecondary),
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (controller.isConnectionOffline) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warningSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.warning.withAlpha(80)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Server offline. Shift akan dibuka secara lokal di perangkat dan disinkronkan saat online.',
                              style: TextStyle(fontSize: 11.5, color: AppColors.warningDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

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
                  const SizedBox(height: 20),

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

  /// Dialog Peringatan & Edukasi: Wajib Sinkronkan Shift Sebelumnya Sebelum Buka Shift Baru
  static Future<bool> showPendingSyncRequiredDialog(
    BuildContext context, {
    required Map<String, dynamic> closedShift,
    bool dismissible = true,
  }) async {
    final cashierName = closedShift['cashier_name']?.toString() ?? 'Kasir';
    final endTimeRaw = closedShift['end_time']?.toString();
    final endTimeFormatted = endTimeRaw != null ? DateFormatter.formatDateTime(endTimeRaw) : '-';
    final actualCash = (closedShift['summary']?['actual_cash'] as num?)?.toDouble() ?? 0.0;
    final isSyncing = false.obs;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: dismissible,
      builder: (dialogContext) => PopScope(
        canPop: dismissible,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(24),
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
                      child: const Icon(Icons.cloud_sync_rounded, color: AppColors.warning, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sinkronisasi Diperlukan',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Shift sebelumnya belum terunggah ke server',
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
                const SizedBox(height: 18),

                // Ringkasan Shift yang Tertunda
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft.withAlpha(80),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.warning.withAlpha(90)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kasir Shift Lalu:',
                            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                          Text(
                            cashierName,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Waktu Penutupan:',
                            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                          Text(
                            endTimeFormatted,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kas Fisik Disetor:',
                            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                          Text(
                            CurrencyFormatter.format(actualCash),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Penjelasan Edukatif
                const Text(
                  'Untuk mencegah selisih pembukuan kas dan menjaga data transaksi tetap rapi, shift sebelumnya wajib tersinkronisasi ke server sebelum shift baru dapat dibuka.',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, color: AppColors.info, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tip: Nyalakan WiFi kafe atau hotspot HP sejenak untuk upload data shift.',
                          style: TextStyle(fontSize: 11.5, color: AppColors.info, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Tombol Aksi
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Obx(() {
                        final loading = isSyncing.value;
                        return ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: loading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.cloud_upload_rounded, size: 18),
                          label: Text(
                            loading ? 'Menyinkronkan...' : 'Cek & Sinkronkan',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: loading
                              ? null
                              : () async {
                                  isSyncing.value = true;
                                  try {
                                    final api = Get.find<ApiProvider>();
                                    final isConnected = await api.checkConnection();
                                    if (!isConnected) {
                                      AppSnackbar.warning(
                                        'Masih Offline',
                                        'Perangkat belum terhubung ke server. Sambungkan WiFi atau hotspot HP lalu coba lagi.',
                                      );
                                      return;
                                    }

                                    final syncService = Get.find<OfflineSyncService>();
                                    final success = await syncService.syncPendingTransactions();
                                    if (!dialogContext.mounted) return;
                                    if (success) {
                                      Navigator.of(dialogContext).pop(true);
                                      AppSnackbar.success(
                                        'Shift Berhasil Disinkronkan',
                                        'Shift sebelumnya telah tercatat resmi di server. Silakan buka shift baru.',
                                      );
                                      // Otomatis buka dialog Buka Shift baru!
                                      if (context.mounted) {
                                        await showStartShiftDialog(context, dismissible: dismissible);
                                      }
                                    }
                                  } catch (e) {
                                    AppSnackbar.danger('Gagal Sinkronisasi', ApiProvider.getErrorMessage(e));
                                  } finally {
                                    isSyncing.value = false;
                                  }
                                },
                        );
                      }),
                    ),
                  ],
                ),
              ],
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

    // Trigger update data terbaru dan auto-sync jika internet online
    controller.fetchCurrentShift();
    if (Get.isRegistered<OfflineSyncService>()) {
      final syncService = Get.find<OfflineSyncService>();
      if (!syncService.isSyncing.value && !controller.isConnectionOffline && controller.offlineTransactionsCount > 0) {
        syncService.syncPendingTransactions(isSilent: true).then((_) {
          controller.fetchCurrentShift();
        });
      }
    }

    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 480,
            maxHeight: MediaQuery.of(context).size.height * 0.90,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
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

              final isConnOffline = controller.isConnectionOffline;
              final isShiftOffline = controller.isShiftOffline;
              final offlineCount = controller.offlineTransactionsCount;
              final hasPending = offlineCount > 0;
              final isReallyOffline = isConnOffline || isShiftOffline;

              final Color badgeBg;
              final Color badgeBorder;
              final Color badgeColor;
              final IconData badgeIcon;
              final String badgeText;

              if (isReallyOffline) {
                badgeBg = AppColors.warningSoft;
                badgeBorder = AppColors.warning.withAlpha(80);
                badgeColor = AppColors.warningDark;
                badgeIcon = Icons.wifi_off_rounded;
                badgeText = offlineCount > 0 ? 'Shift Offline ($offlineCount)' : 'Mode Offline';
              } else if (hasPending) {
                badgeBg = AppColors.infoSoft;
                badgeBorder = AppColors.info.withAlpha(80);
                badgeColor = AppColors.info;
                badgeIcon = Icons.cloud_sync_rounded;
                badgeText = 'Sinkronisasi ($offlineCount)';
              } else {
                badgeBg = AppColors.successSoft;
                badgeBorder = AppColors.success.withAlpha(80);
                badgeColor = AppColors.success;
                badgeIcon = Icons.circle;
                badgeText = 'Shift Aktif';
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Dialog (PINNED)
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
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: badgeBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              badgeIcon,
                              size: badgeIcon == Icons.circle ? 8 : 12,
                              color: badgeColor,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Body Form (SCROLLABLE DENGAN ZERO OVERFLOW)
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                // Info Banner jika Offline Murni
                if (isReallyOffline) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.warningSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withAlpha(90)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2.0),
                          child: Icon(Icons.cloud_off_rounded, color: AppColors.warning, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offlineCount > 0
                                    ? 'Shift Berjalan dalam Mode Offline'
                                    : 'Koneksi Server Sedang Offline',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warningDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                offlineCount > 0
                                    ? 'Terdapat $offlineCount transaksi offline yang tersimpan di memori kasir.'
                                    : 'Koneksi server terputus. Shift tetap aktif dan transaksi baru akan tersimpan di antrean lokal.',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ]
                // Info Banner jika Online tapi ada transaksi pending sync
                else if (hasPending) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.infoSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.info.withAlpha(90)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_sync_rounded, color: AppColors.info, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Koneksi Online Terhubung',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.info,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Terdapat $offlineCount transaksi offline yang sedang disinkronkan ke server.',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: AppColors.info.withAlpha(30),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            if (Get.isRegistered<OfflineSyncService>()) {
                              await Get.find<OfflineSyncService>().syncPendingTransactions();
                              await controller.fetchCurrentShift();
                            }
                          },
                          child: const Text(
                            'Sinkron',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Card 1: Info Mulai & Modal Awal
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                const SizedBox(height: 10),

                // Card 2: Rincian Penjualan
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Column(
                    children: [
                      _buildRow('Penjualan Tunai (Cash)', CurrencyFormatter.format(shift.cashSales)),
                      const SizedBox(height: 4),
                      _buildRow('Penjualan QRIS', CurrencyFormatter.format(shift.qrisSales)),
                      const SizedBox(height: 4),
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
                      if (offlineCount > 0) ...[
                        const SizedBox(height: 4),
                        _buildRow(
                          'Transaksi Belum Sinkron',
                          '$offlineCount Transaksi',
                          isBold: true,
                          valueColor: AppColors.warningDark,
                        ),
                      ],
                      if (shift.totalCashIn > 0 || shift.totalCashOut > 0) ...[
                        const Divider(height: 14),
                        if (shift.totalCashIn > 0)
                          _buildRow('(+) Total Kas Masuk', CurrencyFormatter.format(shift.totalCashIn), valueColor: AppColors.primary),
                        if (shift.totalCashOut > 0)
                          _buildRow('(-) Total Kas Keluar', CurrencyFormatter.format(shift.totalCashOut), valueColor: AppColors.danger),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Card 3: Highlight Kas di Laci Kasir
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withAlpha(70), width: 1.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.primary.withAlpha(40)),
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 17),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estimasi Kas di Laci',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 1),
                                  Text(
                                    '(Modal + Tunai + In - Out)',
                                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          CurrencyFormatter.format(shift.expectedCash),
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Card 4: Action Tombol Kas Keluar & Kas Masuk
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                side: const BorderSide(color: AppColors.danger),
                                foregroundColor: AppColors.danger,
                              ),
                              icon: const Icon(Icons.arrow_upward_rounded, size: 15),
                              label: const Text(
                                '- Kas Keluar',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                              ),
                              onPressed: () async {
                                Navigator.of(dialogContext).pop();
                                await CashMovementDialog.show(context, initialType: 'out');
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                side: const BorderSide(color: AppColors.primary),
                                foregroundColor: AppColors.primary,
                              ),
                              icon: const Icon(Icons.arrow_downward_rounded, size: 15),
                              label: const Text(
                                '+ Kas Masuk',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                              ),
                              onPressed: () async {
                                Navigator.of(dialogContext).pop();
                                await CashMovementDialog.show(context, initialType: 'in');
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          Navigator.of(dialogContext).pop();
                          await ShiftMovementsHistoryDialog.show(context);
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.history_rounded, size: 15, color: AppColors.textSecondary),
                              const SizedBox(width: 5),
                              Text(
                                (shift.totalCashIn > 0 || shift.totalCashOut > 0)
                                    ? 'Lihat Mutasi Kas Shift Ini'
                                    : 'Riwayat Arus Kas Shift',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Tombol Aksi (PINNED DI BAWAH)
        Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    ),
                  ],
                ),
              ],
            );
          }),
        ),
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

                  // Banner Status Mode Offline / Sinkronisasi Transaksi
                  Obx(() {
                    final offCount = controller.offlineTransactionsCount;
                    final isOff = controller.isShiftOffline;
                    if (offCount <= 0 && !isOff) return const SizedBox.shrink();

                    final isConnOff = controller.isConnectionOffline;
                    String message;
                    IconData icon;
                    if (offCount > 0 && !isConnOff) {
                      message = 'Terdapat $offCount transaksi offline di perangkat. Saat shift ditutup, sistem akan otomatis menyinkronkan seluruh transaksi ke server terlebih dahulu.';
                      icon = Icons.cloud_sync_rounded;
                    } else if (offCount > 0) {
                      message = 'Mode Offline: Penutupan shift akan dicatat ke antrean lokal bersama $offCount transaksi dan struk rekapitulasi langsung dicetak.';
                      icon = Icons.cloud_off_rounded;
                    } else {
                      message = 'Mode Offline: Penutupan shift dicatat di antrean offline lokal dan struk rekapitulasi dicetak langsung ke printer thermal.';
                      icon = Icons.cloud_off_rounded;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.warningSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warning.withAlpha(90)),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: AppColors.warning, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              message,
                              style: const TextStyle(fontSize: 12, color: AppColors.warningDark, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  // Info Card Shift
                  Obx(() {
                    final current = controller.currentShift.value ?? shift;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          const SizedBox(height: 2),
                          _buildRow('Penjualan Tunai', CurrencyFormatter.format(current.cashSales)),
                          if (current.totalCashIn > 0) ...[
                            const SizedBox(height: 2),
                            _buildRow('(+) Kas Masuk Laci', CurrencyFormatter.format(current.totalCashIn), valueColor: AppColors.primary),
                          ],
                          if (current.totalCashOut > 0) ...[
                            const SizedBox(height: 2),
                            _buildRow('(-) Kas Keluar Laci', CurrencyFormatter.format(current.totalCashOut), valueColor: AppColors.danger),
                          ],
                          const SizedBox(height: 2),
                          _buildRow('Penjualan Non-Tunai', CurrencyFormatter.format(current.qrisSales + current.transferSales)),
                          const Divider(height: 12),
                          _buildRow(
                            'Total Kas Seharusnya',
                            CurrencyFormatter.format(current.expectedCash),
                            isBold: true,
                            valueColor: AppColors.primaryDark,
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Header Input Uang Fisik + Shortcut Set Uang Pas
                  Obx(() {
                    final current = controller.currentShift.value ?? shift;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Uang Fisik Kasir di Laci:',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            final amt = current.expectedCash.toInt();
                            cashController.text = CurrencyFormatter.formatWithoutSymbol(amt);
                            actualCash.value = current.expectedCash;
                            hasInput.value = true;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withAlpha(60)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 13, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Set Uang Pas',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
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
                      hintText: '0',
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
                    IconData diffIcon = Icons.check_circle_rounded;
                    String statusText = 'Pas (Sesuai)';

                    if (diff > 0) {
                      diffColor = AppColors.info;
                      diffIcon = Icons.arrow_circle_up_rounded;
                      statusText = 'Lebih (+${CurrencyFormatter.format(diff)})';
                    } else if (diff < 0) {
                      diffColor = AppColors.danger;
                      diffIcon = Icons.warning_amber_rounded;
                      statusText = 'Kurang (${CurrencyFormatter.format(diff)})';
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: diffColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: diffColor.withAlpha(80)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(diffIcon, size: 16, color: diffColor),
                              const SizedBox(width: 8),
                              const Text(
                                'Status Selisih Kas:',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Text(
                            statusText,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: diffColor),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Catatan Kasir (Opsional)',
                      hintText: 'Misal: Selisih karena pembulatan atau uang kembalian',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Batal'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Obx(() => ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.warning,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                                controller.isLoading.value ? 'Menutup...' : 'Tutup Shift',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                              onPressed: controller.isLoading.value
                                  ? null
                                  : () async {
                                      if (formKey.currentState!.validate()) {
                                        final raw = cashController.text.replaceAll(RegExp(r'[^0-9]'), '');
                                        final amount = double.tryParse(raw) ?? 0;
                                        final notes = notesController.text.trim();

                                        final success = await controller.endShift(amount, notes);
                                        if (success && dialogContext.mounted) {
                                          Navigator.of(dialogContext).pop(true);
                                        }
                                      }
                                    },
                            )),
                      ),
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
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
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
}
