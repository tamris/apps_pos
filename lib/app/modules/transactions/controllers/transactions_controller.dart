import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/addon_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/esc_pos_printer_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../pos/controllers/pos_controller.dart';
import '../views/widgets/receipt_view_dialog.dart';

class TransactionsController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final EscPosPrinterService _printerService = Get.find<EscPosPrinterService>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final Rx<TransactionStatsModel> stats = TransactionStatsModel.empty().obs;
  final RxString selectedTab = 'completed'.obs; // 'completed', 'pending', 'cancelled', 'all'
  RxString get selectedStatus => selectedTab;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    fetchTodayTransactions();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  /// Susun daftar transaksi offline dari antrean lokal StorageService
  List<TransactionModel> _buildOfflineTransactionsList() {
    final offlineQueue = _storageService.getOfflineQueue();
    final List<TransactionModel> result = [];

    for (int i = 0; i < offlineQueue.length; i++) {
      final item = offlineQueue[i];
      final offlineId = item['offline_id']?.toString() ?? 'OFF-$i';
      final orderType = item['order_type']?.toString() ?? 'dine_in';
      final tableNumber = item['table_number']?.toString();
      final customerName = item['customer_name']?.toString();
      final paymentMethod = item['payment_method']?.toString() ?? 'cash';
      final paid = (item['paid'] as num?)?.toDouble() ?? 0.0;
      final createdAtStr = item['created_at']?.toString() ?? DateTime.now().toIso8601String();
      final dt = DateTime.tryParse(createdAtStr) ?? DateTime.now();

      final rawItems = (item['items'] as List?) ?? [];
      final List<TransactionDetailModel> details = [];
      double subtotalCalc = 0.0;

      for (var it in rawItems) {
        if (it is Map) {
          String name = it['name']?.toString() ??
                        it['product_name']?.toString() ??
                        (it['product'] is Map ? it['product']['name']?.toString() : null) ??
                        it['title']?.toString() ??
                        '';
          final pId = int.tryParse((it['product_id'] ?? it['id'] ?? '0').toString()) ?? 0;
          if ((name.isEmpty || name == 'Menu' || name == 'Item') && pId > 0 && Get.isRegistered<PosController>()) {
            final found = Get.find<PosController>().products.firstWhereOrNull((p) => p.id == pId);
            if (found != null && found.name.isNotEmpty) {
              name = found.name;
            }
          }
          if (name.isEmpty) name = 'Menu';

          final qty = int.tryParse((it['quantity'] ?? it['qty'] ?? '1').toString()) ?? 1;
          final prc = double.tryParse((it['unit_price'] ?? it['price'] ?? '0').toString()) ?? 0.0;
          final sub = double.tryParse((it['total_price'] ?? it['subtotal'] ?? (qty * prc)).toString()) ?? (qty * prc);
          subtotalCalc += sub;

          var addonsList = <AddonModel>[];
          if (it['addons'] != null && it['addons'] is List) {
            addonsList = (it['addons'] as List)
                .map((a) => AddonModel.fromJson(Map<String, dynamic>.from(a)))
                .toList();
          }

          details.add(TransactionDetailModel(
            name: name,
            quantity: qty,
            price: prc,
            subtotal: sub,
            notes: it['notes']?.toString(),
            addons: addonsList,
          ));
        }
      }

      final discountPercent = (item['discount_percent'] as num?)?.toDouble() ?? 0.0;
      final taxPercent = (item['tax_percent'] as num?)?.toDouble() ?? 0.0;
      final discountAmount = subtotalCalc * (discountPercent / 100);
      final taxAmount = (subtotalCalc - discountAmount) * (taxPercent / 100);
      final total = subtotalCalc - discountAmount + taxAmount;
      final change = max(0.0, paid - total);

      // Synthetic negative ID based on index: -1, -2, -3...
      final syntheticId = -(i + 1);

      final dateStr = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      final timeStr = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

      result.add(TransactionModel(
        id: syntheticId,
        invoiceNumber: offlineId,
        status: 'completed',
        orderType: orderType,
        tableNumber: tableNumber,
        customerName: customerName,
        paymentMethod: paymentMethod.toUpperCase() == 'CASH' ? 'TUNAI' : paymentMethod.toUpperCase(),
        total: total,
        paid: paid,
        change: change,
        itemsCount: details.fold<int>(0, (sum, d) => sum + d.quantity),
        time: timeStr,
        date: dateStr,
        details: details,
      ));
    }

    // Urutkan dari yang terbaru ke terlama (DESC) agar konsisten dengan server
    return result.reversed.toList();
  }

  /// Ambil dan filter transaksi server yang tersimpan di cache lokal saat offline
  List<TransactionModel> _loadCachedServerTransactions() {
    final cachedRaw = _storageService.getCachedTodayTransactions();
    if (cachedRaw.isEmpty) return [];

    final list = cachedRaw.map((e) => TransactionModel.fromJson(e)).toList();

    return list.where((t) {
      // 1. Filter Status / Tab
      if (selectedTab.value == 'completed' && !t.isCompleted) return false;
      if (selectedTab.value == 'pending' && !t.isPending) return false;
      if (selectedTab.value == 'cancelled' && !t.isCancelled) return false;

      // 2. Filter Search Query
      if (searchQuery.value.trim().isNotEmpty) {
        final q = searchQuery.value.trim().toLowerCase();
        final inv = t.invoiceNumber.toLowerCase();
        final table = (t.tableNumber ?? '').toLowerCase();
        final cust = (t.customerName ?? '').toLowerCase();
        return inv.contains(q) || table.contains(q) || cust.contains(q);
      }

      return true;
    }).toList();
  }

  /// Hitung statistik transaksi saat offline (menggunakan snapshot server + offline queue)
  void _computeOfflineStats(List<TransactionModel> offlineTxs) {
    final cachedStats = _storageService.getCachedTodayStats();
    if (cachedStats != null) {
      final serverStats = TransactionStatsModel.fromJson(cachedStats);
      stats.value = TransactionStatsModel(
        all: serverStats.all + offlineTxs.length,
        completed: serverStats.completed + offlineTxs.length,
        pending: serverStats.pending,
        cancelled: serverStats.cancelled,
      );
    } else {
      final cachedRaw = _storageService.getCachedTodayTransactions();
      final cachedTxs = cachedRaw.map((e) => TransactionModel.fromJson(e)).toList();
      final comp = cachedTxs.where((t) => t.isCompleted).length;
      final pend = cachedTxs.where((t) => t.isPending).length;
      final canc = cachedTxs.where((t) => t.isCancelled).length;

      stats.value = TransactionStatsModel(
        all: cachedTxs.length + offlineTxs.length,
        completed: comp + offlineTxs.length,
        pending: pend,
        cancelled: canc,
      );
    }
  }

  /// Susun payload struk untuk transaksi offline
  Map<String, dynamic> _buildOfflineReceiptPayload(TransactionModel tx) {
    final posCtrl = Get.isRegistered<PosController>() ? Get.find<PosController>() : null;
    final cafeSettings = posCtrl?.cafeSettings.value;
    final shopName = (cafeSettings?.shopName.isNotEmpty == true) ? cafeSettings!.shopName : 'NOLI COFFEE & SPACE';
    final address = (cafeSettings?.address.isNotEmpty == true) ? cafeSettings!.address : '';
    final phone = cafeSettings?.phone ?? '';

    final cashierName = _storageService.user?.name ?? 'Kasir';
    final subtotal = tx.details.fold<double>(0.0, (sum, d) => sum + d.subtotal);
    final discount = (subtotal - tx.total) > 0 ? (subtotal - tx.total) : 0.0;

    String cleanPayMethod = tx.paymentMethod.replaceAll('(OFFLINE)', '').replaceAll('OFFLINE', '').trim();
    if (cleanPayMethod.isEmpty || cleanPayMethod == 'CASH' || cleanPayMethod == 'TUNAI') {
      cleanPayMethod = 'TUNAI';
    }

    return {
      'header': {
        'shop_name': shopName,
        'address': address,
        'phone': phone,
        'show_logo': false,
      },
      'invoice_number': tx.invoiceNumber,
      'date': '${tx.date} ${tx.time}',
      'cashier_name': cashierName,
      'order_type': tx.orderType.toUpperCase(),
      'table_number': tx.tableNumber,
      'customer_name': tx.customerName,
      'items': tx.details.map((d) => {
        'name': d.name,
        'quantity': d.quantity,
        'price': d.price,
        'subtotal': d.subtotal,
        'notes': d.notes,
        'addons': d.addons.map((a) => {'name': a.name, 'price': a.price}).toList(),
      }).toList(),
      'summary': {
        'subtotal': subtotal,
        'discount': discount,
        'tax': 0.0,
        'total': tx.total,
        'payment_method': cleanPayMethod,
        'paid': tx.paid,
        'change': tx.change,
      },
      'footer': {
        'message': cafeSettings?.receiptFooter ?? 'Terima Kasih Atas Kunjungannya!',
        'wifi_name': cafeSettings?.wifiName,
        'wifi_password': cafeSettings?.wifiPassword,
      },
    };
  }

  /// Ambil riwayat transaksi hari ini kasir beserta live stats (Server + Offline)
  Future<void> fetchTodayTransactions({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final offlineTxs = _buildOfflineTransactionsList();

      // Filter offline berdasarkan tab dan search
      List<TransactionModel> filteredOffline = offlineTxs;
      if (selectedTab.value == 'cancelled' || selectedTab.value == 'pending') {
        filteredOffline = [];
      }
      if (searchQuery.value.trim().isNotEmpty) {
        final q = searchQuery.value.trim().toLowerCase();
        filteredOffline = filteredOffline.where((t) {
          final inv = t.invoiceNumber.toLowerCase();
          final table = (t.tableNumber ?? '').toLowerCase();
          final cust = (t.customerName ?? '').toLowerCase();
          return inv.contains(q) || table.contains(q) || cust.contains(q);
        }).toList();
      }

      if (_storageService.isOfflineToken) {
        final cachedServerTxs = _loadCachedServerTransactions();
        final offlineInvoices = filteredOffline.map((t) => t.invoiceNumber.trim().toLowerCase()).toSet();
        final deduplicatedCached = cachedServerTxs.where((t) => !offlineInvoices.contains(t.invoiceNumber.trim().toLowerCase())).toList();
        transactions.assignAll([...filteredOffline, ...deduplicatedCached]);
        _computeOfflineStats(offlineTxs);
        return;
      }

      final response = await _apiProvider.get(
        ApiConstants.todayTransactions,
        queryParameters: {
          if (searchQuery.value.trim().isNotEmpty) 'search': searchQuery.value.trim(),
          'status': selectedTab.value,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final List list = (data is Map && data['data'] != null) ? data['data'] : (data is List ? data : []);
        final serverTxs = list.map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e))).toList();

        // Gabungkan: Transaksi offline di paling atas, deduplikasi jika ada nomor invoice yang sama
        final offlineInvoices = filteredOffline.map((t) => t.invoiceNumber.trim().toLowerCase()).toSet();
        final deduplicatedServer = serverTxs.where((t) => !offlineInvoices.contains(t.invoiceNumber.trim().toLowerCase())).toList();
        transactions.assignAll([...filteredOffline, ...deduplicatedServer]);

        // Simpan snapshot server secara kumulatif agar saat offline transaksi hari ini tetap muncul
        if (searchQuery.value.trim().isEmpty) {
          final existingCached = _storageService.getCachedTodayTransactions();
          final mapByInvoice = <String, Map<String, dynamic>>{};
          for (final item in existingCached) {
            final inv = (item['invoice_number'] ?? item['invoiceNumber'] ?? item['id'])?.toString();
            if (inv != null && inv.isNotEmpty) {
              mapByInvoice[inv.toLowerCase()] = item;
            }
          }
          for (final item in list) {
            if (item is Map) {
              final mapItem = Map<String, dynamic>.from(item);
              final inv = (mapItem['invoice_number'] ?? mapItem['invoiceNumber'] ?? mapItem['id'])?.toString();
              if (inv != null && inv.isNotEmpty) {
                mapByInvoice[inv.toLowerCase()] = mapItem;
              }
            }
          }
          final mergedList = mapByInvoice.values.toList();
          mergedList.sort((a, b) {
            final idA = int.tryParse(a['id']?.toString() ?? '0') ?? 0;
            final idB = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
            return idB.compareTo(idA);
          });
          await _storageService.saveCachedTodayTransactions(mergedList);
        }

        if (response.data['stats'] != null) {
          final serverStatsRaw = Map<String, dynamic>.from(response.data['stats']);
          await _storageService.saveCachedTodayStats(serverStatsRaw);
          final serverStats = TransactionStatsModel.fromJson(serverStatsRaw);
          stats.value = TransactionStatsModel(
            all: serverStats.all + offlineTxs.length,
            completed: serverStats.completed + offlineTxs.length,
            pending: serverStats.pending,
            cancelled: serverStats.cancelled,
          );
        }
      } else {
        final cachedServerTxs = _loadCachedServerTransactions();
        final offlineInvoices = filteredOffline.map((t) => t.invoiceNumber.trim().toLowerCase()).toSet();
        final deduplicatedCached = cachedServerTxs.where((t) => !offlineInvoices.contains(t.invoiceNumber.trim().toLowerCase())).toList();
        transactions.assignAll([...filteredOffline, ...deduplicatedCached]);
        _computeOfflineStats(offlineTxs);
      }
    } catch (e) {
      final offlineTxs = _buildOfflineTransactionsList();
      List<TransactionModel> filteredOffline = offlineTxs;
      if (selectedTab.value == 'cancelled' || selectedTab.value == 'pending') {
        filteredOffline = [];
      }
      if (searchQuery.value.trim().isNotEmpty) {
        final q = searchQuery.value.trim().toLowerCase();
        filteredOffline = filteredOffline.where((t) {
          final inv = t.invoiceNumber.toLowerCase();
          final table = (t.tableNumber ?? '').toLowerCase();
          final cust = (t.customerName ?? '').toLowerCase();
          return inv.contains(q) || table.contains(q) || cust.contains(q);
        }).toList();
      }

      final cachedServerTxs = _loadCachedServerTransactions();
      final offlineInvoices = filteredOffline.map((t) => t.invoiceNumber.trim().toLowerCase()).toSet();
      final deduplicatedCached = cachedServerTxs.where((t) => !offlineInvoices.contains(t.invoiceNumber.trim().toLowerCase())).toList();
      transactions.assignAll([...filteredOffline, ...deduplicatedCached]);
      _computeOfflineStats(offlineTxs);
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  /// Ambil data struk dan cetak ulang / tampilkan preview (Offline & Online)
  Future<void> printOrPreviewReceipt(int transactionId) async {
    // 1. Jika transaksi offline (ID < 0) atau saat sedang mode offline
    if (transactionId < 0 || _storageService.isOfflineToken) {
      final localTx = transactions.firstWhereOrNull((t) => t.id == transactionId);
      if (localTx != null) {
        final payload = _buildOfflineReceiptPayload(localTx);
        if (_printerService.isConnected.value) {
          await _printerService.printReceipt(payload);
          AppSnackbar.success('Cetak Struk', 'Struk transaksi dicetak.');
        } else {
          ReceiptViewDialog.show(payload);
        }
        return;
      }
    }

    // 2. Transaksi Online normal
    try {
      final response = await _apiProvider.get(ApiConstants.receiptData(transactionId));
      if (response.data != null && response.data['success'] == true) {
        final payload = response.data['data'];
        if (_printerService.isConnected.value) {
          await _printerService.printReceipt(payload);
        } else {
          ReceiptViewDialog.show(payload);
        }
      }
    } catch (e) {
      // Fallback ke data lokal jika API gagal
      final localTx = transactions.firstWhereOrNull((t) => t.id == transactionId);
      if (localTx != null) {
        final payload = _buildOfflineReceiptPayload(localTx);
        if (_printerService.isConnected.value) {
          await _printerService.printReceipt(payload);
          AppSnackbar.success('Cetak Struk', 'Struk transaksi dicetak.');
        } else {
          ReceiptViewDialog.show(payload);
        }
      } else {
        AppSnackbar.danger('Gagal Cetak Ulang', ApiProvider.getErrorMessage(e));
      }
    }
  }

  /// Tampilkan Pratinjau Kertas Struk (Offline & Online)
  Future<void> previewReceipt(int transactionId) async {
    // 1. Jika transaksi offline (ID < 0) atau saat sedang mode offline
    if (transactionId < 0 || _storageService.isOfflineToken) {
      final localTx = transactions.firstWhereOrNull((t) => t.id == transactionId);
      if (localTx != null) {
        final payload = _buildOfflineReceiptPayload(localTx);
        ReceiptViewDialog.show(payload);
        return;
      }
    }

    // 2. Transaksi Online normal
    try {
      final response = await _apiProvider.get(ApiConstants.receiptData(transactionId));
      if (response.data != null && response.data['success'] == true) {
        final payload = response.data['data'];
        ReceiptViewDialog.show(payload);
      }
    } catch (e) {
      final localTx = transactions.firstWhereOrNull((t) => t.id == transactionId);
      if (localTx != null) {
        final payload = _buildOfflineReceiptPayload(localTx);
        ReceiptViewDialog.show(payload);
      } else {
        AppSnackbar.danger('Gagal Pratinjau Struk', ApiProvider.getErrorMessage(e));
      }
    }
  }

  /// Ganti Tab Status (Selesai, Open Bill, Dibatalkan, Semua)
  void changeTab(String tab) {
    if (selectedTab.value == tab) return;
    selectedTab.value = tab;
    fetchTodayTransactions();
  }

  /// Cari transaksi berdasarkan nama / meja / invoice (silent agar tidak kedip skeleton)
  void onSearch(String val) {
    searchQuery.value = val;
    fetchTodayTransactions(silent: true);
  }

  /// Bersihkan pencarian
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    fetchTodayTransactions(silent: true);
  }

  void onSearchChanged(String query) => onSearch(query);
  void onStatusChanged(String status) => changeTab(status);
}
