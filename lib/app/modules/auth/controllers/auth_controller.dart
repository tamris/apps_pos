import 'package:get/get.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/shift_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/storage_service.dart';
import '../../../core/constants/api_constants.dart';
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

  @override
  void onInit() {
    super.onInit();
    fetchCashiers();
  }

  /// Ambil daftar kasir aktif dari backend untuk pilihan cepat
  Future<void> fetchCashiers() async {
    isFetchingCashiers.value = true;
    try {
      final response = await _apiProvider.get(ApiConstants.cashiers);
      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        cashiers.assignAll(list.map((e) => UserModel.fromJson(e)).toList());
      }
    } catch (_) {
      // Fallback silent: kasir tetap bisa login langsung dengan PIN tanpa memilih avatar
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

  /// Submit PIN ke backend
  Future<void> loginWithPin() async {
    if (pin.value.length != 6) return;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final payload = {
        'pin': pin.value,
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

        // Simpan ke storage
        await _storageService.saveToken(token);
        await _storageService.saveUser(userData);
        await _storageService.saveActiveShift(activeShift);

        pin.value = '';
        Get.offAllNamed(AppRoutes.pos);
      } else {
        errorMessage.value = response.data['message'] ?? 'PIN tidak valid.';
        pin.value = '';
      }
    } catch (e) {
      errorMessage.value = ApiProvider.getErrorMessage(e);
      pin.value = '';
    } finally {
      isLoading.value = false;
    }
  }

  /// Logout kasir
  Future<void> logout() async {
    try {
      await _apiProvider.post(ApiConstants.logout);
    } catch (_) {}
    await _storageService.clearAuth();
    Get.offAllNamed(AppRoutes.pinLogin);
  }
}
