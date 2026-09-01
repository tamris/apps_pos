import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../core/theme/app_colors.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Pengaturan & Perangkat', style: TextStyle(fontWeight: FontWeight.bold)),
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

          // Section 3: URL Server Backend
          _buildServerConfigSection(context),
          const SizedBox(height: 16),

          // Section 4: Offline Sync
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
                Icon(Icons.dns_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('URL Server Backend (API)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Sesuaikan alamat IP backend Laravel POS bila menggunakan jaringan lokal toko:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.baseUrlController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.link_rounded),
                hintText: 'http://192.168.1.100:8000/api',
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save_rounded, size: 16),
                label: const Text('Simpan URL Server'),
                onPressed: () => controller.saveBaseUrl(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineSyncSection(BuildContext context) {
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
                Icon(Icons.cloud_sync_rounded, color: AppColors.info),
                SizedBox(width: 8),
                Text('Sinkronisasi Offline', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() {
              final count = controller.offlineSyncService.pendingCount.value;
              final isSyncing = controller.offlineSyncService.isSyncing.value;

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        count > 0 ? '$count Transaksi Tersimpan Offline' : 'Semua transaksi tersinkronisasi',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: count > 0 ? AppColors.warning : AppColors.success,
                        ),
                      ),
                      const Text(
                        'Data tersimpan aman di penyimpanan lokal.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: count > 0 ? AppColors.primary : AppColors.lightBackground,
                      foregroundColor: count > 0 ? Colors.white : AppColors.textPrimary,
                      side: BorderSide(color: count > 0 ? AppColors.primary : AppColors.lightBorder),
                    ),
                    icon: isSyncing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Sync Sekarang'),
                    onPressed: isSyncing ? null : () => controller.syncOffline(),
                  ),
                ],
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
