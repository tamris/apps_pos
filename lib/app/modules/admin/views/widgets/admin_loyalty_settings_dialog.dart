import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../data/providers/api_provider.dart';

class AdminLoyaltySettingsDialog extends StatefulWidget {
  const AdminLoyaltySettingsDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AdminLoyaltySettingsDialog(),
    );
  }

  @override
  State<AdminLoyaltySettingsDialog> createState() => _AdminLoyaltySettingsDialogState();
}

class _AdminLoyaltySettingsDialogState extends State<AdminLoyaltySettingsDialog> {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  final TextEditingController _spendController = TextEditingController();
  final TextEditingController _exchangeRateController = TextEditingController();
  final TextEditingController _minRedeemController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _pointEnabled = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    _spendController.dispose();
    _exchangeRateController.dispose();
    _minRedeemController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiProvider.get(ApiConstants.adminLoyaltySettings);
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'] ?? {};
        setState(() {
          _pointEnabled = data['point_enabled'] == true;
          _spendController.text = CurrencyFormatter.formatWithoutSymbol(data['point_spend_per_point'] ?? 10000);
          _exchangeRateController.text = CurrencyFormatter.formatWithoutSymbol(data['point_exchange_rate'] ?? 1000);
          _minRedeemController.text = (data['point_min_redeem'] ?? 5).toString();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.data?['message'] ?? 'Gagal memuat pengaturan.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = ApiProvider.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  int _parseNumber(String text, int defaultValue) {
    final clean = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(clean) ?? defaultValue;
  }

  Future<void> _saveSettings() async {
    final spend = _parseNumber(_spendController.text, 0);
    final rate = _parseNumber(_exchangeRateController.text, 0);
    final minRedeem = _parseNumber(_minRedeemController.text, 0);

    if (spend < 100) {
      AppSnackbar.warning('Input Tidak Valid', 'Nominal belanja per 1 poin minimal Rp 100.');
      return;
    }
    if (rate < 1) {
      AppSnackbar.warning('Input Tidak Valid', 'Nilai 1 poin minimal Rp 1.');
      return;
    }
    if (minRedeem < 1) {
      AppSnackbar.warning('Input Tidak Valid', 'Minimal poin penukaran minimal 1.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiProvider.post(
        ApiConstants.adminLoyaltySettings,
        data: {
          'point_enabled': _pointEnabled,
          'point_spend_per_point': spend,
          'point_exchange_rate': rate,
          'point_min_redeem': minRedeem,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        HapticFeedback.mediumImpact();
        AppSnackbar.success(
          'Pengaturan Disimpan',
          'Aturan loyalitas & penukaran poin member berhasil diperbarui.',
        );
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = response.data?['message'] ?? 'Gagal menyimpan pengaturan.';
          _isSaving = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = ApiProvider.getErrorMessage(e);
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spendVal = _parseNumber(_spendController.text, 10000);
    final rateVal = _parseNumber(_exchangeRateController.text, 1000);
    final minRedeemVal = _parseNumber(_minRedeemController.text, 5);

    // Simulasi live
    const simBill = 50000;
    final simRedeemPts = 20;
    final simRedeemDiscount = simRedeemPts * rateVal;
    final simCashPaid = (simBill - simRedeemDiscount).clamp(0, simBill);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.stars_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pengaturan Loyalitas & Poin',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Konfigurasi perolehan dan nilai penukaran poin member',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // Body Content
                Flexible(
                  child: _isLoading
                      ? _buildSkeletonLoading()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(fontSize: 12, color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // 1. Program Status Toggle
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _pointEnabled ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _pointEnabled ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Status Program Loyalitas',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _pointEnabled ? const Color(0xFF166534) : const Color(0xFF475569),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _pointEnabled
                                                ? 'Program aktif: Pelanggan dapat mengumpulkan dan menukar poin di kasir.'
                                                : 'Program nonaktif: Poin tidak akan bertambah maupun ditukarkan di transaksi.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: _pointEnabled ? const Color(0xFF15803D) : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch.adaptive(
                                      value: _pointEnabled,
                                      activeThumbColor: const Color(0xFF16A34A),
                                      activeTrackColor: const Color(0xFFBBF7D0),
                                      onChanged: (val) {
                                        setState(() {
                                          _pointEnabled = val;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),

                              // 2. Aturan Perolehan Poin
                              const Text(
                                'ATURAN PEROLEHAN POIN (EARN)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 8),

                              TextFormField(
                                controller: _spendController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  CurrencyInputFormatter(),
                                ],
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  labelText: 'Nominal Belanja per 1 Poin (Rp)',
                                  labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  prefixText: 'Rp ',
                                  prefixStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Poin dihitung dari nilai uang riil yang dibayar pelanggan (setelah dikurangi diskon promo & potongan poin).',
                                style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                              ),
                              const SizedBox(height: 18),

                              // 3. Aturan Penukaran Poin
                              const Text(
                                'ATURAN PENUKARAN POIN (REDEEM)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // 3. Aturan Penukaran Poin (Side-by-side)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextFormField(
                                          controller: _exchangeRateController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            CurrencyInputFormatter(),
                                          ],
                                          onChanged: (_) => setState(() {}),
                                          decoration: InputDecoration(
                                            labelText: 'Nilai 1 Poin (Rupiah)',
                                            labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                            prefixText: 'Rp ',
                                            prefixStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                                            filled: true,
                                            fillColor: const Color(0xFFF8FAFC),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Misal 10 poin = ${CurrencyFormatter.format(10 * rateVal)} diskon',
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TextFormField(
                                          controller: _minRedeemController,
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                          onChanged: (_) => setState(() {}),
                                          decoration: InputDecoration(
                                            labelText: 'Minimal Poin Tukar',
                                            labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                            suffixText: 'Poin',
                                            suffixStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                            filled: true,
                                            fillColor: const Color(0xFFF8FAFC),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(10),
                                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Syarat saldo minimal: $minRedeemVal poin',
                                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Catatan Ketentuan 100%
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                                    SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Penukaran poin diizinkan hingga 100% total tagihan (pelanggan dapat membayar Rp 0).',
                                        style: TextStyle(fontSize: 10.5, color: Color(0xFF475569)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // 4. Ringkasan Aturan Aktif (Full Width & Clean)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.auto_awesome_rounded, size: 14, color: AppColors.primary),
                                        SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Ringkasan Aturan Aktif',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1E293B),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Earn Card Full Width
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.add_shopping_cart_rounded, size: 14, color: Color(0xFF2563EB)),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Dapat Poin Baru',
                                                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                                ),
                                                Text(
                                                  'Rp ${CurrencyFormatter.formatWithoutSymbol(spendVal)} Belanja ➔ +1 Poin',
                                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Redeem Card Full Width
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDF4),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.stars_rounded, size: 14, color: Color(0xFF16A34A)),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Tukar Diskon Belanja',
                                                  style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                                ),
                                                Text(
                                                  '1 Poin ➔ Diskon Rp ${CurrencyFormatter.formatWithoutSymbol(rateVal)} (Min. $minRedeemVal Poin)',
                                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Simulation Tip Box
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(top: 1.5),
                                            child: Icon(Icons.info_outline_rounded, size: 12, color: Color(0xFF475569)),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Contoh: Belanja Rp 50.000 tukar 20 Poin (-${CurrencyFormatter.format(simRedeemDiscount)}) ➔ Sisa bayar ${CurrencyFormatter.format(simCashPaid)} tetap dapat +${(spendVal > 0 ? (simCashPaid / spendVal).floor() : 0)} Poin.',
                                              style: const TextStyle(fontSize: 10, color: Color(0xFF334155)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // Footer Buttons (Clean Side-by-Side Row)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF475569),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Batal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: _isSaving || _isLoading ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle_rounded, size: 16),
                                    SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        'Simpan Pengaturan',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Skeleton Shimmer Loading (Best Practice Industry Pattern)
  // ---------------------------------------------------------------------------
  Widget _buildSkeletonLoading() {
    return AppShimmer(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Switch Card Skeleton
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const ShimmerBox(width: 38, height: 38, borderRadius: 10),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        ShimmerBox(width: 150, height: 14, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 190, height: 11, borderRadius: 4),
                      ],
                    ),
                  ),
                  const ShimmerBox(width: 44, height: 26, borderRadius: 14),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Section 1: Perolehan Poin
            const ShimmerBox(width: 130, height: 12, borderRadius: 4),
            const SizedBox(height: 8),
            const ShimmerBox(width: double.infinity, height: 48, borderRadius: 10),
            const SizedBox(height: 6),
            const ShimmerBox(width: 220, height: 10, borderRadius: 4),
            const SizedBox(height: 18),

            // Section 2: Penukaran Poin
            const ShimmerBox(width: 170, height: 12, borderRadius: 4),
            const SizedBox(height: 8),
            Row(
              children: const [
                Expanded(child: ShimmerBox(height: 48, borderRadius: 10)),
                SizedBox(width: 10),
                Expanded(child: ShimmerBox(height: 48, borderRadius: 10)),
              ],
            ),
            const SizedBox(height: 18),

            // Section 3: Summary Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  ShimmerBox(width: 140, height: 13, borderRadius: 4),
                  SizedBox(height: 10),
                  ShimmerBox(width: double.infinity, height: 48, borderRadius: 8),
                  SizedBox(height: 8),
                  ShimmerBox(width: double.infinity, height: 48, borderRadius: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
