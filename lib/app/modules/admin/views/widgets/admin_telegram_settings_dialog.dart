import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../data/providers/api_provider.dart';

class AdminTelegramSettingsDialog extends StatefulWidget {
  const AdminTelegramSettingsDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AdminTelegramSettingsDialog(),
    );
  }

  @override
  State<AdminTelegramSettingsDialog> createState() => _AdminTelegramSettingsDialogState();
}

class _AdminTelegramSettingsDialogState extends State<AdminTelegramSettingsDialog> {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();

  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _chatIdController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTesting = false;
  bool _notifyTrx = true;
  bool _notifyShift = true;
  bool _notifyVoid = true;
  bool _isConfigured = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _chatIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiProvider.get(ApiConstants.adminTelegramSettings);
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        setState(() {
          _isConfigured = data['is_configured'] == true;
          _chatIdController.text = data['chat_id']?.toString() ?? '';
          if (data['bot_token_masked'] != null) {
            _tokenController.text = data['bot_token_masked'].toString();
          }
          _notifyTrx = data['notify_trx'] == true;
          _notifyShift = data['notify_shift'] == true;
          _notifyVoid = data['notify_void'] == true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat pengaturan: ${ApiProvider.getErrorMessage(e)}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final payload = <String, dynamic>{
        'chat_id': _chatIdController.text.trim(),
        'notify_trx': _notifyTrx,
        'notify_shift': _notifyShift,
        'notify_void': _notifyVoid,
      };

      // Only send token if user actually edited it and it doesn't contain masking
      final token = _tokenController.text.trim();
      if (token.isNotEmpty && !token.contains('***') && !token.contains('...')) {
        payload['bot_token'] = token;
      }

      final response = await _apiProvider.post(
        ApiConstants.adminTelegramSettings,
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        AppSnackbar.success('Berhasil', 'Pengaturan bot Telegram berhasil disimpan!');
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
        _errorMessage = ApiProvider.getErrorMessage(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _testNotification() async {
    setState(() {
      _isTesting = true;
    });

    try {
      final token = _tokenController.text.trim();
      final chatId = _chatIdController.text.trim();
      final payload = <String, dynamic>{};
      if (chatId.isNotEmpty) {
        payload['chat_id'] = chatId;
      }
      if (token.isNotEmpty && !token.contains('***') && !token.contains('...')) {
        payload['bot_token'] = token;
      }

      final response = await _apiProvider.post(
        ApiConstants.adminTelegramTest,
        data: payload.isNotEmpty ? payload : null,
      );
      if (response.data != null && response.data['success'] == true) {
        AppSnackbar.success('Terkirim', 'Pesan uji coba berhasil dikirim ke Telegram Owner!');
      } else {
        AppSnackbar.danger('Gagal', response.data?['message'] ?? 'Gagal mengirim pesan uji coba.');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal', ApiProvider.getErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
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
          constraints: const BoxConstraints(maxWidth: 520),
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
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Color(0xFF7E22CE),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Integrasi Bot Telegram Owner',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Laporan otomatis transaksi & penutupan shift ke Telegram',
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

                // Body
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

                              // Status Banner
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: _isConfigured ? const Color(0xFFF0FDF4) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _isConfigured ? const Color(0xFFBBF7D0) : const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _isConfigured ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                      color: _isConfigured ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _isConfigured
                                            ? 'Bot Telegram aktif dan siap mengirim laporan otomatis ke owner.'
                                            : 'Bot Telegram belum dikonfigurasi lengkap. Masukkan Bot Token & Chat ID.',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: _isConfigured ? const Color(0xFF15803D) : const Color(0xFF92400E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Bot Token
                              TextFormField(
                                controller: _tokenController,
                                decoration: InputDecoration(
                                  labelText: 'Telegram Bot Token',
                                  labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  prefixIcon: const Icon(Icons.key_rounded, size: 18),
                                  hintText: '123456789:ABCdefGHIjklMNO...',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Chat ID
                              TextFormField(
                                controller: _chatIdController,
                                decoration: InputDecoration(
                                  labelText: 'Target Chat ID (Owner / Group)',
                                  labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                  prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                                  hintText: 'Contoh: 123456789 atau -100123456789',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                ),
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'EVENT NOTIFIKASI OTOMATIS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 8),

                              _buildToggleItem(
                                title: 'Notifikasi Transaksi Baru Kasir',
                                subtitle: 'Kirim ringkasan nominal dan item setiap transaksi lunas',
                                value: _notifyTrx,
                                onChanged: (v) => setState(() => _notifyTrx = v),
                              ),
                              const SizedBox(height: 8),
                              _buildToggleItem(
                                title: 'Laporan Tutup Shift & Z-Report',
                                subtitle: 'Kirim ringkasan pendapatan tunai/QRIS saat kasir tutup shift',
                                value: _notifyShift,
                                onChanged: (v) => setState(() => _notifyShift = v),
                              ),
                              const SizedBox(height: 8),
                              _buildToggleItem(
                                title: 'Alert Pembatalan / Void Transaksi',
                                subtitle: 'Peringatan otomatis saat ada transaksi yang dibatalkan oleh kasir',
                                value: _notifyVoid,
                                onChanged: (v) => setState(() => _notifyVoid = v),
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
                      final isNarrow = constraints.maxWidth < 460;

                      final testButton = OutlinedButton.icon(
                        onPressed: (_isTesting || _isLoading) ? null : _testNotification,
                        icon: _isTesting
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.notifications_active_outlined, size: 16),
                        label: const Text('Kirim Uji Coba', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7E22CE),
                          side: const BorderSide(color: Color(0xFFD8B4FE)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      );

                      final cancelButton = OutlinedButton(
                        onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
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
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                        ),
                        child: _isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Simpan Pengaturan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            testButton,
                            const SizedBox(height: 8),
                            saveButton,
                            const SizedBox(height: 8),
                            cancelButton,
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          testButton,
                          Row(
                            children: [
                              cancelButton,
                              const SizedBox(width: 10),
                              saveButton,
                            ],
                          ),
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

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: const Color(0xFF7E22CE),
            activeTrackColor: const Color(0xFFE9D5FF),
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
                        ShimmerBox(width: 160, height: 14, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 200, height: 11, borderRadius: 4),
                      ],
                    ),
                  ),
                  const ShimmerBox(width: 44, height: 26, borderRadius: 14),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Instruction Banner
            const ShimmerBox(width: double.infinity, height: 56, borderRadius: 10),
            const SizedBox(height: 18),

            // Bot Token & Chat ID
            const ShimmerBox(width: 110, height: 12, borderRadius: 4),
            const SizedBox(height: 8),
            const ShimmerBox(width: double.infinity, height: 48, borderRadius: 10),
            const SizedBox(height: 14),
            const ShimmerBox(width: 120, height: 12, borderRadius: 4),
            const SizedBox(height: 8),
            const ShimmerBox(width: double.infinity, height: 48, borderRadius: 10),
            const SizedBox(height: 18),

            // Event toggles
            const ShimmerBox(width: 150, height: 12, borderRadius: 4),
            const SizedBox(height: 10),
            const ShimmerBox(width: double.infinity, height: 46, borderRadius: 8),
            const SizedBox(height: 8),
            const ShimmerBox(width: double.infinity, height: 46, borderRadius: 8),
            const SizedBox(height: 8),
            const ShimmerBox(width: double.infinity, height: 46, borderRadius: 8),
          ],
        ),
      ),
    );
  }
}
