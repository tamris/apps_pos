import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/addon_model.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/cafe_settings_model.dart';
import '../../../data/models/shift_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../shift/controllers/shift_controller.dart';

class PosController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxList<ProductModel> products = <ProductModel>[].obs;
  final RxList<AddonModel> allAddons = <AddonModel>[].obs;
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
    // 1. Muat cache lokal terlebih dahulu agar UI instan dan siap offline
    _loadCachedBootstrap();
    // 2. Ambil data terbaru dari backend
    fetchBootstrap();
    fetchOpenBillsCount();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Memuat data bootstrap dari penyimpanan lokal (Master Data Cache)
  void _loadCachedBootstrap() {
    final cachedData = _storageService.getBootstrapCache();
    if (cachedData != null) {
      _applyBootstrapData(cachedData);
    }
  }

  /// Terapkan payload data bootstrap ke state aplikasi
  void _applyBootstrapData(Map<String, dynamic> data) {
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

    // 3. Addons
    if (data['addons'] != null) {
      final List addonList = data['addons'];
      allAddons.assignAll(
        addonList.map((e) => AddonModel.fromJson(e)).toList(),
      );
    }

    // 4. Occupied Tables & Open Bills Count
    if (data['occupied_tables'] != null) {
      final List tables = data['occupied_tables'];
      occupiedTables.assignAll(tables.map((e) => e.toString()).toList());
    }
    if (data['open_bills_count'] != null) {
      final count = (data['open_bills_count'] as num).toInt();
      updateOpenBillsCount(count);
    }

    // 5. Cafe Settings
    if (data['settings'] != null) {
      cafeSettings.value = CafeSettingsModel.fromJson(data['settings']);
    }

    // 6. Presets
    if (data['quick_cash_presets'] != null) {
      final List presets = data['quick_cash_presets'];
      quickCashPresets.assignAll(
        presets.map((e) => int.tryParse(e.toString()) ?? 0).toList(),
      );
    }
  }

  /// Ambil daftar add-ons yang tersedia untuk suatu produk menu.
  /// Memprioritaskan product.availableAddons dari server.
  /// Fallback cerdas: mencocokkan category_id produk ke allAddons jika cache offline
  /// berasal dari versi sebelumnya.
  List<AddonModel> getAddonsForProduct(ProductModel product) {
    if (product.availableAddons.isNotEmpty) {
      return product.availableAddons.where((a) => a.isActive).toList();
    }
    if (product.categoryId > 0 && allAddons.isNotEmpty) {
      return allAddons
          .where((a) => a.isActive && a.categoryIds.contains(product.categoryId))
          .toList();
    }
    return const [];
  }

  /// Ambil ulang data add-ons langsung dari endpoint dedicated
  Future<void> fetchAddons() async {
    try {
      final response = await _apiProvider.get(ApiConstants.addons);
      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'];
        allAddons.assignAll(list.map((e) => AddonModel.fromJson(e)).toList());
      }
    } catch (_) {}
  }

  /// Ambil data lengkap POS (Kategori, Produk, Meja Terisi, Info Kafe, Shift)
  Future<void> fetchBootstrap({bool isSilent = false}) async {
    final bool hasExistingData = products.isNotEmpty;
    if (!hasExistingData && !isSilent) {
      isLoading.value = true;
    }

    try {
      // Jika kasir masuk dalam mode offline token, coba lakukan auto re-auth jika internet sudah aktif
      if (_storageService.isOfflineToken) {
        await _apiProvider.ensureAuthenticated();
      }

      // Jika masih offline token (internet belum ada), tetap gunakan data cache lokal
      if (_storageService.isOfflineToken) {
        return;
      }

      final response = await _apiProvider.get(ApiConstants.bootstrap);
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];

        // Terapkan data ke model
        _applyBootstrapData(data);

        // Simpan ke storage untuk master cache offline berikutnya
        await _storageService.saveBootstrapCache(data);

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
          }
        }
      }
    } catch (e) {
      if (products.isEmpty) {
        AppSnackbar.danger('Koneksi POS', ApiProvider.getErrorMessage(e));
      }
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


  /// Update nilai badge open bill secara hening (silent update)
  void updateOpenBillsCount(int newCount) {
    activeOpenBillsCount.value = newCount;
  }

  /// Ambil jumlah open bill aktif (Server + Offline Lokal)
  Future<void> fetchOpenBillsCount() async {
    final completedIds = _storageService.getOfflineCompletedServerBillIds();
    final offlineBills = _storageService.getOfflineOpenBills()
        .where((e) {
          final id = int.tryParse(e['id']?.toString() ?? '0') ?? 0;
          return !completedIds.contains(id);
        })
        .toList();

    final offlineIds = offlineBills
        .map((e) => int.tryParse(e['id']?.toString() ?? '0') ?? 0)
        .toSet();

    final cachedServerBills = _storageService.getCachedServerOpenBills()
        .where((e) {
          final id = int.tryParse(e['id']?.toString() ?? '0') ?? 0;
          return !completedIds.contains(id) && !offlineIds.contains(id);
        })
        .toList();

    // Gabungan lokal (offline + snapshot server yang tersimpan tanpa duplikat)
    final allLocalBills = [...offlineBills, ...cachedServerBills];
    final localTables = allLocalBills
        .map((e) => e['table_number']?.toString())
        .where((t) => t != null && t.isNotEmpty)
        .cast<String>()
        .toSet();

    try {
      if (_storageService.isOfflineToken) {
        updateOpenBillsCount(allLocalBills.length);
        occupiedTables.assignAll(localTables.toList());
        return;
      }

      final response = await _apiProvider.get(ApiConstants.openBills);
      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];

        // Simpan snapshot server bills ke cache lokal
        final serverMaps = list.map((e) => Map<String, dynamic>.from(e)).toList();
        await _storageService.saveCachedServerOpenBills(serverMaps);

        // Filter out ID yang sudah diselesaikan offline atau sedang aktif di offline bills
        final activeServerList = serverMaps.where((e) {
          final id = int.tryParse(e['id']?.toString() ?? '0') ?? 0;
          return !completedIds.contains(id) && !offlineIds.contains(id);
        }).toList();

        final totalCount = activeServerList.length + offlineBills.length;
        updateOpenBillsCount(totalCount);

        // Update occupiedTables gabungan server + offline (tanpa duplikat)
        final serverTables = activeServerList
            .map((e) => e['table_number']?.toString())
            .where((t) => t != null && t.isNotEmpty)
            .cast<String>()
            .toSet();

        final offlineTables = offlineBills
            .map((e) => e['table_number']?.toString())
            .where((t) => t != null && t.isNotEmpty)
            .cast<String>()
            .toSet();

        occupiedTables.assignAll({...serverTables, ...offlineTables}.toList());
      } else {
        updateOpenBillsCount(allLocalBills.length);
        occupiedTables.assignAll(localTables.toList());
      }
    } catch (_) {
      // Fallback offline: gunakan data lokal gabungan (offline + cached server)
      updateOpenBillsCount(allLocalBills.length);
      occupiedTables.assignAll(localTables.toList());
    }
  }
}
