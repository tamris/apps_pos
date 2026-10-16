import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../data/providers/api_provider.dart';

class AdminEditStoreDialog extends StatefulWidget {
  const AdminEditStoreDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AdminEditStoreDialog(),
    );
  }

  @override
  State<AdminEditStoreDialog> createState() => _AdminEditStoreDialogState();
}

class _AdminEditStoreDialogState extends State<AdminEditStoreDialog> {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _wifiNameController = TextEditingController();
  final TextEditingController _wifiPassController = TextEditingController();
  final TextEditingController _footerController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _autoPrintReceipt = false;
  bool _autoPrintKitchen = false;
  bool _showLogoReceipt = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _wifiNameController.dispose();
    _wifiPassController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiProvider.get(ApiConstants.adminGeneralSettings);
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['shop_name']?.toString() ?? 'Noli Coffe & Space';
          _addressController.text = data['address']?.toString() ?? '';
          _phoneController.text = data['phone']?.toString() ?? '';
          _wifiNameController.text = data['wifi_name']?.toString() ?? '';
          _wifiPassController.text = data['wifi_password']?.toString() ?? '';
          _footerController.text = data['receipt_footer']?.toString() ?? 'Terima Kasih Atas Kunjungannya!';
          _autoPrintReceipt = (data['auto_print_receipt'] ?? false) == true;
          _autoPrintKitchen = (data['auto_print_kitchen'] ?? false) == true;
          _showLogoReceipt = (data['show_logo_receipt'] ?? true) == true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat pengaturan toko: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (_nameController.text.trim().isEmpty) {
      AppSnackbar.danger('Peringatan', 'Nama toko / outlet tidak boleh kosong.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final payload = {
        'shop_name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'wifi_name': _wifiNameController.text.trim(),
        'wifi_password': _wifiPassController.text.trim(),
        'receipt_footer': _footerController.text.trim(),
        'auto_print_receipt': _autoPrintReceipt,
        'auto_print_kitchen': _autoPrintKitchen,
        'show_logo_receipt': _showLogoReceipt,
      };

      final response = await _apiProvider.post(
        ApiConstants.adminGeneralSettings,
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        AppSnackbar.success('Berhasil', 'Pengaturan profil toko berhasil diperbarui!');
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = response.data?['message'] ?? 'Gagal menyimpan pengaturan.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
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
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.secondary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Profil Outlet & Struk',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Kelola identitas cabang, kontak WiFi, dan catatan struk',
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
                        splashRadius: 18,
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
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFECACA)),
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

