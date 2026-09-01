import 'package:get/get.dart';
import '../../../data/models/shift_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../routes/app_routes.dart';

class ShiftController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final StorageService _storageService = Get.find<StorageService>();

  final Rx<ShiftModel?> currentShift = Rx<ShiftModel?>(null);
  final RxBool hasActiveShift = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load from cache first
    final cached = _storageService.activeShift;
    if (cached != null) {
      currentShift.value = cached;
      hasActiveShift.value = cached.isOpen;
    }
    fetchCurrentShift();
  }

  /// Ambil status shift aktif kasir saat ini
  Future<void> fetchCurrentShift() async {
    try {
      final response = await _apiProvider.get(ApiConstants.currentShift);
      if (response.data != null && response.data['success'] == true) {
        hasActiveShift.value = response.data['has_active_shift'] == true;
        if (response.data['data'] != null) {
          final shift = ShiftModel.fromJson(response.data['data']);
          currentShift.value = shift;
          await _storageService.saveActiveShift(shift);
        } else {
          currentShift.value = null;
          await _storageService.saveActiveShift(null);
        }
      }
    } catch (_) {}
  }

  /// Buka Shift Kasir dengan Modal Awal
  Future<bool> startShift(double startingCash) async {
    isLoading.value = true;
    try {
      final response = await _apiProvider.post(
        ApiConstants.startShift,
        data: {'starting_cash': startingCash},
      );

      if (response.data != null && response.data['success'] == true) {
        final shift = ShiftModel.fromJson(response.data['data']);
        currentShift.value = shift;
        hasActiveShift.value = true;
        await _storageService.saveActiveShift(shift);

        AppSnackbar.success(
          'Shift Kasir Dibuka',
          response.data['message'] ?? 'Shift kasir berhasil dibuka dengan sukses.',
        );
        return true;
      } else {
        AppSnackbar.danger(
          'Gagal Buka Shift',
          response.data['message'] ?? 'Terjadi kesalahan saat membuka shift.',
        );
        return false;
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Buka Shift', ApiProvider.getErrorMessage(e));
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Tutup Shift Kasir dengan Uang Fisik Riil
  Future<bool> endShift(double actualCash, String notes) async {
    isLoading.value = true;
    try {
      final response = await _apiProvider.post(
        ApiConstants.endShift,
        data: {
          'actual_cash': actualCash,
          'notes': notes,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        currentShift.value = null;
        hasActiveShift.value = false;
        await _storageService.saveActiveShift(null);

        AppSnackbar.success(
          'Shift Kasir Ditutup',
          response.data['message'] ?? 'Shift kasir berhasil ditutup.',
        );
        return true;
      } else {
        final msg = response.data['message']?.toString() ?? 'Terjadi kesalahan saat menutup shift.';
        final isOpenBillError = msg.toLowerCase().contains('bill') || msg.toLowerCase().contains('meja');

        if (isOpenBillError) {
          AppSnackbar.danger(
            'Gagal Tutup Shift',
            msg,
            actionLabel: 'Lihat Bill',
            onAction: () => Get.toNamed(AppRoutes.openBills),
          );
        } else {
          AppSnackbar.danger('Gagal Tutup Shift', msg);
        }
        return false;
      }
    } catch (e) {
      final errorMsg = ApiProvider.getErrorMessage(e);
      final isOpenBillError = errorMsg.toLowerCase().contains('bill') || errorMsg.toLowerCase().contains('meja');

      if (isOpenBillError) {
        AppSnackbar.danger(
          'Gagal Tutup Shift',
          errorMsg,
          actionLabel: 'Lihat Bill',
          onAction: () => Get.toNamed(AppRoutes.openBills),
        );
      } else {
        AppSnackbar.danger('Gagal Tutup Shift', errorMsg);
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}
