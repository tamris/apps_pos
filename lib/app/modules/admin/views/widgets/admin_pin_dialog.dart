import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/providers/api_provider.dart';
import '../../../../data/services/storage_service.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';

class AdminPinDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const AdminPinDialog({super.key, required this.onSuccess});

  static Future<void> show(BuildContext context, {required VoidCallback onSuccess}) async {
    final storage = Get.find<StorageService>();
    final currentUser = storage.user;

    // Jika user saat ini sudah ber-role admin atau owner, langsung lolos tanpa minta PIN ulang
    if (currentUser != null && currentUser.isAdmin) {
      onSuccess();
      return;
    }

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AdminPinDialog(onSuccess: onSuccess),
    );
  }

  @override
  State<AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<AdminPinDialog> {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final StorageService _storageService = Get.find<StorageService>();

  String _pin = '';
  bool _isLoading = false;
  String? _errorMessage;

  void _onKeyTap(String val) {
    if (_isLoading) return;
    if (_pin.length < 6) {
      setState(() {
        _pin += val;
        _errorMessage = null;
      });

      if (_pin.length == 6) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_isLoading) return;
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onClear() {
    if (_isLoading) return;
    setState(() {
      _pin = '';
      _errorMessage = null;
    });
  }

  Future<void> _verifyPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiProvider.post(
        ApiConstants.pinLogin,
        data: {
          'pin': _pin,
          'device_name': 'Admin-Owner-Hub',
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final userData = UserModel.fromJson(data['user']);

        if (!userData.isAdmin) {
          setState(() {
            _errorMessage = 'Akses Ditolak: Akun (${userData.name}) bukan Admin / Owner.';
            _pin = '';
            _isLoading = false;
          });
          return;
        }

        // Simpan token admin untuk request berikutnya
        final token = data['token'];
        if (token != null && token.toString().isNotEmpty) {
          await _storageService.saveToken(token.toString());
          await _storageService.saveUser(userData);
        }

        if (mounted) {
          Navigator.of(context).pop();
        }

        widget.onSuccess();
        AppSnackbar.success(
          'Otoritas Terverifikasi',
          'Selamat datang di Panel Owner & Admin, ${userData.name}.',
        );
      } else {
        setState(() {
          _errorMessage = response.data?['message'] ?? 'PIN Admin / Owner tidak valid.';
          _pin = '';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = ApiProvider.getErrorMessage(e);
        _pin = '';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    color: AppColors.secondary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Verifikasi Otoritas Admin',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Masukkan 6-digit PIN Admin / Owner untuk mengakses fitur finansial & otoritas toko.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 20),

                // PIN Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    final isFilled = index < _pin.length;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? AppColors.secondary : Colors.grey.shade300,
                        border: Border.all(
                          color: isFilled ? AppColors.secondary : Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 16),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Numeric Keypad
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: CircularProgressIndicator(),
                  )
                else
                  _buildKeypad(),

                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeyRow(['1', '2', '3']),
        const SizedBox(height: 10),
        _buildKeyRow(['4', '5', '6']),
        const SizedBox(height: 10),
        _buildKeyRow(['7', '8', '9']),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildKeypadButton(
              child: const Text('C', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.danger)),
              onTap: _onClear,
            ),
            _buildKeypadButton(
              child: const Text('0', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              onTap: () => _onKeyTap('0'),
            ),
            _buildKeypadButton(
              child: const Icon(Icons.backspace_outlined, size: 20, color: AppColors.textPrimary),
              onTap: _onDelete,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyRow(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: values.map((val) {
        return _buildKeypadButton(
          child: Text(
            val,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          onTap: () => _onKeyTap(val),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton({required Widget child, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 64,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.keypadButton,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      ),
    );
  }
}
