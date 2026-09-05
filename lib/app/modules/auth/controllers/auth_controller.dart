import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/shift_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../routes/app_routes.dart';

class AuthController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final StorageService _storageService = Get.find<StorageService>();

  final RxList<UserModel> cashiers = <UserModel>[].obs;
  final Rx<UserModel?> selectedCashier = Rx<UserModel?>(null);
  final RxString pin = ''.obs;
  final RxBool isLoading = false.obs;
  final RxBool isFetchingCashiers = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool isOfflineMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Load cached cashiers first so avatars appear immediately
    final cached = _storageService.getCachedCashiers();
    if (cached.isNotEmpty) {
      cashiers.assignAll(cached);
    }
    fetchCashiers();
  }

  /// Ambil daftar kasir aktif dari backend untuk pilihan cepat
  Future<void> fetchCashiers() async {
    isFetchingCashiers.value = true;
    try {
      final response = await _apiProvider.get(ApiConstants.cashiers);
      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        final parsedCashiers = list.map((e) => UserModel.fromJson(e)).toList();
        cashiers.assignAll(parsedCashiers);
        await _storageService.saveCachedCashiers(parsedCashiers);
        isOfflineMode.value = false;
      }
    } catch (_) {
      // Fallback offline: gunakan kasir dari storage
      final cached = _storageService.getCachedCashiers();
      if (cached.isNotEmpty) {
        cashiers.assignAll(cached);
      }
      isOfflineMode.value = true;
    } finally {
      isFetchingCashiers.value = false;
    }
  }

  void selectCashier(UserModel? cashier) {
    if (selectedCashier.value?.id == cashier?.id) {
      selectedCashier.value = null;
    } else {
      selectedCashier.value = cashier;
    }
    pin.value = '';
    errorMessage.value = '';
  }

  void onNumberPress(int number) {
    if (pin.value.length < 6 && !isLoading.value) {
      pin.value += number.toString();
      errorMessage.value = '';
      if (pin.value.length == 6) {
        loginWithPin();
      }
    }
  }

  void onBackspacePress() {
    if (pin.value.isNotEmpty && !isLoading.value) {
      pin.value = pin.value.substring(0, pin.value.length - 1);
      errorMessage.value = '';
    }
  }

  void onClearPress() {
    if (!isLoading.value) {
      pin.value = '';
      errorMessage.value = '';
    }
  }

  /// Submit PIN ke backend atau verifikasi offline PIN jika server tidak dapat dihubungi
  Future<void> loginWithPin() async {
    if (pin.value.length != 6) return;

    isLoading.value = true;
    errorMessage.value = '';
    final enteredPin = pin.value;

    try {
      final payload = {
        'pin': enteredPin,
        'device_name': 'POS-Mobile-App',
      };

      final response = await _apiProvider.post(
        ApiConstants.pinLogin,
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final token = data['token'];
        final userData = UserModel.fromJson(data['user']);
        ShiftModel? activeShift;
        if (data['active_shift'] != null) {
          activeShift = ShiftModel.fromJson(data['active_shift']);
        }

        // Simpan ke storage (termasuk hash PIN dan activePin untuk login offline / auto re-auth)
        await _storageService.saveToken(token);
        await _storageService.saveUser(userData);
        await _storageService.saveActiveShift(activeShift);
        await _storageService.saveCashierPinHash(userData.id, enteredPin);
        await _storageService.saveActivePin(enteredPin);

        pin.value = '';
        if (userData.isAdmin) {
          Get.offAllNamed(AppRoutes.admin);
        } else {
          Get.offAllNamed(AppRoutes.pos);
        }
      } else {
        errorMessage.value = response.data['message'] ?? 'PIN tidak valid.';
        pin.value = '';
      }
    } catch (e) {
      // Cek apakah error adalah masalah koneksi jaringan (offline)
      final bool isNetworkIssue = _isNetworkError(e);

      if (isNetworkIssue) {
        // Coba Offline PIN Auth dari cache lokal
        final matchedUser = _storageService.verifyOfflinePin(
          enteredPin,
          selectedCashier.value?.id,
        );

        if (matchedUser != null) {
          // Berhasil login offline!
          await _storageService.saveToken(
            'offline_token_${matchedUser.id}_${DateTime.now().millisecondsSinceEpoch}',
          );
          await _storageService.saveUser(matchedUser);
          await _storageService.saveActivePin(enteredPin);

          pin.value = '';
          if (matchedUser.isAdmin) {
            Get.offAllNamed(AppRoutes.admin);
          } else {
            Get.offAllNamed(AppRoutes.pos);
          }
          AppSnackbar.warning(
            'Mode Offline',
            'Masuk sebagai ${matchedUser.name} dalam mode offline lokal.',
          );
          return;
        } else {
          errorMessage.value =
              'Koneksi server gagal & PIN belum pernah login online di perangkat ini.';
          pin.value = '';
        }
      } else {
        errorMessage.value = ApiProvider.getErrorMessage(e);
        pin.value = '';
      }
    } finally {
      isLoading.value = false;
    }
  }

  bool _isNetworkError(dynamic e) {
    if (e is DioException) {
      return e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown;
    }
    return true;
  }

  /// Logout kasir
  Future<void> logout() async {
    try {
      if (!_storageService.isOfflineToken) {
        await _apiProvider.post(ApiConstants.logout);
      }
    } catch (_) {}
    await _storageService.clearAuth();
    Get.offAllNamed(AppRoutes.pinLogin);
  }
}
