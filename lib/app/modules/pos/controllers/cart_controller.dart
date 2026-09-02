import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/cart_item_model.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/open_bill_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/offline_sync_service.dart';
import '../../../data/services/esc_pos_printer_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import 'pos_controller.dart';
import '../views/widgets/payment_success_dialog.dart';
import '../../shift/controllers/shift_controller.dart';
import '../../shift/views/shift_dialogs.dart';

class CartController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final StorageService _storageService = Get.find<StorageService>();
  final OfflineSyncService _offlineSyncService = Get.find<OfflineSyncService>();
  final EscPosPrinterService _printerService = Get.find<EscPosPrinterService>();

  final RxList<CartItemModel> items = <CartItemModel>[].obs;
  final RxString orderType = 'dine_in'.obs; // 'dine_in', 'take_away', 'delivery'
  final RxString tableNumber = ''.obs;
  final RxString customerName = ''.obs;

  final RxDouble discountPercent = 0.0.obs;
  final RxDouble taxPercent = 0.0.obs;
  final RxString paymentMethod = 'cash'.obs; // 'cash', 'qris', 'transfer', 'debit'
  final RxDouble paidAmount = 0.0.obs;

  final Rx<int?> activeOpenBillId = Rx<int?>(null);
  final RxBool isProcessing = false.obs;

  // --- Kalkulasi Realtime ---
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get discountAmount => (subtotal * discountPercent.value) / 100.0;
  double get taxAmount => (max(0.0, subtotal - discountAmount) * taxPercent.value) / 100.0;
  double get grandTotal => max(0.0, subtotal - discountAmount + taxAmount);
  double get changeAmount => (paymentMethod.value == 'cash') ? max(0.0, paidAmount.value - grandTotal) : 0.0;
  int get totalItemsCount => items.fold(0, (sum, item) => sum + item.quantity);
  bool get isCartEmpty => items.isEmpty;

  /// Tambah item ke keranjang (dengan custom gula, es, catatan)
  void addItem(
    ProductModel product, {
    int quantity = 1,
    String sugarLevel = 'Normal',
    String iceLevel = 'Normal Ice',
    String notes = '',
  }) {
    final newItem = CartItemModel(
      product: product,
      quantity: quantity,
      sugarLevel: sugarLevel,
      iceLevel: iceLevel,
      notes: notes,
    );

    // Cek apakah item dengan konfigurasi yang sama persis sudah ada di keranjang
    final existingIndex = items.indexWhere((item) => item.itemKey == newItem.itemKey);
    if (existingIndex != -1) {
      items[existingIndex].quantity += quantity;
      items.refresh();
    } else {
      items.add(newItem);
    }
  }

  /// Tambah kuantitas item
  void increaseQuantity(int index) {
    if (index >= 0 && index < items.length) {
      items[index].quantity++;
      items.refresh();
    }
  }

  /// Kurangi kuantitas item
  void decreaseQuantity(int index) {
    if (index >= 0 && index < items.length) {
      if (items[index].quantity > 1) {
        items[index].quantity--;
        items.refresh();
      } else {
        removeItem(index);
      }
    }
  }

  /// Hapus item dari keranjang
  void removeItem(int index) {
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
    }
  }

  /// Perbarui kustomisasi/kuantitas item yang sudah ada di keranjang
  void updateItem(int index, CartItemModel updatedItem) {
    if (index >= 0 && index < items.length) {
      items[index] = updatedItem;
      items.refresh();
    }
  }

  /// Kosongkan seluruh keranjang & reset bill aktif
  void clearCart() {
    items.clear();
    discountPercent.value = 0.0;
    taxPercent.value = 0.0;
    paidAmount.value = 0.0;
    tableNumber.value = '';
    customerName.value = '';
    activeOpenBillId.value = null;
    orderType.value = 'dine_in';
  }

  /// Set tipe pesanan & nomor meja
  void setOrderDetails({required String type, String? table, String? name}) {
    orderType.value = type;
    tableNumber.value = table ?? '';
    customerName.value = name ?? '';
  }

  /// Set nominal bayar langsung (preset uang pas / quick cash)
  void setPaidAmount(double amount) {
    paidAmount.value = amount;
  }

  /// Muat data dari Open Bill ke dalam keranjang (Resume Bill)
  void loadFromOpenBill(OpenBillModel bill, List<ProductModel> allProducts) {
    clearCart();
    activeOpenBillId.value = bill.id;
    orderType.value = bill.orderType;
    tableNumber.value = bill.tableNumber ?? '';
    customerName.value = bill.customerName ?? '';
    discountPercent.value = bill.discount > 0 && bill.subtotal > 0
        ? ((bill.discount / bill.subtotal) * 100).roundToDouble()
        : 0.0;
    taxPercent.value = bill.tax > 0 && (bill.subtotal - bill.discount) > 0
        ? ((bill.tax / (bill.subtotal - bill.discount)) * 100).roundToDouble()
        : 0.0;

    for (var detail in bill.details) {
      // 1. Cari produk berdasarkan ID yang valid
      ProductModel? matchedProduct;
      if (detail.productId > 0) {
        matchedProduct = allProducts.firstWhereOrNull((p) => p.id == detail.productId);
      }

      // 2. Jika tidak ditemukan berdasarkan ID, cari berdasarkan Nama
      if (matchedProduct == null && detail.name.isNotEmpty) {
        matchedProduct = allProducts.firstWhereOrNull(
          (p) => p.name.trim().toLowerCase() == detail.name.trim().toLowerCase(),
        );
      }

      final finalProduct = matchedProduct ??
          ProductModel(
            id: detail.productId > 0 ? detail.productId : (allProducts.isNotEmpty ? allProducts.first.id : 1),
            categoryId: 0,
            categoryName: 'Menu',
            name: detail.name,
            price: detail.price,
          );

      items.add(CartItemModel(
        product: finalProduct,
        quantity: detail.quantity,
        price: detail.price,
        notes: detail.notes ?? '',
      ));
    }
  }

  /// Simpan / Tahan Pesanan sebagai Open Bill (Meja / Nama Pelanggan)
  Future<bool> saveOpenBill({BuildContext? context}) async {
    if (isCartEmpty) {
      return false;
    }

    // Periksa apakah shift kasir sudah dibuka
    if (Get.isRegistered<ShiftController>() && context != null) {
      final shiftCtrl = Get.find<ShiftController>();
      if (!shiftCtrl.hasActiveShift.value) {
        final opened = await ShiftDialogs.showStartShiftDialog(context);
        if (!opened) return false; // Kasir membatalkan buka shift
      }
    }

    if (orderType.value == 'dine_in' && tableNumber.value.isEmpty && customerName.value.isEmpty) {
      AppSnackbar.warning('Pilih Meja', 'Silakan pilih Nomor Meja atau isi Nama Pelanggan untuk Simpan Bill.');
      return false;
    }

    isProcessing.value = true;
    try {
      final payload = {
        'order_type': orderType.value,
        'table_number': tableNumber.value.isNotEmpty ? tableNumber.value : null,
        'customer_name': customerName.value.isNotEmpty ? customerName.value : null,
        'discount_percent': discountPercent.value,
        'tax_percent': taxPercent.value,
        'items': items.map((e) => e.toApiJson()).toList(),
        if (activeOpenBillId.value != null) 'open_bill_id': activeOpenBillId.value,
      };

      final response = await _apiProvider.post(
        ApiConstants.openBills,
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        if (Get.isRegistered<PosController>()) {
          final posCtrl = Get.find<PosController>();
          if (tableNumber.value.isNotEmpty) {
            posCtrl.markTableOccupied(tableNumber.value);
          }
        }

        AppSnackbar.success('Bill Tersimpan', 'Pesanan open bill meja berhasil disimpan.');
        clearCart();
        return true;
      } else {
        AppSnackbar.danger('Gagal Simpan Bill', response.data['message'] ?? 'Terjadi kesalahan.');
        return false;
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Simpan Bill', ApiProvider.getErrorMessage(e));
      return false;
    } finally {
      isProcessing.value = false;
    }
  }

  /// Proses Checkout / Pembayaran Transaksi
  Future<bool> processCheckout({BuildContext? context}) async {
    if (isCartEmpty) {
      AppSnackbar.warning('Keranjang Kosong', 'Pilih menu terlebih dahulu untuk checkout.');
      return false;
    }

    if (paymentMethod.value == 'cash' && paidAmount.value < grandTotal) {
      AppSnackbar.warning('Uang Kurang', 'Jumlah bayar kurang dari total tagihan.');
      return false;
    }

    isProcessing.value = true;
    final itemsPayload = items.map((e) => e.toApiJson()).toList();
    final savedTable = tableNumber.value;
    final savedCustomer = customerName.value;
    final currentOrderType = orderType.value;
    final currentPaymentMethod = paymentMethod.value;
    final currentPaid = (currentPaymentMethod == 'cash') ? paidAmount.value : grandTotal;

    try {
      final payload = {
        'order_type': currentOrderType,
        'table_number': savedTable.isNotEmpty ? savedTable : null,
        'customer_name': savedCustomer.isNotEmpty ? savedCustomer : null,
        'payment_method': currentPaymentMethod,
        'discount_percent': discountPercent.value,
        'tax_percent': taxPercent.value,
        'paid': currentPaid,
        'items': itemsPayload,
        if (activeOpenBillId.value != null) 'open_bill_id': activeOpenBillId.value,
      };

      final response = await _apiProvider.post(
        ApiConstants.checkout,
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        final txData = response.data['data'];
        final receiptPayload = response.data['receipt_payload'];

        // Auto print jika printer bluetooth terhubung
        if (_printerService.isConnected.value && receiptPayload != null) {
          _printerService.printReceipt(receiptPayload);
        }

        // Bebaskan meja jika sebelumnya open bill / dine in
        if (Get.isRegistered<PosController>()) {
          final posCtrl = Get.find<PosController>();
          if (savedTable.isNotEmpty) {
            posCtrl.freeTable(savedTable);
          }
        }

        // Kitchen Payload untuk cetak struk dapur
        final kitchenPayload = {
          'invoice_number': txData['invoice_number'] ?? 'INV',
          'date': DateTime.now().toString().substring(0, 16),
          'order_type': currentOrderType,
          'table_number': savedTable.isNotEmpty ? savedTable : null,
          'customer_name': savedCustomer.isNotEmpty ? savedCustomer : null,
          'items': itemsPayload,
        };

        // Tampilkan dialog sukses transaksi
        PaymentSuccessDialog.show(
          invoiceNumber: txData['invoice_number'] ?? 'INV',
          total: grandTotal,
          paid: currentPaid,
          change: (currentPaymentMethod == 'cash') ? max(0.0, currentPaid - grandTotal) : 0.0,
          paymentMethod: currentPaymentMethod.toUpperCase(),
          isOffline: false,
          receiptPayload: receiptPayload,
          kitchenPayload: kitchenPayload,
        );

        clearCart();
        return true;
      } else {
        AppSnackbar.danger('Transaksi Gagal', response.data['message'] ?? 'Terjadi kesalahan checkout.');
        return false;
      }
    } catch (e) {
      // Offline fallback: jika error koneksi, simpan ke queue offline
      final offlineId = await _offlineSyncService.enqueueTransaction(
        orderType: currentOrderType,
        tableNumber: savedTable.isNotEmpty ? savedTable : null,
        customerName: savedCustomer.isNotEmpty ? savedCustomer : null,
        paymentMethod: currentPaymentMethod,
        discountPercent: discountPercent.value,
        taxPercent: taxPercent.value,
        paid: currentPaid,
        items: itemsPayload,
      );

      AppSnackbar.warning(
        'Tersimpan Offline',
        'Transaksi disimpan di antrean offline lokal ($offlineId) karena kendala koneksi.',
      );

      final posCtrl = Get.isRegistered<PosController>() ? Get.find<PosController>() : null;
      final cafeName = (posCtrl?.cafeSettings.value.shopName.isNotEmpty == true)
          ? posCtrl!.cafeSettings.value.shopName
          : 'NOLI COFFE & SPACE';
      final cafeAddress = (posCtrl?.cafeSettings.value.address.isNotEmpty == true)
          ? posCtrl!.cafeSettings.value.address
          : 'POS Kasir (Offline)';
      final cashierName = _storageService.user?.name ?? 'Kasir';

      final offlineKitchenPayload = {
        'invoice_number': offlineId,
        'date': DateTime.now().toString().substring(0, 16),
        'order_type': currentOrderType,
        'table_number': savedTable.isNotEmpty ? savedTable : null,
        'customer_name': savedCustomer.isNotEmpty ? savedCustomer : null,
        'items': itemsPayload,
      };

      final offlineReceiptPayload = {
        'header': {'shop_name': cafeName, 'address': cafeAddress},
        'invoice_number': offlineId,
        'date': DateTime.now().toString().substring(0, 16),
        'cashier_name': cashierName,
        'order_type': currentOrderType,
        'table_number': savedTable.isNotEmpty ? savedTable : null,
        'customer_name': savedCustomer.isNotEmpty ? savedCustomer : null,
        'items': itemsPayload,
        'summary': {
          'subtotal': subtotal,
          'discount': discountAmount,
          'tax': taxAmount,
          'total': grandTotal,
          'payment_method': currentPaymentMethod.toUpperCase(),
          'paid': currentPaid,
          'change': (currentPaymentMethod == 'cash') ? max(0.0, currentPaid - grandTotal) : 0.0,
        },
      };

      PaymentSuccessDialog.show(
        invoiceNumber: offlineId,
        total: grandTotal,
        paid: currentPaid,
        change: (currentPaymentMethod == 'cash') ? max(0.0, currentPaid - grandTotal) : 0.0,
        paymentMethod: '$currentPaymentMethod (OFFLINE)'.toUpperCase(),
        isOffline: true,
        receiptPayload: offlineReceiptPayload,
        kitchenPayload: offlineKitchenPayload,
      );

      clearCart();
      return true;
    } finally {
      isProcessing.value = false;
    }
  }
}
