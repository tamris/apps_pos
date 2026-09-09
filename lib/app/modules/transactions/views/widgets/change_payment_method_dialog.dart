import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/transaction_model.dart';
import '../../controllers/transactions_controller.dart';

class ChangePaymentMethodDialog extends StatefulWidget {
  final TransactionModel transaction;
  final VoidCallback? onSuccess;

  const ChangePaymentMethodDialog({
    super.key,
    required this.transaction,
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required TransactionModel transaction,
    VoidCallback? onSuccess,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ChangePaymentMethodDialog(
        transaction: transaction,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<ChangePaymentMethodDialog> createState() => _ChangePaymentMethodDialogState();
}

class _ChangePaymentMethodDialogState extends State<ChangePaymentMethodDialog> {
  final TransactionsController _controller = Get.find<TransactionsController>();

  late String _selectedMethod;
  late TextEditingController _paidController;
  double _enteredPaid = 0.0;
  bool _isLoading = false;

  String get _cleanCurrentMethod {
    final raw = widget.transaction.paymentMethod.toLowerCase().trim();
    if (raw == 'tunai') return 'cash';
    return raw;
  }

  @override
  void initState() {
    super.initState();
    // Default pilihan baru: arahkan otomatis ke metode alternatif pertama yang bukan metode saat ini
    final current = _cleanCurrentMethod;
    if (current == 'cash') {
      _selectedMethod = 'qris';
    } else if (current == 'qris') {
      _selectedMethod = 'cash';
    } else {
      _selectedMethod = 'cash';
    }

    _enteredPaid = widget.transaction.total;
    _paidController = TextEditingController(
      text: CurrencyFormatter.formatWithoutSymbol(_enteredPaid),
    );
  }

  @override
  void dispose() {
    _paidController.dispose();
    super.dispose();
  }

  double get _currentGrandTotal => widget.transaction.total;

  double get _changeAmount {
    if (_selectedMethod != 'cash') return 0.0;
    return max(0.0, _enteredPaid - _currentGrandTotal);
  }

  /// Generator Rekomendasi Uang Cepat Pintar Kasir (Selalu > Total Tagihan)
  List<double> _getSmartCashSuggestions(double total) {
    if (total <= 0) return [10000, 20000, 50000];

    final Set<double> suggestions = {};
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
    return sorted.take(3).toList();
  }

  void _onPaidAmountChanged(String val) {
    final cleanDigits = val.replaceAll(RegExp(r'[^0-9]'), '');
    final parsed = double.tryParse(cleanDigits) ?? 0.0;
    setState(() {
      _enteredPaid = parsed;
    });
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    if (_selectedMethod == _cleanCurrentMethod) {
      AppSnackbar.warning('Perhatian', 'Metode yang dipilih sama dengan metode saat ini.');
      return;
    }

    if (_selectedMethod == 'cash' && _enteredPaid < _currentGrandTotal) {
      AppSnackbar.danger(
        'Nominal Kurang',
        'Uang tunai yang diterima kurang dari total tagihan (${CurrencyFormatter.format(_currentGrandTotal)}).',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _controller.updatePaymentMethod(
      transactionId: widget.transaction.id,
      newPaymentMethod: _selectedMethod,
      paid: (_selectedMethod == 'cash') ? _enteredPaid : _currentGrandTotal,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (success) {
        Navigator.of(context).pop();
        widget.onSuccess?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentMethod = widget.transaction.paymentMethod.toUpperCase();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 36,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(28, 24, 28, 26 + (bottomInset > 0 ? 10 : 0)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Dialog
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primaryLight.withAlpha(100), width: 1.5),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: AppColors.primaryDark,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ubah Metode Pembayaran',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Invoice: ${widget.transaction.invoiceNumber}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 22),
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 18),

                // 2. Info Ringkasan Tagihan & Metode Aktif
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL TAGIHAN',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.format(_currentGrandTotal),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'METODE SAAT INI',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondarySoft,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.secondaryLight.withAlpha(80)),
                            ),
                            child: Text(
                              currentMethod,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // 3. Pilihan Metode Baru (Metode saat ini otomatis di-disable)
                const Text(
                  'Pilih Metode Pembayaran Baru:',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    _buildMethodOption('cash', 'Tunai', Icons.payments_outlined),
                    const SizedBox(width: 10),
                    _buildMethodOption('qris', 'QRIS', Icons.qr_code_scanner_rounded),
                    const SizedBox(width: 10),
                    _buildMethodOption('transfer', 'Transfer', Icons.account_balance_outlined),
                  ],
                ),
                const SizedBox(height: 20),

                // 4. Form Dinamis: Tunai vs Non-Tunai
                if (_selectedMethod == 'cash') ...[
                  const Text(
                    'Uang Tunai Diterima Kasir:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _paidController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    onChanged: _onPaidAmountChanged,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _paidController.clear();
                          setState(() {
                            _enteredPaid = 0;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: AppColors.lightBackground,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.lightBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.lightBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Preset Cepat Dinamis (Persis seperti Layar Kasir POS)
                  _buildQuickCashRow(_currentGrandTotal),
                  const SizedBox(height: 14),

                  // Kotak Kembalian / Status Pembayaran
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: (_enteredPaid >= _currentGrandTotal) ? AppColors.successSoft : AppColors.dangerSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (_enteredPaid >= _currentGrandTotal)
                            ? AppColors.success.withAlpha(60)
                            : AppColors.danger.withAlpha(60),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          (_enteredPaid >= _currentGrandTotal) ? 'Uang Kembalian:' : 'Kurang Bayar:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: (_enteredPaid >= _currentGrandTotal) ? AppColors.success : AppColors.danger,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.format((_enteredPaid >= _currentGrandTotal)
                              ? _changeAmount
                              : (_currentGrandTotal - _enteredPaid)),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (_enteredPaid >= _currentGrandTotal) ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Keterangan Non-Tunai (QRIS / Transfer)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.infoSoft,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.info.withAlpha(60)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.info, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Transaksi akan dialihkan ke ${_selectedMethod.toUpperCase()}. Tagihan otomatis diset lunas pas sebesar ${CurrencyFormatter.format(_currentGrandTotal)} tanpa uang kembalian.',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // 5. Tombol Aksi Bawah
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.lightBorder),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check_circle_outline_rounded, size: 20),
                        label: Text(
                          _isLoading ? 'Menyimpan...' : 'Simpan Perubahan',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isLoading ? null : _handleSubmit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodOption(String key, String title, IconData icon) {
    final isCurrent = _cleanCurrentMethod == key;
    final isSelected = _selectedMethod == key;

    return Expanded(
      child: InkWell(
        onTap: isCurrent
            ? null // DISABLE jika merupakan metode transaksi saat ini!
            : () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedMethod = key;
                  if (key == 'cash') {
                    _enteredPaid = _currentGrandTotal;
                    _paidController.text = CurrencyFormatter.formatWithoutSymbol(_currentGrandTotal);
                  }
                });
              },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.lightBackground.withAlpha(200)
                : (isSelected ? AppColors.primarySoft : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCurrent
                  ? AppColors.lightBorder.withAlpha(120)
                  : (isSelected ? AppColors.primary : AppColors.lightBorder),
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 26,
                color: isCurrent
                    ? AppColors.textMuted
                    : (isSelected ? AppColors.primaryDark : AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isCurrent
                      ? AppColors.textMuted
                      : (isSelected ? AppColors.primaryDark : AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 5),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withAlpha(35),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'Metode Awal',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else if (isSelected)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Text(
                    'Dipilih',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                )
              else
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Preset Cepat Dinamis (Uang Pas + 3 Rekomendasi Bulat Lebih Besar)
  Widget _buildQuickCashRow(double total) {
    final suggestions = _getSmartCashSuggestions(total);
    final isExactSelected = _enteredPaid == total && total > 0;

    return Row(
      children: [
        // 1. Tombol Uang Pas
        Expanded(
          child: _buildCashPresetButton(
            label: 'Uang Pas',
            isSelected: isExactSelected,
            showCheck: true,
            onTap: () {
              setState(() {
                _enteredPaid = total;
                _paidController.text = CurrencyFormatter.formatWithoutSymbol(total);
              });
            },
          ),
        ),
        // 2. Rekomendasi Dinamis Pecahan Lebih Besar
        ...suggestions.map((amount) {
          final isSelected = _enteredPaid == amount;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 6.0),
              child: _buildCashPresetButton(
                label: CurrencyFormatter.format(amount),
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _enteredPaid = amount;
                    _paidController.text = CurrencyFormatter.formatWithoutSymbol(amount);
                  });
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
    bool showCheck = false,
  }) {
    return Material(
      color: isSelected ? AppColors.primarySoft : AppColors.lightBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showCheck && isSelected) ...[
                const Icon(Icons.check_circle_rounded, size: 13, color: AppColors.primary),
                const SizedBox(width: 3),
              ],
              Flexible(
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
            ],
          ),
        ),
      ),
    );
  }
}
