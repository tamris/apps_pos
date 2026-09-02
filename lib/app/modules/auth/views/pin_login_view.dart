import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/providers/api_provider.dart';

class PinLoginView extends StatelessWidget {
  const PinLoginView({super.key});

  AuthController get controller =>
      Get.isRegistered<AuthController>() ? Get.find<AuthController>() : Get.put(AuthController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Konfigurasi IP Backend',
            icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () => _showServerConfigDialog(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isTablet = constraints.maxWidth >= 600;
            return Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isTablet ? 420 : double.infinity),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo & Header
                      _buildHeader(),
                      _buildOfflineBadge(),
                      const SizedBox(height: 28),

                      // 6-Digit PIN Indicator Dots
                      _buildPinDots(),
                      const SizedBox(height: 12),

                      // Error message display
                      _buildErrorMessage(),
                      const SizedBox(height: 16),

                      // Numeric Keypad
                      _buildKeypad(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.lightBorder, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/icons/app_icon.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.point_of_sale_rounded,
                color: AppColors.primary,
                size: 36,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Noli POS Kasir',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Masukkan 6 digit PIN kasir untuk login',
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildOfflineBadge() {
    return Obx(() {
      if (!controller.isOfflineMode.value) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 14, color: Colors.amber.shade800),
            const SizedBox(width: 6),
            Text(
              'Mode Offline (Lokal)',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade900,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPinDots() {
    return Obx(() {
      final pinLength = controller.pin.value.length;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          final isFilled = index < pinLength;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            width: isFilled ? 18 : 14,
            height: isFilled ? 18 : 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled ? AppColors.primary : Colors.white,
              border: Border.all(
                color: isFilled ? AppColors.primary : AppColors.lightBorder,
                width: 2,
              ),
              boxShadow: isFilled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(102),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
          );
        }),
      );
    });
  }

  Widget _buildErrorMessage() {
    return Obx(() {
      if (controller.errorMessage.value.isEmpty) {
        return const SizedBox(height: 20);
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.dangerSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                controller.errorMessage.value,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildKeypad() {
    return Obx(() {
      final isLoading = controller.isLoading.value;

      return IgnorePointer(
        ignoring: isLoading,
        child: Opacity(
          opacity: isLoading ? 0.6 : 1.0,
          child: Column(
            children: [
              _buildKeypadRow([1, 2, 3]),
              const SizedBox(height: 12),
              _buildKeypadRow([4, 5, 6]),
              const SizedBox(height: 12),
              _buildKeypadRow([7, 8, 9]),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionKey(
                    label: 'C',
                    onTap: controller.onClearPress,
                    color: AppColors.textSecondary,
                  ),
                  _buildNumberKey(0),
                  _buildActionKey(
                    icon: Icons.backspace_outlined,
                    onTap: controller.onBackspacePress,
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildKeypadRow(List<int> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((n) => _buildNumberKey(n)).toList(),
    );
  }

  Widget _buildNumberKey(int number) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => controller.onNumberPress(number),
        child: Container(
          width: 76,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightBorder, width: 1.2),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionKey({
    String? label,
    IconData? icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: AppColors.keypadButton,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 76,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.lightBorder, width: 1.2),
          ),
          alignment: Alignment.center,
          child: label != null
              ? Text(
                  label,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                )
              : Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }

  void _showServerConfigDialog(BuildContext context) {
    final storageService = Get.find<StorageService>();
    final apiProvider = Get.find<ApiProvider>();
    final textController = TextEditingController(text: storageService.baseUrl);

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.cloud_outlined, color: AppColors.primary),
            SizedBox(width: 10),
            Text('Alamat Server Toko', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan alamat server pusat data toko untuk menghubungkan aplikasi kasir:',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'https://alamat-server-toko.com/api',
                prefixIcon: Icon(Icons.link_rounded, size: 20),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.lightBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.lightBorder),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 15, color: AppColors.textMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gunakan alamat server lokal (Wi-Fi toko) atau domain server cloud yang diberikan oleh pengelola toko.',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              textController.text = ApiConstants.defaultBaseUrl;
            },
            child: const Text('Reset Default', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final newUrl = textController.text.trim();
              if (newUrl.isNotEmpty) {
                await storageService.setBaseUrl(newUrl);
                apiProvider.updateBaseUrl(newUrl);
                Get.back();
                AppSnackbar.success('Tersimpan', 'Alamat server toko berhasil diperbarui.');
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
