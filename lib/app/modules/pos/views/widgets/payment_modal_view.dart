import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/pos_controller.dart';

import '../../../shift/controllers/shift_controller.dart';
import '../../../shift/views/shift_dialogs.dart';

class PaymentModalView extends StatefulWidget {
  const PaymentModalView({super.key});

  static Future<void> show(BuildContext context) async {
    // 1. Periksa apakah kasir sudah membuka shift aktif sebelum bayar
    if (Get.isRegistered<ShiftController>()) {
      final shiftCtrl = Get.find<ShiftController>();
      if (!shiftCtrl.hasActiveShift.value) {
        final opened = await ShiftDialogs.showStartShiftDialog(context);
        if (!opened) return; // Kasir membatalkan buka shift -> jangan tampilkan pembayaran
      }
    }

    if (!context.mounted) return;

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
      text: CurrencyFormatter.formatWithoutSymbol(cartController.paidAmount.value),
    );
  }

  @override
  void dispose() {
    _paidInputController.dispose();
    super.dispose();
  }

  /// Generator Rekomendasi Uang Cepat Pintar (Selalu >= Total Tagihan)
  List<double> _getSmartCashSuggestions(double total) {
    if (total <= 0) return [10000, 20000, 50000];

    final Set<double> suggestions = {};

    // Daftar pecahan uang rupiah yang umum
    final List<double> standardNotes = [
      10000,
      20000,
      50000,
      100000,
      150000,
      200000,
      250000,
      300000,
      400000,
      500000,
      1000000,
    ];

    // 1. Pembulatan 10k terdekat
    if (total % 10000 != 0) {
      suggestions.add(((total ~/ 10000) + 1) * 10000.0);
    }
    // 2. Pembulatan 50k terdekat
    if (total % 50000 != 0) {
      suggestions.add(((total ~/ 50000) + 1) * 50000.0);
    }
    // 3. Pembulatan 100k terdekat
    if (total % 100000 != 0) {
      suggestions.add(((total ~/ 100000) + 1) * 100000.0);
    }

    // 4. Tambahkan pecahan standar yang lebih besar dari total
    for (final note in standardNotes) {
      if (note > total) {
        suggestions.add(note);
      }
    }

    final sorted = suggestions.where((s) => s > total).toList()..sort();

    // Ambil 3 rekomendasi nominal tercepat
    return sorted.take(3).toList();
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
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
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryLight.withAlpha(102)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'TOTAL TAGIHAN',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                            letterSpacing: 1.0,
                          ),
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

                  // Pilihan Metode Pembayaran (3 Kartu Sama Rata)
                  const Text(
                    'Pilih Metode Pembayaran:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
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
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: AppColors.primaryDark, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Pembayaran non-tunai (${cartController.paymentMethod.value.toUpperCase()}) akan diverifikasi secara pas/lunas tanpa uang kembalian.',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final grandTotal = cartController.grandTotal;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Uang Yang Diterima Kasir:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Input Nominal Diterima
                        TextField(
                          controller: _paidInputController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                          ],
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 14),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.payments_rounded, color: AppColors.primary, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Rp',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
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

                        // Preset Uang Pas & Rekomendasi Cepat Dinamis (4 Tombol Sama Rata)
                        _buildQuickCashRow(grandTotal),
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
                                  fontSize: 12,
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
              height: 50,
              child: ElevatedButton(
                onPressed: (canProceed && !cartController.isProcessing.value)
                    ? () async {
                        // Tutup modal pembayaran terlebih dahulu agar tidak menumpuk di latar belakang dialog sukses
                        Navigator.of(context).pop();
                        await cartController.processCheckout(context: context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
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
                          Text('Memproses Transaksi...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Selesaikan & Bayar (${CurrencyFormatter.format(cartController.grandTotal)})',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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

  /// Komponen Rekomendasi Uang Cepat (4 Tombol Sama Lebar)
  Widget _buildQuickCashRow(double total) {
    final suggestions = _getSmartCashSuggestions(total);
    final isExactSelected = cartController.paidAmount.value == total && total > 0;

    return Row(
      children: [
        // 1. Tombol Uang Pas (Teks satu baris bersih)
        Expanded(
          child: _buildCashPresetButton(
            label: 'Uang Pas',
            isSelected: isExactSelected,
            onTap: () {
              cartController.setPaidAmount(total);
              _paidInputController.text = CurrencyFormatter.formatWithoutSymbol(total);
            },
          ),
        ),
        // 2. Tombol Rekomendasi Dinamis
        ...suggestions.map((amount) {
          final isSelected = cartController.paidAmount.value == amount;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: _buildCashPresetButton(
                label: CurrencyFormatter.format(amount),
                isSelected: isSelected,
                onTap: () {
                  if (isSelected) {
                    // Toggle: jika nominal yang sama diklik lagi, reset kembali ke uang pas
                    cartController.setPaidAmount(total);
                    _paidInputController.text = CurrencyFormatter.formatWithoutSymbol(total);
                  } else {
                    cartController.setPaidAmount(amount);
                    _paidInputController.text = CurrencyFormatter.formatWithoutSymbol(amount);
                  }
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCashPresetButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? AppColors.primarySoft : AppColors.lightBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.lightBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
            ),
          ),
        ),
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
                width: isSelected ? 1.5 : 1.0,
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
