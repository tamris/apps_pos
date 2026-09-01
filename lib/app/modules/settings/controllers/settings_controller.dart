import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/offline_sync_service.dart';
import '../../../data/services/esc_pos_printer_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../auth/controllers/auth_controller.dart';

class SettingsController extends GetxController {
  final StorageService _storageService = Get.find<StorageService>();
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final EscPosPrinterService printerService = Get.find<EscPosPrinterService>();
  final OfflineSyncService offlineSyncService = Get.find<OfflineSyncService>();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final TextEditingController baseUrlController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _storageService.user;
    baseUrlController.text = _storageService.baseUrl;
  }

  @override
  void onClose() {
    baseUrlController.dispose();
    super.onClose();
  }

  /// Simpan URL Server baru
  Future<void> saveBaseUrl() async {
    final newUrl = baseUrlController.text.trim();
    if (newUrl.isNotEmpty) {
      await _storageService.setBaseUrl(newUrl);
      _apiProvider.updateBaseUrl(newUrl);
      AppSnackbar.success(
        'Tersimpan',
        'URL Server backend berhasil diperbarui ke: $newUrl',
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
