import 'package:get/get.dart';
import '../../../data/models/open_bill_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../pos/controllers/cart_controller.dart';
import '../../pos/controllers/pos_controller.dart';

class OpenBillsController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  final RxList<OpenBillModel> openBills = <OpenBillModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchOpenBills();
  }

  /// Ambil daftar seluruh bill aktif (pending)
  Future<void> fetchOpenBills() async {
    isLoading.value = true;
    try {
      final response = await _apiProvider.get(
        ApiConstants.openBills,
        queryParameters: searchQuery.value.isNotEmpty ? {'search': searchQuery.value} : null,
      );

      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        openBills.assignAll(list.map((e) => OpenBillModel.fromJson(e)).toList());
        
        // Update count di PosController
        if (Get.isRegistered<PosController>()) {
          Get.find<PosController>().activeOpenBillsCount.value = openBills.length;
        }
      }
    } catch (e) {
      AppSnackbar.danger('Open Bills', ApiProvider.getErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  /// Buka kembali bill pesanan ke keranjang kasir (Resume Bill)
  Future<void> resumeBill(OpenBillModel bill) async {
    isLoading.value = true;
    try {
      OpenBillModel detailedBill = bill;

      // Coba ambil data detail jika endpoint spesifik tersedia
      try {
        final response = await _apiProvider.get(ApiConstants.openBillDetail(bill.id));
        if (response.data != null && response.data['success'] == true && response.data['data'] != null) {
          detailedBill = OpenBillModel.fromJson(response.data['data']);
        }
      } catch (_) {
        // Fallback: gunakan data bill yang sudah dimuat di list
        detailedBill = bill;
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
      final response = await _apiProvider.post(ApiConstants.cancelOpenBill(bill.id));
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
        AppSnackbar.danger('Gagal Membatalkan', response.data['message'] ?? 'Terjadi kesalahan.');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Membatalkan', ApiProvider.getErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    fetchOpenBills();
  }
}
