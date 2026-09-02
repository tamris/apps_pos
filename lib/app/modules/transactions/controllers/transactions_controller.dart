import 'package:get/get.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/esc_pos_printer_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../views/widgets/receipt_view_dialog.dart';

class TransactionsController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final EscPosPrinterService _printerService = Get.find<EscPosPrinterService>();

  final RxList<TransactionModel> transactions = <TransactionModel>[].obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedStatus = 'completed'.obs; // 'completed', 'cancelled', 'all'
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTodayTransactions();
  }

  /// Ambil riwayat transaksi hari ini kasir
  Future<void> fetchTodayTransactions() async {
    isLoading.value = true;
    try {
      final response = await _apiProvider.get(
        ApiConstants.todayTransactions,
        queryParameters: {
          if (searchQuery.value.isNotEmpty) 'search': searchQuery.value,
          'status': selectedStatus.value,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final List list = (data is Map && data['data'] != null) ? data['data'] : (data is List ? data : []);
        transactions.assignAll(list.map((e) => TransactionModel.fromJson(e)).toList());
      }
    } catch (e) {
      AppSnackbar.danger('Riwayat Transaksi', ApiProvider.getErrorMessage(e));
    } finally {
      isLoading.value = false;
    }
  }

  /// Ambil data struk dan cetak ulang / tampilkan preview
  Future<void> printOrPreviewReceipt(int transactionId) async {
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
      AppSnackbar.danger('Gagal Cetak Ulang', ApiProvider.getErrorMessage(e));
    }
  }

  /// Tampilkan Pratinjau Kertas Struk
  Future<void> previewReceipt(int transactionId) async {
    try {
      final response = await _apiProvider.get(ApiConstants.receiptData(transactionId));
      if (response.data != null && response.data['success'] == true) {
        final payload = response.data['data'];
        ReceiptViewDialog.show(payload);
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Pratinjau Struk', ApiProvider.getErrorMessage(e));
    }
  }

  void onSearchChanged(String query) {
    searchQuery.value = query;
    fetchTodayTransactions();
  }

  void onStatusChanged(String status) {
    selectedStatus.value = status;
    fetchTodayTransactions();
  }
}
