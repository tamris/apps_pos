import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/offline_sync_service.dart';
import '../../../data/services/esc_pos_printer_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../auth/controllers/auth_controller.dart';

class SettingsController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final EscPosPrinterService printerService = Get.find<EscPosPrinterService>();
  final OfflineSyncService offlineSyncService = Get.find<OfflineSyncService>();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final TextEditingController baseUrlController = TextEditingController();

  void resetBaseUrlToDefault() {
    baseUrlController.text = ApiConstants.defaultBaseUrl;
  }

  // State Audio Notifikasi Kustom & Presets
  final RxString selectedPreset = 'bell_classic'.obs;
  final RxString customSoundName = ''.obs;
  final RxString customSoundPath = ''.obs;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _storageService.user;
    baseUrlController.text = _storageService.baseUrl;
    selectedPreset.value = _storageService.selectedSoundPreset;
    customSoundName.value = _storageService.customSoundName ?? '';
    customSoundPath.value = _storageService.customSoundPath ?? '';
  }

  @override
  void onClose() {
    baseUrlController.dispose();
    super.onClose();
  }

  /// Pilih salah satu preset nada bawaan
  Future<void> selectPreset(String presetId) async {
    await _storageService.saveSelectedSoundPreset(presetId);
    selectedPreset.value = presetId;
    SoundService.testPlaySound(presetId: presetId);
  }

  /// Pilih file audio sendiri dari memori HP kasir (MP3/WAV/M4A/dll)
  Future<void> pickCustomSound() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'ogg', 'aac', 'flac'],
      );

      if (result != null && result.files.single.path != null) {
        final sourcePath = result.files.single.path!;
        final fileName = result.files.single.name;

        // Salin file ke folder internal aplikasi agar tidak hilang jika file di Downloads terhapus
        final appDir = await getApplicationDocumentsDirectory();
        final ext = fileName.contains('.') ? fileName.split('.').last : 'mp3';
        final savedFileName = 'custom_order_sound_${DateTime.now().millisecondsSinceEpoch}.$ext';
        final savedFile = File('${appDir.path}/$savedFileName');

        await File(sourcePath).copy(savedFile.path);

        await _storageService.saveCustomSound(savedFile.path, fileName);
        customSoundName.value = fileName;
        customSoundPath.value = savedFile.path;
        selectedPreset.value = 'custom';

        AppSnackbar.success(
          'Suara Notifikasi Diperbarui',
          'Suara "$fileName" berhasil dipilih.',
        );

        // Putar langsung sebagai pratinjau
        SoundService.testPlaySound(customPath: savedFile.path);
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Memilih Suara', 'Terjadi kesalahan: $e');
    }
  }

  /// Reset kembali ke nada lonceng kasir bawaan
  Future<void> resetToDefaultSound() async {
    await _storageService.clearCustomSound();
    customSoundName.value = '';
    customSoundPath.value = '';
    selectedPreset.value = 'bell_classic';
    AppSnackbar.info('Suara Bawaan', 'Suara dikembalikan ke Lonceng Kasir Klasik.');
    SoundService.testPlaySound(presetId: 'bell_classic');
  }

  /// Tes putar suara notifikasi saat ini
  void testCurrentSound() {
    SoundService.testPlaySound(presetId: selectedPreset.value);
  }

  /// Simpan Alamat Server Toko
  Future<void> saveBaseUrl() async {
    final newUrl = baseUrlController.text.trim();
    if (newUrl.isNotEmpty) {
      await _storageService.setBaseUrl(newUrl);
      _apiProvider.updateBaseUrl(newUrl);
      AppSnackbar.success(
        'Tersimpan',
        'Alamat server toko berhasil diperbarui.',
      );
    }
  }

  /// Pindai perangkat bluetooth printer
  Future<void> scanPrinters() async {
    await printerService.scanDevices();
  }

  /// Hubungkan printer bluetooth
  Future<void> connectPrinter(BluetoothInfo device) async {
    await printerService.connect(device.macAdress, device.name);
  }

  /// Putuskan printer bluetooth
  Future<void> disconnectPrinter() async {
    await printerService.disconnect();
  }

  /// Cetak struk uji coba printer
  Future<void> printTest() async {
    await printerService.printTestReceipt();
  }

  /// Sinkronisasi transaksi offline
  Future<void> syncOffline() async {
    await offlineSyncService.syncPendingTransactions();
  }

  /// Logout kasir
  void logout() {
    if (Get.isRegistered<AuthController>()) {
      Get.find<AuthController>().logout();
    } else {
      Get.put(AuthController()).logout();
    }
  }
}
