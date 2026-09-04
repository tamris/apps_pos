import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';
import '../../../core/services/sound_service.dart';
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
                children: [
                  Expanded(
                    child: Column(
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
                        const SizedBox(height: 2),
                        const Text(
                          'Data tersimpan aman di penyimpanan lokal.',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: count > 0 ? AppColors.primary : AppColors.lightBackground,
                      foregroundColor: count > 0 ? Colors.white : AppColors.textPrimary,
                      side: BorderSide(color: count > 0 ? AppColors.primary : AppColors.lightBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    icon: isSyncing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Sync', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
