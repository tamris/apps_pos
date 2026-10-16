import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../data/providers/api_provider.dart';
import 'admin_edit_store_dialog.dart';
import 'admin_loyalty_settings_dialog.dart';
import 'admin_telegram_settings_dialog.dart';

class AdminSettingsTab extends StatefulWidget {
  const AdminSettingsTab({super.key});

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  bool _isLoading = true;
  String? _errorMessage;

  // General Settings
  String _shopName = 'Noli Coffe & Space';
  String _address = 'Jl. Kh Wahid Hasyim, Slawi Kulon Kec. Slawi, Kab. Tegal Slawi';
  String _phone = '-';
  String _wifiName = '';
  String _wifiPassword = '';
  String _receiptFooter = 'Terima Kasih Atas Kunjungannya!';
  bool _autoPrintReceipt = false;
  bool _autoPrintKitchen = false;
  bool _showLogoReceipt = true;

  // Loyalty Settings
  bool _pointEnabled = true;
  int _pointSpendPerPoint = 10000;
  int _pointExchangeRate = 1000;
  int _pointMinRedeem = 5;

  // Telegram Settings
  bool _telegramConfigured = false;
  bool _telegramNotifyTrx = false;
  bool _telegramNotifyShift = false;
  bool _telegramNotifyVoid = false;

  @override
  void initState() {
    super.initState();
    _loadAllSettings();
  }

  Future<void> _loadAllSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch General Settings
      final genRes = await _apiProvider.get(ApiConstants.adminGeneralSettings);
      if (genRes.data != null && genRes.data['success'] == true) {
        final d = genRes.data['data'] as Map<String, dynamic>;
        _shopName = d['shop_name']?.toString() ?? _shopName;
        _address = d['address']?.toString() ?? _address;
        _phone = (d['phone'] != null && d['phone'].toString().isNotEmpty) ? d['phone'].toString() : '-';
        _wifiName = d['wifi_name']?.toString() ?? '';
        _wifiPassword = d['wifi_password']?.toString() ?? '';
        _receiptFooter = d['receipt_footer']?.toString() ?? _receiptFooter;
        _autoPrintReceipt = (d['auto_print_receipt'] ?? false) == true;
        _autoPrintKitchen = (d['auto_print_kitchen'] ?? false) == true;
        _showLogoReceipt = (d['show_logo_receipt'] ?? true) == true;
        _pointEnabled = (d['point_enabled'] ?? true) == true;
        _pointSpendPerPoint = (d['point_spend_per_point'] as num?)?.toInt() ?? 10000;
        _pointExchangeRate = (d['point_exchange_rate'] as num?)?.toInt() ?? 1000;
        _pointMinRedeem = (d['point_min_redeem'] as num?)?.toInt() ?? 5;
      }

