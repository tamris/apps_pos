import 'package:get/get.dart';
import '../../../data/models/open_bill_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/esc_pos_printer_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../pos/controllers/cart_controller.dart';
import '../../pos/controllers/pos_controller.dart';
import '../../transactions/views/widgets/receipt_view_dialog.dart';

class OpenBillsController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final StorageService _storageService = Get.find<StorageService>();
  final EscPosPrinterService _printerService = Get.find<EscPosPrinterService>();

  final RxList<OpenBillModel> openBills = <OpenBillModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  double get totalPendingAmount =>
      openBills.fold(0.0, (sum, b) => sum + b.total);

  @override
  void onInit() {
    super.onInit();
    fetchOpenBills();
  }

  /// Ambil daftar seluruh bill aktif (pending) dari Server + Offline Storage
  Future<void> fetchOpenBills() async {
    isLoading.value = true;
    try {
      final completedIds = _storageService.getOfflineCompletedServerBillIds();

      // 1. Ambil Open Bills yang tersimpan di penyimpanan offline lokal (dibuat / diedit saat offline)
      final rawOffline = _storageService.getOfflineOpenBills();
      final offlineList = rawOffline
          .map((e) {
            final map = Map<String, dynamic>.from(e);
            map['is_offline'] = true;
            return OpenBillModel.fromJson(map);
          })
          .where((b) => !completedIds.contains(b.id))
          .toList();

      final offlineIds = offlineList.map((b) => b.id).toSet();

      // 2. Ambil snapshot Open Bills server yang tersimpan di cache lokal
      final rawCachedServer = _storageService.getCachedServerOpenBills();
      final cachedServerList = rawCachedServer
          .map((e) => OpenBillModel.fromJson(e))
          .where((b) => !completedIds.contains(b.id) && !offlineIds.contains(b.id))
          .toList();

      // Gabungan lokal (offline + cached server)
      final combinedLocal = [...offlineList, ...cachedServerList];

      // Helper filter pencarian
      final query = searchQuery.value.trim().toLowerCase();
      List<OpenBillModel> filterList(List<OpenBillModel> source) {
        if (query.isEmpty) return source;
        return source.where((b) {
          final table = (b.tableNumber ?? '').toLowerCase();
          final cust = (b.customerName ?? '').toLowerCase();
          final inv = b.invoiceNumber.toLowerCase();
          return table.contains(query) ||
              cust.contains(query) ||
              inv.contains(query);
        }).toList();
      }

      // Jika offline mode, langsung gunakan gabungan data lokal (offline + cached server)
      if (_storageService.isOfflineToken) {
        openBills.assignAll(filterList(combinedLocal));
        if (Get.isRegistered<PosController>()) {
          Get.find<PosController>().fetchOpenBillsCount();
        }
        return;
      }

      // 3. Jika online, ambil data dari server dan simpan snapshot-nya
      final response = await _apiProvider.get(
        ApiConstants.openBills,
        queryParameters: query.isNotEmpty ? {'search': query} : null,
      );

      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];

        // Simpan snapshot server bills ke cache lokal jika tidak sedang search
        if (query.isEmpty) {
          final serverMaps = list.map((e) => Map<String, dynamic>.from(e)).toList();
          await _storageService.saveCachedServerOpenBills(serverMaps);
        }

        final serverList = list.map((e) => OpenBillModel.fromJson(e)).toList();

        // Filter out ID yang telah diselesaikan saat offline atau sedang aktif di offline bills
        final activeServerList = serverList
            .where((b) => !completedIds.contains(b.id) && !offlineIds.contains(b.id))
            .toList();

        // Gabungkan: Bill offline di atas, disusul bill server aktif
        openBills.assignAll([...filterList(offlineList), ...filterList(activeServerList)]);

        // Update count di PosController
        if (Get.isRegistered<PosController>()) {
          Get.find<PosController>().fetchOpenBillsCount();
        }
      } else {
        openBills.assignAll(filterList(combinedLocal));
      }
    } catch (e) {
      // Fallback offline saat request jaringan gagal: tampilkan gabungan offline + snapshot server
      final completedIds = _storageService.getOfflineCompletedServerBillIds();
      final rawOffline = _storageService.getOfflineOpenBills();
      final offlineList = rawOffline
          .map((e) {
            final map = Map<String, dynamic>.from(e);
            map['is_offline'] = true;
            return OpenBillModel.fromJson(map);
          })
          .where((b) => !completedIds.contains(b.id))
          .toList();

      final offlineIds = offlineList.map((b) => b.id).toSet();
      final rawCachedServer = _storageService.getCachedServerOpenBills();
      final cachedServerList = rawCachedServer
          .map((e) => OpenBillModel.fromJson(e))
          .where((b) => !completedIds.contains(b.id) && !offlineIds.contains(b.id))
          .toList();
      final combined = [...offlineList, ...cachedServerList];

      final query = searchQuery.value.trim().toLowerCase();
      if (query.isNotEmpty) {
        openBills.assignAll(
          combined.where((b) {
            final table = (b.tableNumber ?? '').toLowerCase();
            final cust = (b.customerName ?? '').toLowerCase();
            final inv = b.invoiceNumber.toLowerCase();
            return table.contains(query) ||
                cust.contains(query) ||
                inv.contains(query);
          }).toList(),
        );
      } else {
        openBills.assignAll(combined);
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Buka kembali bill pesanan ke keranjang kasir (Resume Bill)
  Future<void> resumeBill(OpenBillModel bill) async {
    isLoading.value = true;
    try {
      OpenBillModel detailedBill = bill;

      // Jika bill dibuat secara online dan memiliki ID > 0, coba ambil data detail
      if (bill.id > 0 && !_storageService.isOfflineToken) {
        try {
          final response = await _apiProvider.get(
            ApiConstants.openBillDetail(bill.id),
          );
          if (response.data != null &&
              response.data['success'] == true &&
              response.data['data'] != null) {
            detailedBill = OpenBillModel.fromJson(response.data['data']);
          }
        } catch (_) {
          detailedBill = bill;
        }
      }

      final cartController = Get.find<CartController>();
      final posController = Get.find<PosController>();

      cartController.loadFromOpenBill(detailedBill, posController.products);

      // Kembali ke layar POS
      Get.back();

      // Refresh counter
      if (Get.isRegistered<PosController>()) {
        Get.find<PosController>().fetchOpenBillsCount();
      }

      AppSnackbar.success(
        'Bill Dimuat',
        'Pesanan ${bill.billTitle} berhasil dimasukkan ke keranjang kasir.',
      );
    } catch (e) {
      AppSnackbar.danger('Gagal Memuat Bill', ApiProvider.getErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  /// Batalkan / Void Open Bill
  Future<void> cancelBill(OpenBillModel bill) async {
    isLoading.value = true;
    try {
      // 1. Jika bill murni offline (ID < 0)
      if (bill.id < 0) {
        await _storageService.removeOfflineOpenBill(bill.id);

        if (bill.tableNumber != null && bill.tableNumber!.isNotEmpty) {
          if (Get.isRegistered<PosController>()) {
            Get.find<PosController>().freeTable(bill.tableNumber!);
          }
        }

        AppSnackbar.success(
          'Bill Dibatalkan',
          'Bill offline berhasil dibatalkan.',
        );
        await fetchOpenBills();
        return;
      }

      // 2. Jika offline mode tapi bill berasal dari server (ID > 0)
      if (_storageService.isOfflineToken) {
        await _storageService.removeOfflineOpenBill(bill.id);
        await _storageService.removeCachedServerOpenBill(bill.id);
        await _storageService.addOfflineCompletedServerBillId(bill.id);

        if (bill.tableNumber != null && bill.tableNumber!.isNotEmpty) {
          if (Get.isRegistered<PosController>()) {
            Get.find<PosController>().freeTable(bill.tableNumber!);
          }
        }

        AppSnackbar.success(
          'Bill Dibatalkan',
          'Bill server dibatalkan secara lokal (Offline).',
        );
        await fetchOpenBills();
        return;
      }

      // 3. Jika online, batalkan ke server
      final response = await _apiProvider.post(
        ApiConstants.cancelOpenBill(bill.id),
      );
      if (response.data != null && response.data['success'] == true) {
        await _storageService.removeOfflineOpenBill(bill.id);
        await _storageService.removeCachedServerOpenBill(bill.id);
        if (bill.tableNumber != null && bill.tableNumber!.isNotEmpty) {
          if (Get.isRegistered<PosController>()) {
            Get.find<PosController>().freeTable(bill.tableNumber!);
          }
        }

        AppSnackbar.success(
          'Bill Dibatalkan',
          response.data['message'] ?? 'Bill berhasil dibatalkan.',
        );
        await fetchOpenBills();
      } else {
        AppSnackbar.danger(
          'Gagal Membatalkan',
          response.data['message'] ?? 'Terjadi kesalahan.',
        );
      }
    } catch (e) {
      // Fallback jika request server gagal: hapus dari penyimpanan lokal
      await _storageService.removeOfflineOpenBill(bill.id);
      if (bill.id > 0) {
        await _storageService.removeCachedServerOpenBill(bill.id);
        await _storageService.addOfflineCompletedServerBillId(bill.id);
      }

      if (bill.tableNumber != null && bill.tableNumber!.isNotEmpty) {
        if (Get.isRegistered<PosController>()) {
          Get.find<PosController>().freeTable(bill.tableNumber!);
        }
      }
      AppSnackbar.warning(
        'Bill Dibatalkan (Offline)',
        'Kendala koneksi. Bill dibatalkan di penyimpanan lokal kasir.',
      );
      await fetchOpenBills();
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    fetchOpenBills();
  }

  /// Cetak struk tagihan bill ke printer Bluetooth atau tampilkan preview
  Future<void> printBill(OpenBillModel bill) async {
    try {
      OpenBillModel detailedBill = bill;

      // Jika bill belum memiliki rincian item, coba muat detail dari server
      if (detailedBill.details.isEmpty && detailedBill.id > 0 && !_storageService.isOfflineToken) {
        try {
          final response = await _apiProvider.get(ApiConstants.openBillDetail(bill.id));
          if (response.data != null && response.data['success'] == true && response.data['data'] != null) {
            detailedBill = OpenBillModel.fromJson(response.data['data']);
          }
        } catch (_) {}
      }

      final payload = _buildOpenBillReceiptPayload(detailedBill);

      if (_printerService.isConnected.value) {
        final success = await _printerService.printReceipt(payload);
        if (success) {
          AppSnackbar.success('Cetak Struk', 'Struk tagihan ${bill.billTitle} berhasil dicetak.');
        }
      } else {
        ReceiptViewDialog.show(payload);
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Mencetak', 'Terjadi kesalahan saat memproses cetak struk: $e');
    }
  }

  /// Susun payload struk untuk Bill Aktif / Tagihan Meja
  Map<String, dynamic> _buildOpenBillReceiptPayload(OpenBillModel bill) {
    final posCtrl = Get.isRegistered<PosController>() ? Get.find<PosController>() : null;
    final cafeSettings = posCtrl?.cafeSettings.value;
    final shopName = (cafeSettings?.shopName.isNotEmpty == true)
        ? cafeSettings!.shopName
        : 'NOLI COFFEE & SPACE';
    final address = (cafeSettings?.address.isNotEmpty == true) ? cafeSettings!.address : '';
    final phone = cafeSettings?.phone ?? '';
    final cashierName = _storageService.user?.name ?? 'Kasir';

    String orderTypeStr = bill.orderType.toUpperCase();
    if (orderTypeStr.contains('DINE')) {
      final cleanTable = (bill.tableNumber ?? '').toUpperCase().replaceAll('MEJA', '').trim();
      orderTypeStr = cleanTable.isNotEmpty ? 'DINE IN (MEJA $cleanTable)' : 'DINE IN';
    } else if (orderTypeStr.contains('TAKE')) {
      orderTypeStr = 'TAKE AWAY (BUNGKUS)';
    }

    final double subtotal = bill.subtotal > 0
        ? bill.subtotal
        : bill.details.fold<double>(0.0, (sum, d) => sum + d.subtotal);

    return {
      'header': {
        'shop_name': shopName,
        'address': address,
        'phone': phone,
        'show_logo': false,
      },
      'invoice_number': bill.invoiceNumber,
      'date': bill.createdAt,
      'cashier_name': cashierName,
      'order_type': orderTypeStr,
      'table_number': bill.tableNumber,
      'customer_name': bill.customerName,
      'items': bill.details.map((d) => {
        'name': d.name,
        'quantity': d.quantity,
        'price': d.price,
        'subtotal': d.subtotal,
        'notes': d.notes,
        'addons': d.addons.map((a) => {'name': a.name, 'price': a.price}).toList(),
      }).toList(),
      'summary': {
        'subtotal': subtotal > 0 ? subtotal : bill.total,
        'discount': bill.discount,
        'tax': bill.tax,
        'total': bill.total,
        'payment_method': 'TAGIHAN (BILL)',
        'paid': 0.0,
        'change': 0.0,
      },
      'footer': {
        'message': '--- STRUK BILL / TAGIHAN ---\nBelum Termasuk Pembayaran',
        'wifi_name': cafeSettings?.wifiName,
        'wifi_password': cafeSettings?.wifiPassword,
      },
    };
  }
}

