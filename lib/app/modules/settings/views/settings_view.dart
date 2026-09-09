import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Section 1: Profil Kasir
          _buildUserSection(context),
          const SizedBox(height: 16),

          // Section 2: Printer Bluetooth Thermal 58mm
          _buildPrinterSection(context),
          const SizedBox(height: 16),

          // Section 3: Suara Notifikasi Pesanan (Audio Kustom / Bawaan)
          _buildSoundSection(context),
          const SizedBox(height: 16),

          // Section 4: URL Server Backend
          _buildServerConfigSection(context),
          const SizedBox(height: 16),

          // Section 5: Offline Sync
          _buildOfflineSyncSection(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUserSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightBorder, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(() {
          final user = controller.currentUser.value;
          return Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primarySoft,
                child: Text(
                  user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'K',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Kasir',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? '-',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySoft,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Role: ${user?.role.toUpperCase() ?? "KASIR"}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('Logout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () => _confirmLogout(context),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPrinterSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightBorder, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.print_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Printer Thermal 58mm (Bluetooth)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Obx(() {
                  final isScanning = controller.printerService.isScanning.value;
                  return IconButton(
                    icon: isScanning
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync_rounded),
                    tooltip: 'Pindai Perangkat',
                    onPressed: () => controller.scanPrinters(),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),

            // Status Printer Saat Ini
            Obx(() {
              final isConnected = controller.printerService.isConnected.value;
              final deviceName = controller.printerService.connectedDeviceName.value;

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isConnected ? AppColors.primarySoft : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isConnected ? AppColors.primaryLight : AppColors.lightBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                      color: isConnected ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isConnected ? 'Terhubung ke: $deviceName' : 'Belum Ada Printer Terhubung',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isConnected ? AppColors.primaryDark : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            isConnected
                                ? 'Standar lebar kertas 58mm ESC/POS aktif.'
                                : 'Pastikan Bluetooth HP aktif dan printer thermal sudah dipasangkan (paired).',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (isConnected)
                      TextButton(
                        onPressed: () => controller.disconnectPrinter(),
                        child: const Text('Putuskan', style: TextStyle(color: AppColors.danger, fontSize: 12)),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),

            // Tombol Uji Cetak Struk Tester
            Obx(() {
              if (!controller.printerService.isConnected.value) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                    icon: const Icon(Icons.receipt_long_rounded, size: 18),
                    label: const Text('Uji Cetak Struk 58mm (Test Print)'),
                    onPressed: () => controller.printTest(),
                  ),
                ),
              );
            }),

            // List Perangkat Bluetooth Terdeteksi
            Obx(() {
              final devices = controller.printerService.availableDevices;
              if (devices.isEmpty) {
                return OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                  icon: const Icon(Icons.bluetooth_searching_rounded, size: 18),
                  label: const Text('Cari & Pasangkan Printer Bluetooth'),
                  onPressed: () => controller.scanPrinters(),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perangkat Bluetooth Terpasang:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  ...devices.map((d) {
                    final isThisConnected = controller.printerService.connectedMacAddress.value == d.macAdress;
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.print_outlined, color: AppColors.primary),
                      title: Text(d.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      subtitle: Text(d.macAdress, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      trailing: isThisConnected
                          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                textStyle: const TextStyle(fontSize: 11),
                              ),
                              onPressed: () => controller.connectPrinter(d),
                              child: const Text('Hubungkan'),
                            ),
                    );
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildServerConfigSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightBorder, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cloud_outlined, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Alamat Server Toko', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Alamat server pusat data untuk menghubungkan aplikasi kasir dengan database toko:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.baseUrlController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.link_rounded),
                hintText: 'https://alamat-server-toko.com/api',
                suffixIcon: Tooltip(
                  message: 'Hapus / Kosongkan',
                  child: IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20, color: AppColors.textMuted),
                    onPressed: () => controller.clearBaseUrl(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySoft.withAlpha(80),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primaryLight.withAlpha(100)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pastikan perangkat kasir terhubung ke jaringan Wi-Fi toko atau internet yang stabil agar sinkronisasi data lancar.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.restore_rounded, size: 16),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onPressed: () => controller.resetBaseUrlToDefault(),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_rounded, size: 16),
                  label: const Text('Simpan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => controller.saveBaseUrl(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineSyncSection(BuildContext context) {
    return Obx(() {
      final syncService = controller.offlineSyncService;
      final count = syncService.pendingCount.value;
      final txCount = syncService.pendingTxCount.value;
      final shiftCount = syncService.pendingShiftCount.value;
      final isSyncing = syncService.isSyncing.value;
      final isOnline = controller.isOnline.value;
      final lastSync = syncService.lastSyncTime.value;

      final Color statusColor = count > 0 ? AppColors.warning : AppColors.success;
      final Color statusBg = count > 0 ? AppColors.warningSoft : AppColors.successSoft;

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 1.2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Icon + Title + Status Chip
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSyncing ? AppColors.primaryLight : statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isSyncing
                          ? Icons.sync_rounded
                          : (count > 0 ? Icons.cloud_upload_rounded : Icons.cloud_done_rounded),
                      color: isSyncing ? AppColors.primary : statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sinkronisasi Cloud & Offline',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isSyncing
                              ? 'Sedang menyinkronkan data...'
                              : (count > 0 ? '$count data menunggu koneksi' : 'Semua data aman & tersinkron'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSyncing ? AppColors.primary : statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSyncing ? AppColors.primaryLight : statusBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (isSyncing ? AppColors.primary : statusColor).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSyncing)
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        else
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          isSyncing ? 'Syncing' : (count > 0 ? '$count Pending' : 'Tersinkron'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSyncing ? AppColors.primary : statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Monitoring Dashboard Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lightBorder),
                ),
                child: Column(
                  children: [
                    // Status Koneksi
                    Row(
                      children: [
                        Icon(
                          isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                          size: 16,
                          color: isOnline ? AppColors.success : AppColors.danger,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Koneksi Backend:',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        Text(
                          isOnline ? 'Online (Terhubung)' : 'Offline (Lokal)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isOnline ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1, color: AppColors.lightBorder),
                    ),
                    // Terakhir Sinkron
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        const Text(
                          'Terakhir Disinkronkan:',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        Text(
                          lastSync != null
                              ? DateFormatter.formatDateTime(lastSync.toIso8601String())
                              : 'Belum pernah disinkronkan',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Pending items breakdown (if count > 0)
              if (count > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningSoft.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.warning),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Data offline tersimpan aman di perangkat.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rincian antrean: $txCount transaksi, $shiftCount shift kasir.',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _showPendingQueueBottomSheet(context),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.list_alt_rounded, size: 14, color: AppColors.textPrimary),
                              SizedBox(width: 6),
                              Text(
                                'Lihat Rincian Antrean',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded, size: 14, color: AppColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Info otomatis background
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.bolt_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Sistem otomatis mengunggah data transaksi & shift kasir ke server setiap kali online. Tidak ada data yang hilang.',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Action button: Sinkronkan Sekarang
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: count > 0 ? AppColors.primary : AppColors.lightBackground,
                    foregroundColor: count > 0 ? Colors.white : AppColors.textPrimary,
                    side: BorderSide(
                      color: count > 0 ? AppColors.primary : AppColors.lightBorder,
                      width: 1.2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: isSyncing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : Icon(
                          Icons.sync_rounded,
                          size: 18,
                          color: count > 0 ? Colors.white : AppColors.textPrimary,
                        ),
                  label: Text(
                    isSyncing
                        ? 'Sedang Menyinkronkan Data...'
                        : (count > 0 ? 'Sinkronkan Sekarang ($count Data)' : 'Sinkronkan Ulang Sekarang'),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  onPressed: isSyncing ? null : () => controller.syncOffline(),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showPendingQueueBottomSheet(BuildContext context) {
    final pendingTx = controller.offlineSyncService.getPendingTransactions();
    final pendingShifts = controller.offlineSyncService.getPendingClosedShifts();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Close Button
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Antrean Data Offline',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Data yang tersimpan lokal dan menunggu dikirim ke server',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.lightBorder),
              const SizedBox(height: 12),

              // List of Pending Items
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (pendingTx.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'Transaksi Offline (${pendingTx.length})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...pendingTx.map((tx) {
                        final offlineId = tx['offline_id']?.toString() ?? '-';
                        final orderType = tx['order_type']?.toString().toUpperCase() ?? 'DINE IN';
                        final table = tx['table_number'] != null ? 'Meja ${tx['table_number']}' : null;
                        final cust = tx['customer_name']?.toString();
                        final sub = [orderType, if (table != null) table, if (cust != null) cust].join(' • ');

                        double amount = 0.0;
                        if (tx['items'] != null && tx['items'] is List) {
                          for (final itm in (tx['items'] as List)) {
                            final qty = int.tryParse(itm['quantity']?.toString() ?? '1') ?? 1;
                            final price = (itm['price'] as num?)?.toDouble() ?? 0.0;
                            amount += price * qty;
                          }
                        }
                        if (amount == 0.0) {
                          amount = (tx['paid'] as num?)?.toDouble() ?? 0.0;
                        }

                        final dateStr = tx['created_at'] != null
                            ? DateFormatter.formatDateTime(tx['created_at'].toString())
                            : '-';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.lightBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.lightBorder),
                                ),
                                child: const Icon(Icons.receipt_rounded, size: 20, color: AppColors.primary),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      offlineId,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    const SizedBox(height: 2),
                                    Text(dateStr, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(amount),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],

                    if (pendingShifts.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(Icons.point_of_sale_rounded, size: 16, color: AppColors.warning),
                          const SizedBox(width: 6),
                          Text(
                            'Shift Kasir Ditutup Offline (${pendingShifts.length})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...pendingShifts.map((cs) {
                        final actualCash = (cs['summary']?['actual_cash'] as num?)?.toDouble() ?? 0.0;
                        final endTime = cs['end_time'] != null
                            ? DateFormatter.formatDateTime(cs['end_time'].toString())
                            : '-';
                        final notes = cs['notes']?.toString();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.lightBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.lightBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.lightBorder),
                                ),
                                child: const Icon(Icons.lock_clock_rounded, size: 20, color: AppColors.warning),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Tutup Shift Kasir', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text('Waktu: $endTime', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    if (notes != null && notes.isNotEmpty)
                                      Text('Catatan: $notes', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Kas Fisik', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                  Text(
                                    CurrencyFormatter.format(actualCash),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bottom buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Tutup'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Sinkronkan Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        controller.syncOffline();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSoundSection(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.lightBorder, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.volume_up_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Suara Notifikasi Pesanan Online',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih salah satu nada bawaan siap pakai di bawah ini atau upload audio sendiri dari HP:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),

            // Daftar 5 Preset Nada Bawaan
            ...SoundService.presets.map((preset) {
              return Obx(() {
                final isSelected = controller.selectedPreset.value == preset.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primarySoft.withAlpha(90) : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.lightBorder,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    dense: true,
                    leading: Text(
                      preset.icon,
                      style: const TextStyle(fontSize: 22),
                    ),
                    title: Text(
                      preset.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      preset.subtitle,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (preset.assetPath != null)
                          IconButton(
                            icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 24),
                            tooltip: 'Dengarkan Nada',
                            onPressed: () => SoundService.testPlaySound(presetId: preset.id),
                          ),
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: isSelected ? AppColors.primary : AppColors.textMuted,
                          size: 22,
                        ),
                      ],
                    ),
                    onTap: () => controller.selectPreset(preset.id),
                  ),
                );
              });
            }),

            const Divider(height: 24),

            // Opsi Tambah Audio Kustom Sendiri dari HP
            const Text(
              'Opsi Kustom (Pilih dari HP):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            Obx(() {
              final hasCustom = controller.customSoundName.value.isNotEmpty;
              final isCustomSelected = controller.selectedPreset.value == 'custom';

              if (!hasCustom) {
                return OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    minimumSize: const Size(double.infinity, 44),
                    side: const BorderSide(color: AppColors.primary, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.folder_open_rounded, color: AppColors.primary, size: 18),
                  label: const Text(
                    'Pilih / Upload File Audio Sendiri (MP3/WAV)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  onPressed: () => controller.pickCustomSound(),
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: isCustomSelected ? AppColors.secondarySoft : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCustomSelected ? AppColors.secondary : AppColors.lightBorder,
                    width: isCustomSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      dense: true,
                      leading: const Text('📁', style: TextStyle(fontSize: 22)),
                      title: Text(
                        controller.customSoundName.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCustomSelected ? FontWeight.bold : FontWeight.w600,
                          color: isCustomSelected ? AppColors.secondary : AppColors.textPrimary,
                        ),
                      ),
                      subtitle: const Text(
                        'File audio kustom tersimpan di memori HP kasir',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_circle_fill_rounded, color: AppColors.secondary, size: 24),
                            tooltip: 'Dengarkan Audio',
                            onPressed: () => SoundService.testPlaySound(presetId: 'custom'),
                          ),
                          Icon(
                            isCustomSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: isCustomSelected ? AppColors.secondary : AppColors.textMuted,
                            size: 22,
                          ),
                        ],
                      ),
                      onTap: () => controller.selectPreset('custom'),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                side: const BorderSide(color: AppColors.lightBorder),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.sync_alt_rounded, size: 15),
                              label: const Text('Ganti File Audio', style: TextStyle(fontSize: 11.5)),
                              onPressed: () => controller.pickCustomSound(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 15),
                            label: const Text('Hapus', style: TextStyle(fontSize: 11.5)),
                            onPressed: () => controller.resetToDefaultSound(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout Kasir?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Anda akan keluar dari sesi kasir aktif.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Get.back();
              controller.logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