      // 2. Fetch Telegram Settings
      final teleRes = await _apiProvider.get(ApiConstants.adminTelegramSettings);
      if (teleRes.data != null && teleRes.data['success'] == true) {
        final td = teleRes.data['data'] as Map<String, dynamic>;
        _telegramConfigured = td['is_configured'] == true;
        _telegramNotifyTrx = td['notify_trx'] == true;
        _telegramNotifyShift = td['notify_shift'] == true;
        _telegramNotifyVoid = td['notify_void'] == true;
      }
    } catch (e) {
      _errorMessage = 'Gagal memuat pengaturan: ${e.toString()}';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSkeletonLoading();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadAllSettings,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
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
                      TextButton(
                        onPressed: _loadAllSettings,
                        child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],

              // 1. HERO HEADER BANNER (Full Width)
              _buildHeroHeader(context),
              const SizedBox(height: 16),

              // 2. BENTO QUICK STATS STRIP (4 CARDS, UNIFORM HEIGHT)
              _buildBentoQuickStats(context, isWide),
              const SizedBox(height: 18),

              // 3. PAIRED ROWS FOR PERFECT VERTICAL ALIGNMENT
              if (isWide) ...[
                // BARIS 1: PROFIL OUTLET & PRINTER THERMAL
                _buildAlignedRow(
                  left: _buildStoreProfileCard(context),
                  right: _buildHardwarePrinterCard(context),
                ),
                const SizedBox(height: 18),

                // BARIS 2: LOYALITAS POIN & BOT TELEGRAM
                _buildAlignedRow(
                  left: _buildLoyaltyCard(context),
                  right: _buildTelegramCard(context),
                ),
              ] else ...[
                // SINGLE COLUMN FOR COMPACT / MOBILE SCREENS
                _buildStoreProfileCard(context),
                const SizedBox(height: 14),
                _buildHardwarePrinterCard(context),
                const SizedBox(height: 14),
                _buildLoyaltyCard(context),
                const SizedBox(height: 14),
                _buildTelegramCard(context),
              ],
              const SizedBox(height: 18),

              // 4. SLEEK MINIMALIST SYSTEM & VERSION FOOTER STRIP
              _buildSystemVersionFooter(context),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // Helper widget to keep left and right cards on the exact same height and baseline
  Widget _buildAlignedRow({required Widget left, required Widget right}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 18),
          Expanded(child: right),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HERO HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeroHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;

        final storeIcon = Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF047857), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 25),
        );

        final titlesAndBadges = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _shopName,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF16A34A)),
                      SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          'Pusat Kontrol Utama',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_done_rounded, size: 10, color: Color(0xFF0284C7)),
                      SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          'Cloud Online',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              _address.isNotEmpty ? _address : 'Alamat cabang belum diatur.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
            ),
          ],
        );

        final editStoreBtn = ElevatedButton.icon(
          onPressed: () async {
            final updated = await AdminEditStoreDialog.show(context);
            if (updated == true) _loadAllSettings();
          },
          icon: const Icon(Icons.edit_note_rounded, size: 16),
          label: const Text('Edit Profil Toko', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
        );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        storeIcon,
                        const SizedBox(width: 14),
                        Expanded(child: titlesAndBadges),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: editStoreBtn,
                    ),
                  ],
                )
              : Row(
                  children: [
                    storeIcon,
                    const SizedBox(width: 16),
                    Expanded(child: titlesAndBadges),
                    const SizedBox(width: 14),
                    editStoreBtn,
                  ],
                ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 2. BENTO QUICK STATS STRIP (4 CARDS, EQUAL HEIGHT)
  // ---------------------------------------------------------------------------
  Widget _buildBentoQuickStats(BuildContext context, bool isWide) {
    final card1 = _buildStatCard(
      icon: Icons.wifi_rounded,
      iconColor: const Color(0xFF0284C7),
      iconBgColor: const Color(0xFFE0F2FE),
      badgeText: 'WiFi Cafe',
      badgeColor: const Color(0xFFE0F2FE),
      badgeTextColor: const Color(0xFF0369A1),
      title: 'Akses WiFi Pengunjung',
      mainText: _wifiName.isNotEmpty ? _wifiName : 'Belum Ada WiFi',
      subText: _wifiPassword.isNotEmpty ? 'Sandi: $_wifiPassword' : 'Tanpa Sandi / Belum Diatur',
      actionLabel: 'Salin Sandi',
      actionIcon: Icons.copy_rounded,
      onAction: _wifiPassword.isNotEmpty
          ? () {
              Clipboard.setData(ClipboardData(text: _wifiPassword));
              AppSnackbar.success('Disalin', 'Sandi WiFi disalin ke clipboard!');
            }
          : null,
    );

    final card2 = _buildStatCard(
      icon: Icons.stars_rounded,
      iconColor: const Color(0xFFD97706),
      iconBgColor: const Color(0xFFFEF3C7),
      badgeText: _pointEnabled ? 'Aktif' : 'Nonaktif',
      badgeColor: _pointEnabled ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
      badgeTextColor: _pointEnabled ? const Color(0xFF15803D) : const Color(0xFF64748B),
      title: 'Program Poin Member',
      mainText: _pointEnabled ? 'Loyalitas Aktif' : 'Program Dinonaktifkan',
      subText: 'Rp ${CurrencyFormatter.formatWithoutSymbol(_pointSpendPerPoint.toDouble())} = 1 Poin • 1 Poin = Rp ${CurrencyFormatter.formatWithoutSymbol(_pointExchangeRate.toDouble())}',
      actionLabel: 'Atur Poin',
      actionIcon: Icons.tune_rounded,
      onAction: () async {
        await AdminLoyaltySettingsDialog.show(context);
        _loadAllSettings();
      },
    );

    final card3 = _buildStatCard(
      icon: Icons.print_rounded,
      iconColor: const Color(0xFF4F46E5),
      iconBgColor: const Color(0xFFEEF2FF),
      badgeText: 'ESC/POS 58mm',
      badgeColor: const Color(0xFFEEF2FF),
      badgeTextColor: const Color(0xFF4338CA),
      title: 'Printer Struk Kasir',
      mainText: _autoPrintReceipt ? 'Auto Print Aktif' : 'Cetak Struk Manual',
      subText: 'Format Thermal Bluetooth / USB Siap Pakai',
      actionLabel: 'Ubah Struk',
      actionIcon: Icons.settings_outlined,
      onAction: () async {
        final updated = await AdminEditStoreDialog.show(context);
        if (updated == true) _loadAllSettings();
      },
    );

    final card4 = _buildStatCard(
      icon: Icons.send_rounded,
      iconColor: const Color(0xFF7E22CE),
      iconBgColor: const Color(0xFFF3E8FF),
      badgeText: _telegramConfigured ? 'Terkoneksi' : 'Belum Diatur',
      badgeColor: _telegramConfigured ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
      badgeTextColor: _telegramConfigured ? const Color(0xFF15803D) : const Color(0xFFB45309),
      title: 'Bot Telegram Owner',
      mainText: _telegramConfigured ? 'Bot Siap Kirim' : 'Token Belum Lengkap',
      subText: 'Alert Transaksi & Laporan Tutup Shift',
      actionLabel: 'Kelola Bot',
      actionIcon: Icons.arrow_forward_ios_rounded,
      onAction: () async {
        final updated = await AdminTelegramSettingsDialog.show(context);
        if (updated == true) _loadAllSettings();
      },
    );

    if (isWide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: card1),
            const SizedBox(width: 12),
            Expanded(child: card2),
            const SizedBox(width: 12),
            Expanded(child: card3),
            const SizedBox(width: 12),
            Expanded(child: card4),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          card1,
          const SizedBox(height: 10),
          card2,
          const SizedBox(height: 10),
          card3,
          const SizedBox(height: 10),
          card4,
        ],
      );
    }
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required String title,
    required String mainText,
    required String subText,
    required String actionLabel,
    required IconData actionIcon,
    VoidCallback? onAction,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeTextColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 2),
              Text(
                mainText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                subText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: onAction != null ? AppColors.primaryDark : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      actionIcon,
                      size: 11,
                      color: onAction != null ? AppColors.primaryDark : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MAIN CARDS (CLEAN & CONSISTENT)
  // ---------------------------------------------------------------------------

  // Card 1: Profil & Identitas Outlet
  Widget _buildStoreProfileCard(BuildContext context) {
    return _buildSectionCard(
      title: 'Profil & Identitas Outlet',
      subtitle: 'Informasi legal cabang, kontak WhatsApp, dan WiFi cafe',
      icon: Icons.storefront_rounded,
      iconColor: const Color(0xFF059669),
      action: _buildCardActionBtn(
        icon: Icons.edit_outlined,
        label: 'Edit Profil',
        onTap: () async {
          final updated = await AdminEditStoreDialog.show(context);
          if (updated == true) _loadAllSettings();
        },
      ),
      child: Column(
        children: [
          _buildInfoRow('Nama Brand / Toko', _shopName, Icons.badge_outlined),
          const Divider(height: 14, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Alamat Fisik Cabang', _address, Icons.location_on_outlined),
          const Divider(height: 14, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Kontak WhatsApp Toko', _phone, Icons.phone_outlined),
          const Divider(height: 14, color: Color(0xFFF1F5F9)),
          _buildInfoRow(
            'Akses WiFi Pengunjung',
            _wifiName.isNotEmpty ? '$_wifiName (Sandi: ${_wifiPassword.isEmpty ? '-' : _wifiPassword})' : 'Belum Diatur',
            Icons.wifi_rounded,
            trailingAction: _wifiPassword.isNotEmpty
                ? InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _wifiPassword));
                      AppSnackbar.success('Disalin', 'Sandi WiFi berhasil disalin!');
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(Icons.copy_rounded, size: 14, color: AppColors.primary),
                    ),
                  )
                : null,
          ),
          const Divider(height: 14, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Catatan Kaki Struk', _receiptFooter, Icons.receipt_long_outlined),
        ],
      ),
    );
  }

  // Card 2: Printer Thermal & Hardware Kasir
  Widget _buildHardwarePrinterCard(BuildContext context) {
    return _buildSectionCard(
      title: 'Printer Thermal & Hardware Kasir',
      subtitle: 'Standarisasi cetak struk kasir, tiket dapur, dan laci kasir',
      icon: Icons.print_rounded,
      iconColor: const Color(0xFF4F46E5),
      action: _buildCardActionBtn(
        icon: Icons.settings_outlined,
        label: 'Atur Cetak',
        onTap: () async {
          final updated = await AdminEditStoreDialog.show(context);
          if (updated == true) _loadAllSettings();
        },
      ),
      child: Column(
        children: [
          _buildStatusRow(
            title: 'Auto-Print Struk Kasir',
            subtitle: 'Cetak struk belanja otomatis saat pembayaran lunas',
            isActive: _autoPrintReceipt,
          ),
          const Divider(height: 14, color: Color(0xFFF1F5F9)),
          _buildStatusRow(
            title: 'Auto-Print Struk Dapur',
            subtitle: 'Kirim tiket pesanan makanan/minuman langsung ke dapur',
            isActive: _autoPrintKitchen,
          ),
          const Divider(height: 14, color: Color(0xFFF1F5F9)),
          _buildStatusRow(
            title: 'Tampilkan Logo di Struk',
            subtitle: 'Cetak logo outlet grafis pada bagian header struk thermal',
            isActive: _showLogoReceipt,
          ),
          const Divider(height: 14, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Lebar Kertas Thermal', '58mm (Standar Portabel) & 80mm', Icons.straighten_rounded),
          const Divider(height: 14, color: Color(0xFFF1F5F9)),
          _buildInfoRow('Protokol Cetak Struk', 'ESC/POS Native Binary & RawBT Service', Icons.code_rounded),
        ],
      ),
    );
  }

  // Card 3: Program Loyalitas & Poin Member
  Widget _buildLoyaltyCard(BuildContext context) {
    return _buildSectionCard(
      title: 'Program Loyalitas & Poin Member',
      subtitle: 'Aturan perolehan poin transaksi dan nilai tukar diskon member',
      icon: Icons.stars_rounded,
      iconColor: const Color(0xFFD97706),
      action: _buildCardActionBtn(
        icon: Icons.tune_rounded,
        label: 'Atur Poin',
        onTap: () async {
          await AdminLoyaltySettingsDialog.show(context);
          _loadAllSettings();
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: _pointEnabled ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _pointEnabled ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(
                  _pointEnabled ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                  color: _pointEnabled ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _pointEnabled
                        ? 'Program Aktif: Member mendapatkan poin dari sisa uang belanja riil (Nett Spend).'
                        : 'Program Nonaktif: Penambahan dan penukaran poin saat ini dinonaktifkan.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _pointEnabled ? const Color(0xFF15803D) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 3 Metric Badges
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Perolehan Poin',
                  'Rp ${CurrencyFormatter.formatWithoutSymbol(_pointSpendPerPoint.toDouble())}',
                  'Per 1 Poin didapat',
                  const Color(0xFF0284C7),
                  const Color(0xFFF0F9FF),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Nilai Tukar Poin',
                  'Rp ${CurrencyFormatter.formatWithoutSymbol(_pointExchangeRate.toDouble())}',
                  'Diskon per 1 Poin',
                  const Color(0xFF16A34A),
                  const Color(0xFFF0FDF4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  'Syarat Minimal',
                  '$_pointMinRedeem Poin',
                  'Min. untuk ditukar',
                  const Color(0xFFD97706),
                  const Color(0xFFFFFBEB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.verified_outlined, size: 14, color: Color(0xFF64748B)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Poin member dihitung dari sisa uang yang dibayarkan dan mendukung penukaran hingga 100% lunas.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 4: Bot Telegram Owner
  Widget _buildTelegramCard(BuildContext context) {
    return _buildSectionCard(
      title: 'Notifikasi & Bot Telegram Owner',
      subtitle: 'Laporan otomatis transaksi real-time dan audit shift kasir',
      icon: Icons.send_rounded,
      iconColor: const Color(0xFF7E22CE),
      action: _buildCardActionBtn(
        icon: Icons.settings_rounded,
        label: 'Kelola Bot',
        onTap: () async {
          final updated = await AdminTelegramSettingsDialog.show(context);
          if (updated == true) _loadAllSettings();
        },
      ),
      child: Column(
        children: [
          _buildStatusRow(
            title: 'Notifikasi Transaksi Baru Kasir',
            subtitle: 'Pesan otomatis ke Telegram owner setiap pesanan dibayar',
            isActive: _telegramNotifyTrx,
          ),
          const Divider(height: 14, color: Color(0xFFF1F5F9)),
          _buildStatusRow(
            title: 'Laporan Tutup Shift & Z-Report',
            subtitle: 'Ringkasan total omset, penerimaan tunai/QRIS, dan selisih kas',
            isActive: _telegramNotifyShift,
          ),
          const Divider(height: 14, color: Color(0xFFF1F5F9)),
          _buildStatusRow(
            title: 'Alert Pembatalan / Void Transaksi',
            subtitle: 'Pemberitahuan darurat jika ada transaksi dibatalkan oleh kasir',
            isActive: _telegramNotifyVoid,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. MINIMALIST SYSTEM & VERSION FOOTER STRIP
  // ---------------------------------------------------------------------------
  Widget _buildSystemVersionFooter(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 680;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.015),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Cloud Connected',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            AppConstants.versionTag,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Database Online & Sinkron',
                          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                        _buildCheckUpdateBtn(context),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Cloud Status Indicator
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Terhubung ke Cloud (Cloudflare)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('•', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14)),
                    const SizedBox(width: 12),

                    // Version Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded, size: 12, color: Color(0xFF0284C7)),
                          const SizedBox(width: 5),
                          Text(
                            AppConstants.displayVersion,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('•', style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14)),
                    const SizedBox(width: 12),

                    // Engine info
                    const Expanded(
                      child: Text(
                        'Database MySQL & SQLite Sinkron',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Check update button
                    _buildCheckUpdateBtn(context),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildCheckUpdateBtn(BuildContext context) {
    return InkWell(
      onTap: () {
        AppSnackbar.success(
          'Versi Terbaru',
          '${AppConstants.appName} v${AppConstants.appVersion} adalah rilis stabil terbaru. Tidak ada pembaruan tertunda.',
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync_rounded, size: 13, color: Color(0xFF475569)),
            SizedBox(width: 5),
            Text(
              'Cek Update',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER COMPONENTS & DESIGN TOKENS
  // ---------------------------------------------------------------------------
  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildCardActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: const Color(0xFFF1F5F9),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 13.5, color: const Color(0xFF475569)),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(width: 3),
              const Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Widget? trailingAction}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 15, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  ),
                ),
                if (trailingAction != null) ...[
                  const SizedBox(width: 6),
                  trailingAction,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required String title,
    required String subtitle,
    required bool isActive,
    String? activeText,
    String? inactiveText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isActive ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 11,
                  color: isActive ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  isActive ? (activeText ?? 'Aktif') : (inactiveText ?? 'Nonaktif'),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isActive ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, String note, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color, letterSpacing: 0.2),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 1.5),
          Text(
            note,
            style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8)),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          return ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Hero Banner Skeleton
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const ShimmerBox(width: 50, height: 50, borderRadius: 14),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          ShimmerBox(width: 180, height: 18, borderRadius: 4),
                          SizedBox(height: 8),
                          ShimmerBox(width: 260, height: 12, borderRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const ShimmerBox(width: 130, height: 38, borderRadius: 9),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4 Bento Cards Skeleton
              if (isWide) ...[
                Row(
                  children: const [
                    Expanded(child: ShimmerBox(height: 110, borderRadius: 14)),
                    SizedBox(width: 12),
                    Expanded(child: ShimmerBox(height: 110, borderRadius: 14)),
                    SizedBox(width: 12),
                    Expanded(child: ShimmerBox(height: 110, borderRadius: 14)),
                    SizedBox(width: 12),
                    Expanded(child: ShimmerBox(height: 110, borderRadius: 14)),
                  ],
                ),
              ] else ...[
                Row(
                  children: const [
                    Expanded(child: ShimmerBox(height: 100, borderRadius: 14)),
                    SizedBox(width: 12),
                    Expanded(child: ShimmerBox(height: 100, borderRadius: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Expanded(child: ShimmerBox(height: 100, borderRadius: 14)),
                    SizedBox(width: 12),
                    Expanded(child: ShimmerBox(height: 100, borderRadius: 14)),
                  ],
                ),
              ],
              const SizedBox(height: 18),

              // Paired Cards / Single Column Skeleton
              if (isWide) ...[
                Row(
                  children: const [
                    Expanded(child: ShimmerBox(height: 240, borderRadius: 16)),
                    SizedBox(width: 18),
                    Expanded(child: ShimmerBox(height: 240, borderRadius: 16)),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Expanded(child: ShimmerBox(height: 220, borderRadius: 16)),
                    SizedBox(width: 18),
                    Expanded(child: ShimmerBox(height: 220, borderRadius: 16)),
                  ],
                ),
              ] else ...[
                const ShimmerBox(width: double.infinity, height: 220, borderRadius: 16),
                const SizedBox(height: 14),
                const ShimmerBox(width: double.infinity, height: 220, borderRadius: 16),
                const SizedBox(height: 14),
                const ShimmerBox(width: double.infinity, height: 200, borderRadius: 16),
                const SizedBox(height: 14),
                const ShimmerBox(width: double.infinity, height: 200, borderRadius: 16),
              ],
            ],
          );
        },
      ),
    );
  }
}
