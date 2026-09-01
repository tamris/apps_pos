import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/pos_controller.dart';

class PaymentModalView extends StatefulWidget {
  const PaymentModalView({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const PaymentModalView(),
    );
  }

  @override
  State<PaymentModalView> createState() => _PaymentModalViewState();
}

class _PaymentModalViewState extends State<PaymentModalView> {
  final CartController cartController = Get.find<CartController>();
  final PosController posController = Get.find<PosController>();
  late TextEditingController _paidInputController;

  @override
  void initState() {
    super.initState();
    // Default uang pas jika cash
    if (cartController.paidAmount.value <= 0) {
      cartController.setPaidAmount(cartController.grandTotal);
    }
    _paidInputController = TextEditingController(
      text: cartController.paidAmount.value.toInt().toString(),
    );
  }

  @override
  void dispose() {
    _paidInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: Column(
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.lightBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pembayaran Transaksi',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Get.back(),
              ),
            ],
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Total Tagihan Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryLight.withAlpha(102)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TOTAL TAGIHAN',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                        const SizedBox(height: 4),
                        Obx(() => Text(
                              CurrencyFormatter.format(cartController.grandTotal),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pilihan Metode Pembayaran
                  const Text(
                    'Pilih Metode Pembayaran:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 10),

                  Obx(() {
                    return Row(
                      children: [
                        _buildMethodCard('cash', 'Tunai', Icons.payments_outlined),
                        const SizedBox(width: 8),
                        _buildMethodCard('qris', 'QRIS', Icons.qr_code_scanner_rounded),
                        const SizedBox(width: 8),
                        _buildMethodCard('transfer', 'Transfer', Icons.account_balance_outlined),
                        const SizedBox(width: 8),
                        _buildMethodCard('debit', 'Debit EDC', Icons.credit_card_rounded),
                      ],
                    );
                  }),
                  const SizedBox(height: 20),

                  // Bagian Khusus Tunai (Cash Presets & Kembalian)
                  Obx(() {
                    if (cartController.paymentMethod.value != 'cash') {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.info, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Pembayaran non-tunai (${cartController.paymentMethod.value.toUpperCase()}) akan diverifikasi secara pas/lunas tanpa uang kembalian.',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Uang Yang Diterima Kasir:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),

                        // Input Nominal Diterima
                        TextField(
                          controller: _paidInputController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.money_rounded, color: AppColors.primary),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _paidInputController.clear();
                                cartController.setPaidAmount(0);
                              },
                            ),
                          ),
                          onChanged: (val) {
                            final raw = val.replaceAll(RegExp(r'[^0-9]'), '');
                            cartController.setPaidAmount(double.tryParse(raw) ?? 0);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Preset Uang Pas & Pecahan
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            // Uang Pas
                            ActionChip(
                              label: const Text('Uang Pas', style: TextStyle(fontWeight: FontWeight.bold)),
                              backgroundColor: AppColors.primarySoft,
                              side: const BorderSide(color: AppColors.primary),
                              onPressed: () {
                                final exact = cartController.grandTotal;
                                cartController.setPaidAmount(exact);
                                _paidInputController.text = exact.toInt().toString();
                              },
                            ),
                            // Presets dari Backend
                            ...posController.quickCashPresets.map((preset) {
                              return ActionChip(
                                label: Text(CurrencyFormatter.format(preset)),
                                backgroundColor: AppColors.lightBackground,
                                side: const BorderSide(color: AppColors.lightBorder),
                                onPressed: () {
                                  cartController.setPaidAmount(preset.toDouble());
                                  _paidInputController.text = preset.toString();
                                },
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Kembalian Box
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: cartController.paidAmount.value >= cartController.grandTotal
                                ? AppColors.primarySoft
                                : AppColors.dangerSoft,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: cartController.paidAmount.value >= cartController.grandTotal
                                  ? AppColors.primary
                                  : AppColors.danger,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                cartController.paidAmount.value >= cartController.grandTotal
                                    ? 'UANG KEMBALIAN:'
                                    : 'KURANG BAYAR:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: cartController.paidAmount.value >= cartController.grandTotal
                                      ? AppColors.primaryDark
                                      : AppColors.danger,
                                ),
                              ),
                              Text(
                                cartController.paidAmount.value >= cartController.grandTotal
                                    ? CurrencyFormatter.format(cartController.changeAmount)
                                    : CurrencyFormatter.format(cartController.grandTotal - cartController.paidAmount.value),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: cartController.paidAmount.value >= cartController.grandTotal
                                      ? AppColors.primaryDark
                                      : AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),

          // Tombol Proses Transaksi
          const SizedBox(height: 12),
          Obx(() {
            final isCash = cartController.paymentMethod.value == 'cash';
            final isCashEnough = cartController.paidAmount.value >= cartController.grandTotal;
            final canProceed = !isCash || isCashEnough;

            return SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (canProceed && !cartController.isProcessing.value)
                    ? () async {
                        final success = await cartController.processCheckout(context: context);
                        if (success) {
                          Get.back();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: cartController.isProcessing.value
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text('Memproses Transaksi...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Selesaikan & Bayar (${CurrencyFormatter.format(cartController.grandTotal)})',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMethodCard(String key, String label, IconData icon) {
    final isSelected = cartController.paymentMethod.value == key;
    return Expanded(
      child: Material(
        color: isSelected ? AppColors.primarySoft : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => cartController.paymentMethod.value = key,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.lightBorder,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
