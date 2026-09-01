import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/cafe_settings_model.dart';
import '../../../data/models/shift_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../shift/controllers/shift_controller.dart';
import '../../shift/views/shift_dialogs.dart';

class PosController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<String> occupiedTables = <String>[].obs;
  final RxInt activeOpenBillsCount = 0.obs;
  final Rx<CafeSettingsModel> cafeSettings = CafeSettingsModel().obs;
  final RxList<int> quickCashPresets = <int>[
    10000,
    20000,
    50000,
    100000,
    200000,
  ].obs;

  final RxInt selectedCategoryId = 0.obs; // 0 = Semua Kategori
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchBootstrap();
    fetchOpenBillsCount();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Ambil data lengkap POS (Kategori, Produk, Meja Terisi, Info Kafe, Shift)
  Future<void> fetchBootstrap() async {
    isLoading.value = true;
    try {
      final response = await _apiProvider.get(ApiConstants.bootstrap);
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];

        // 1. Categories
        if (data['categories'] != null) {
          final List catList = data['categories'];
          categories.assignAll(
            catList.map((e) => CategoryModel.fromJson(e)).toList(),
          );
        }

        // 2. Products
        if (data['products'] != null) {
          final List prodList = data['products'];
          products.assignAll(
            prodList.map((e) => ProductModel.fromJson(e)).toList(),
          );
        }

        // 3. Occupied Tables
        if (data['occupied_tables'] != null) {
          final List tables = data['occupied_tables'];
          occupiedTables.assignAll(tables.map((e) => e.toString()).toList());
        }

        // 4. Cafe Settings
        if (data['settings'] != null) {
          cafeSettings.value = CafeSettingsModel.fromJson(data['settings']);
        }

        // 5. Presets
        if (data['quick_cash_presets'] != null) {
          final List presets = data['quick_cash_presets'];
          quickCashPresets.assignAll(
            presets.map((e) => int.tryParse(e.toString()) ?? 0).toList(),
          );
        }

        // 6. Active Shift check
        if (Get.isRegistered<ShiftController>()) {
          final shiftCtrl = Get.find<ShiftController>();
          shiftCtrl.hasActiveShift.value = data['has_active_shift'] == true;
          if (data['active_shift'] != null) {
            final shift = ShiftModel.fromJson(data['active_shift']);
            shiftCtrl.currentShift.value = shift;
            await _storageService.saveActiveShift(shift);
          } else {
            shiftCtrl.currentShift.value = null;
            await _storageService.saveActiveShift(null);
            // Prompt dialog buka shift jika user adalah kasir
            final currentUser = _storageService.user;
            if (currentUser != null && currentUser.isCashier) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Get.context != null) {
                  ShiftDialogs.showStartShiftDialog(
                    Get.context!,
                    dismissible: false,
                  );
                }
              });
            }
          }
        }
      }
    } catch (e) {
      AppSnackbar.danger('Koneksi POS', ApiProvider.getErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  /// Filter produk berdasarkan kategori dan kata kunci pencarian,
  /// dengan urutan: Produk Aktif (Ready) di atas, Produk Non-Aktif (Habis) di paling bawah
  List<ProductModel> get filteredProducts {
    final list = products.where((product) {
      // Filter kategori
      final matchCategory =
          (selectedCategoryId.value == 0) ||
          (product.categoryId == selectedCategoryId.value);
      if (!matchCategory) return false;

      // Filter query pencarian
      final query = searchQuery.value.trim().toLowerCase();
      if (query.isEmpty) return true;

      final nameMatch = product.name.toLowerCase().contains(query);
      final skuMatch = product.sku?.toLowerCase().contains(query) ?? false;
      final barcodeMatch =
          product.barcode?.toLowerCase().contains(query) ?? false;
      return nameMatch || skuMatch || barcodeMatch;
    }).toList();

    // Sort: Produk aktif (true) di urutan awal, non-aktif (false) di paling bawah
    list.sort((a, b) {
      if (a.isActive && !b.isActive) return -1;
      if (!a.isActive && b.isActive) return 1;
      return 0;
    });

    return list;
  }

  void selectCategory(int categoryId) {
    selectedCategoryId.value = categoryId;
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  /// Toggle ketersediaan menu produk (Ready / Habis)
  Future<bool> toggleProductAvailability(ProductModel product) async {
    final newStatus = !product.isActive;

    // Optimistic update di UI
    final index = products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      products[index] = product.copyWith(isActive: newStatus);
    }

    try {
      final response = await _apiProvider.post(
        ApiConstants.toggleProductAvailability(product.id),
      );

      if (response.data != null && response.data['success'] == true) {
        final statusLabel = newStatus ? 'Tersedia di Kasir' : 'Habis / Non-Aktif';
        AppSnackbar.success(
          'Ketersediaan Menu',
          "Menu '${product.name}' kini diubah menjadi $statusLabel.",
        );
        return true;
      } else {
        // Rollback jika server error
        if (index != -1) {
          products[index] = product.copyWith(isActive: !newStatus);
        }
        AppSnackbar.danger(
          'Gagal Mengubah Status',
          response.data?['message'] ?? 'Terjadi kesalahan di server.',
        );
        return false;
      }
    } catch (e) {
      // Rollback jika jaringan error
      if (index != -1) {
        products[index] = product.copyWith(isActive: !newStatus);
      }
      AppSnackbar.danger('Gagal Mengubah Status', ApiProvider.getErrorMessage(e));
      return false;
    }
  }

  /// Tandai meja terisi setelah save open bill / checkout dine in
  void markTableOccupied(String table) {
    if (!occupiedTables.contains(table)) {
      occupiedTables.add(table);
    }
    fetchOpenBillsCount();
  }

  /// Hapus meja dari daftar terisi setelah selesai bayar / void
  void freeTable(String table) {
    occupiedTables.remove(table);
    fetchOpenBillsCount();
  }

  /// Ambil jumlah open bill aktif
  Future<void> fetchOpenBillsCount() async {
    try {
      final response = await _apiProvider.get(ApiConstants.openBills);
      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        activeOpenBillsCount.value = list.length;
      }
    } catch (_) {}
  }
}