                              // 1. Informasi Outlet
                              _buildSectionHeader('Identitas Outlet', Icons.storefront_rounded),
                              const SizedBox(height: 8),

                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                decoration: _buildInputDecoration(
                                  label: 'Nama Toko / Outlet',
                                  hint: 'Contoh: Noli Coffee & Space',
                                  icon: Icons.business_rounded,
                                ),
                              ),
                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _addressController,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                decoration: _buildInputDecoration(
                                  label: 'Alamat Cabang Lengkap',
                                  hint: 'Alamat fisik cabang outlet',
                                  icon: Icons.location_on_outlined,
                                ),
                              ),
                              const SizedBox(height: 12),

                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                decoration: _buildInputDecoration(
                                  label: 'Nomor WhatsApp / Kontak Toko',
                                  hint: 'Contoh: 081234567890',
                                  icon: Icons.phone_outlined,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // 2. WiFi Cafe Pengunjung
                              _buildSectionHeader('Akses WiFi Pengunjung', Icons.wifi_rounded, badge: 'Tampil di Struk'),
                              const SizedBox(height: 8),

                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isNarrow = constraints.maxWidth < 400;
                                  final wifiField = TextFormField(
                                    controller: _wifiNameController,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                    decoration: _buildInputDecoration(
                                      label: 'Nama WiFi (SSID)',
                                      hint: 'Contoh: Noli_FreeWiFi',
                                      icon: Icons.wifi_rounded,
                                    ),
                                  );

                                  final passField = TextFormField(
                                    controller: _wifiPassController,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                    decoration: _buildInputDecoration(
                                      label: 'Sandi WiFi',
                                      hint: 'Kata sandi WiFi',
                                      icon: Icons.lock_outline_rounded,
                                    ),
                                  );

                                  if (isNarrow) {
                                    return Column(
                                      children: [
                                        wifiField,
                                        const SizedBox(height: 12),
                                        passField,
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(child: wifiField),
                                      const SizedBox(width: 12),
                                      Expanded(child: passField),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),

                              // 3. Struk & Cetak Otomatis
                              _buildSectionHeader('Struk & Hardware Cetak', Icons.receipt_long_rounded),
                              const SizedBox(height: 8),

                              TextFormField(
                                controller: _footerController,
                                style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                                decoration: _buildInputDecoration(
                                  label: 'Pesan Kaki Struk (Receipt Footer)',
                                  hint: 'Terima Kasih Atas Kunjungannya!',
                                  icon: Icons.receipt_long_outlined,
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Unified Toggle Container
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  children: [
                                    _buildSwitchRow(
                                      icon: Icons.point_of_sale_rounded,
                                      title: 'Cetak Otomatis Struk Kasir',
                                      subtitle: 'Cetak struk belanja otomatis saat kasir menyelesaikan pembayaran',
                                      value: _autoPrintReceipt,
                                      onChanged: (v) => setState(() => _autoPrintReceipt = v),
                                    ),
                                    const Divider(height: 1, thickness: 1, color: Color(0xFFEDF2F7)),
                                    _buildSwitchRow(
                                      icon: Icons.restaurant_rounded,
                                      title: 'Cetak Otomatis Struk Dapur',
                                      subtitle: 'Kirim tiket pesanan makanan/minuman otomatis ke printer dapur',
                                      value: _autoPrintKitchen,
                                      onChanged: (v) => setState(() => _autoPrintKitchen = v),
                                    ),
                                    const Divider(height: 1, thickness: 1, color: Color(0xFFEDF2F7)),
                                    _buildSwitchRow(
                                      icon: Icons.image_outlined,
                                      title: 'Tampilkan Logo Outlet di Struk',
                                      subtitle: 'Mencetak header logo grafis pada printer thermal kasir',
                                      value: _showLogoReceipt,
                                      onChanged: (v) => setState(() => _showLogoReceipt = v),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),

                // Footer Buttons (Responsive Stack on Mobile)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 360;

                      final cancelButton = OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        ),
                        child: const Text('Batal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      );

                      final saveButton = ElevatedButton(
                        onPressed: _isSaving || _isLoading ? null : _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
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
                                      'Simpan Perubahan',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                      );

                      if (isNarrow) {
                        return Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: cancelButton,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: saveButton,
                            ),
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          cancelButton,
                          const SizedBox(width: 10),
                          saveButton,
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, {String? badge}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Color(0xFF475569),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: Color(0xFF475569),
      ),
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 12.5,
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.normal,
      ),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
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
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: value ? AppColors.primarySoft : const Color(0xFFEDF2F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: value ? AppColors.primary : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primarySoft,
            onChanged: onChanged,
          ),
        ],
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
            // Section 1: Identitas Toko
            const ShimmerBox(width: 160, height: 13, borderRadius: 4),
            const SizedBox(height: 12),
            const ShimmerBox(width: double.infinity, height: 48, borderRadius: 10),
            const SizedBox(height: 12),
            const ShimmerBox(width: double.infinity, height: 72, borderRadius: 10),
            const SizedBox(height: 12),
            const ShimmerBox(width: double.infinity, height: 48, borderRadius: 10),
            const SizedBox(height: 20),

            // Section 2: WiFi
            const ShimmerBox(width: 140, height: 13, borderRadius: 4),
            const SizedBox(height: 12),
            Row(
              children: const [
                Expanded(child: ShimmerBox(height: 48, borderRadius: 10)),
                SizedBox(width: 12),
                Expanded(child: ShimmerBox(height: 48, borderRadius: 10)),
              ],
            ),
            const SizedBox(height: 20),

            // Section 3: Hardware Printer & Switches
            const ShimmerBox(width: 170, height: 13, borderRadius: 4),
            const SizedBox(height: 12),
            const ShimmerBox(width: double.infinity, height: 48, borderRadius: 10),
            const SizedBox(height: 10),
            const ShimmerBox(width: double.infinity, height: 52, borderRadius: 10),
            const SizedBox(height: 8),
            const ShimmerBox(width: double.infinity, height: 52, borderRadius: 10),
            const SizedBox(height: 8),
            const ShimmerBox(width: double.infinity, height: 52, borderRadius: 10),
          ],
        ),
      ),
    );
  }
}

