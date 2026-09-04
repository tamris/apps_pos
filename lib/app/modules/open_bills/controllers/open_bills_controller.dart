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
      // 1. Ambil Open Bills yang tersimpan di penyimpanan offline lokal
      final rawOffline = _storageService.getOfflineOpenBills();
      final offlineList = rawOffline
          .map((e) => OpenBillModel.fromJson(e))
          .toList();

      // Filter pencarian offline
      final query = searchQuery.value.trim().toLowerCase();
      List<OpenBillModel> filteredOffline = offlineList;
      if (query.isNotEmpty) {
        filteredOffline = offlineList.where((b) {
          final table = (b.tableNumber ?? '').toLowerCase();
          final cust = (b.customerName ?? '').toLowerCase();
          final inv = b.invoiceNumber.toLowerCase();
          return table.contains(query) ||
              cust.contains(query) ||
              inv.contains(query);
        }).toList();
      }

      // Jika offline mode, langsung gunakan data lokal
      if (_storageService.isOfflineToken) {
        openBills.assignAll(filteredOffline);
        if (Get.isRegistered<PosController>()) {
          Get.find<PosController>().fetchOpenBillsCount();
        }
        return;
      }

      // 2. Jika online, ambil data dari server dan gabungkan dengan open bill offline
      final response = await _apiProvider.get(
        ApiConstants.openBills,
        queryParameters: query.isNotEmpty ? {'search': query} : null,
      );

      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        final serverList = list.map((e) => OpenBillModel.fromJson(e)).toList();

        // Gabungkan: Bill offline di atas, disusul bill server
        openBills.assignAll([...filteredOffline, ...serverList]);

        // Update count di PosController
        if (Get.isRegistered<PosController>()) {
          Get.find<PosController>().fetchOpenBillsCount();
        }
      } else {
        openBills.assignAll(filteredOffline);
      }
    } catch (e) {
      // Fallback offline saat request jaringan gagal
      final rawOffline = _storageService.getOfflineOpenBills();
      final offlineList = rawOffline
          .map((e) => OpenBillModel.fromJson(e))
          .toList();
      final query = searchQuery.value.trim().toLowerCase();
      if (query.isNotEmpty) {
        openBills.assignAll(
          offlineList.where((b) {
            final table = (b.tableNumber ?? '').toLowerCase();
            final cust = (b.customerName ?? '').toLowerCase();
            final inv = b.invoiceNumber.toLowerCase();
            return table.contains(query) ||
                cust.contains(query) ||
                inv.contains(query);
          }).toList(),
        );
      } else {
        openBills.assignAll(offlineList);
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
      // Jika bill offline (ID < 0), hapus langsung dari local storage
      if (bill.id < 0 || _storageService.isOfflineToken) {
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

      final response = await _apiProvider.post(
        ApiConstants.cancelOpenBill(bill.id),
      );
      if (response.data != null && response.data['success'] == true) {
        if (bill.tableNumber != null && bill.tableNumber!.isNotEmpty) {
          if (Get.isRegistered<PosController>()) {
            Get.find<PosController>().freeTable(bill.tableNumber!);
          }
        }

        AppSnackbar.success(
          'Bill Dibatalkan',
          response.data['message'] ?? 'Bill berhasil dibatalkan.',
        );
        fetchOpenBills();
      } else {
        AppSnackbar.danger(
          'Gagal Membatalkan',
          response.data['message'] ?? 'Terjadi kesalahan.',
        );
      }
    } catch (e) {
      // Jika request server gagal tapi bill ada di local offline, hapus dari local
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
      } else {
        AppSnackbar.danger('Gagal Membatalkan', ApiProvider.getErrorMessage(e));
      }
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

