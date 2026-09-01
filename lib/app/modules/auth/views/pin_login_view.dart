import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/providers/api_provider.dart';

class PinLoginView extends GetView<AuthController> {
  const PinLoginView({super.key});

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
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 500 : double.infinity),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo & Header
                      _buildHeader(),
                      const SizedBox(height: 20),

                      // Cashier Quick Selector
                      _buildCashierSelector(),
                      const SizedBox(height: 24),

                      // 6-Digit PIN Indicator Dots
                      _buildPinDots(),
                      const SizedBox(height: 16),

                      // Error message display
                      _buildErrorMessage(),
                      const SizedBox(height: 24),

                      // Numeric Keypad
                      _buildKeypad(),
                      const SizedBox(height: 20),
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
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(76),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.point_of_sale_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Noli POS Kasir',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Masukkan 6 digit PIN untuk memulai transaksi',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCashierSelector() {
    return Obx(() {
      if (controller.cashiers.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Kasir (Opsional):',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: controller.cashiers.map((cashier) {
                final isSelected = controller.selectedCashier.value?.id == cashier.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    avatar: CircleAvatar(
                      backgroundColor: isSelected ? Colors.white : AppColors.primaryLight,
                      child: Text(
                        cashier.name.isNotEmpty ? cashier.name[0].toUpperCase() : 'K',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? AppColors.primary : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    label: Text(
                      cashier.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : AppColors.lightBorder,
                    ),
                    onSelected: (_) => controller.selectCashier(cashier),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Konfigurasi URL Server', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan URL API Backend Laravel POS Toko Anda:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'http://192.168.1.100:8000/api',
                prefixIcon: Icon(Icons.link, size: 20),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Contoh:\n• Emulator Android: http://10.0.2.2:8000/api\n• HP Fisik (Wi-Fi): http://192.168.1.XX:8000/api',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = textController.text.trim();
              if (newUrl.isNotEmpty) {
                await storageService.setBaseUrl(newUrl);
                apiProvider.updateBaseUrl(newUrl);
                controller.fetchCashiers();
                Get.back();
                Get.snackbar('Tersimpan', 'URL Server berhasil diperbarui.');
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
