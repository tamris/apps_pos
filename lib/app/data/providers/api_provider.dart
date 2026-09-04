import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;
import '../services/storage_service.dart';
import '../../routes/app_routes.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/app_snackbar.dart';

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final dynamic errors;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic data)? fromData,
  ) {
    return ApiResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
      data: (json['data'] != null && fromData != null) ? fromData(json['data']) : json['data'] as T?,
      errors: json['errors'],
    );
  }
}

class ApiProvider extends getx.GetxService {
  late Dio _dio;
  final StorageService _storageService = getx.Get.find<StorageService>();

  @override
  void onInit() {
    super.onInit();
    _initDio();
  }

  void _initDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _storageService.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Always use dynamic current base url in case updated in settings
          options.baseUrl = _storageService.baseUrl;
          options.headers['ngrok-skip-browser-warning'] = 'true';
          final token = _storageService.token;
          if (token != null && token.isNotEmpty) {
            // Jangan kirim offline token ke server karena server Laravel pasti 401
            if (!_storageService.isOfflineToken) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          if (error.response?.statusCode == 401) {
            // Jika dalam mode offline, jangan logout paksa
            if (_storageService.isOfflineToken) {
              return handler.next(error);
            }

            // Token expired or invalid
            _storageService.clearAuth();
            if (getx.Get.currentRoute != AppRoutes.pinLogin) {
              getx.Get.offAllNamed(AppRoutes.pinLogin);
              AppSnackbar.warning(
                'Sesi Berakhir',
                'Sesi kasir telah berakhir. Silakan login kembali dengan PIN.',
              );
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Memastikan token valid sebelum request penting (seperti sync). Melakukan auto re-auth jika masih offline token.
  Future<bool> ensureAuthenticated() async {
    if (!_storageService.hasToken) return false;
    if (!_storageService.isOfflineToken) return true;

    final pin = _storageService.activePin;
    if (pin == null || pin.isEmpty) return false;

    try {
      final response = await _dio.post(
        ApiConstants.pinLogin,
        data: {
          'pin': pin,
          'device_name': 'POS-Mobile-App',
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final realToken = data['token'];
        if (realToken != null && realToken.toString().isNotEmpty) {
          await _storageService.saveToken(realToken.toString());
          return true;
        }
      }
    } catch (_) {
      // Server belum online
    }
    return false;
  }

  /// Reload Dio Base Options when user changes Server IP in Settings
  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
  }

  // GET Request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters, options: options);
    } catch (e) {
      rethrow;
    }
  }

  // POST Request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
    } catch (e) {
      rethrow;
    }
  }

  // DELETE Request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
    } catch (e) {
      rethrow;
    }
  }

  /// Ekstrak pesan kesalahan yang ramah pengguna (human-readable)
  static String getErrorMessage(dynamic error) {
    if (error == null) return 'Terjadi kesalahan tidak terduga. Silakan coba lagi.';

    final errorStr = error.toString().toLowerCase();

    // 1. Deteksi kendala koneksi / jaringan / timeout / browser CORS
    if (errorStr.contains('xmlhttprequest') ||
        errorStr.contains('connection error') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('connection timeout') ||
        errorStr.contains('socketexception') ||
        errorStr.contains('network layer') ||
        errorStr.contains('cross-origin') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('handshake') ||
        errorStr.contains('clientexception')) {
      return 'Gagal terhubung ke server. Periksa koneksi internet atau pastikan server backend aktif.';
    }

    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'Gagal terhubung ke server. Periksa koneksi internet atau pastikan server backend aktif.';
      }
      if (error.response?.data != null && error.response?.data is Map) {
        final data = error.response!.data as Map;
        if (data['message'] != null && data['message'].toString().isNotEmpty) {
          return data['message'].toString();
        }
      }
      if (error.response?.statusCode != null) {
        final code = error.response!.statusCode;
        if (code == 401) return 'Sesi login kasir telah kedaluwarsa. Silakan login ulang.';
        if (code == 403) return 'Akses ditolak. Anda tidak memiliki izin untuk fitur ini.';
        if (code == 404) return 'Data atau layanan yang diminta tidak ditemukan di server.';
        if (code == 500) return 'Terjadi kendala pada server backend (Error 500). Silakan coba lagi.';
        return 'Server memberikan respons tidak berhasil ($code).';
      }
      return 'Koneksi ke server terputus. Silakan coba beberapa saat lagi.';
    }

    // 2. Jika pesan error teknis sistem (exception/crash), jangan tampilkan stack trace mentah ke pengguna
    if (errorStr.contains('exception') || errorStr.contains('error:')) {
      return 'Terjadi kendala saat memproses permintaan. Silakan coba lagi.';
    }

    return error.toString();
  }
}
