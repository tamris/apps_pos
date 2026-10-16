import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../../data/models/customer_model.dart';
import '../../../../data/providers/api_provider.dart';
import '../../controllers/cart_controller.dart';

class MemberSelectorModal extends StatefulWidget {
  const MemberSelectorModal({super.key});

  static Future<void> show(BuildContext context) async {
    HapticFeedback.lightImpact();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MemberSelectorModal(),
    );
  }

  @override
  State<MemberSelectorModal> createState() => _MemberSelectorModalState();
}

class _MemberSelectorModalState extends State<MemberSelectorModal> {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final CartController _cartController = Get.find<CartController>();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _newPhoneController = TextEditingController();
  final TextEditingController _newNameController = TextEditingController();

  Timer? _debounce;
  bool _isLoading = false;
  bool _isRegistering = false;
  bool _showRegisterForm = false;
  List<CustomerModel> _searchResults = [];
  String _lastQuery = '';

  // Hybrid Mode: Riwayat member terakhir yang bertransaksi / baru terdaftar
  List<CustomerModel> _recentMembers = [];
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    _fetchRecentMembers();
    // Jika di keranjang sudah ada customerName (misal diisi kasir), jadikan query awal
    final existingName = _cartController.customerName.value.trim();
    if (existingName.isNotEmpty && _cartController.selectedCustomer.value == null) {
      _searchController.text = existingName;
      _searchMembers(existingName);
    }
  }

  Future<void> _fetchRecentMembers() async {
    setState(() {
      _isLoadingRecent = true;
    });

    try {
      final response = await _apiProvider.get(ApiConstants.customers);

      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        if (mounted) {
          setState(() {
            _recentMembers = list
                .map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e)))
                .toList();
            _isLoadingRecent = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingRecent = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingRecent = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _newPhoneController.dispose();
    _newNameController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchMembers(query);
    });
  }

  Future<void> _searchMembers(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 2) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
        _lastQuery = cleanQuery;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _lastQuery = cleanQuery;
    });

    try {
      final response = await _apiProvider.get(
        ApiConstants.customerSearch,
        queryParameters: {'query': cleanQuery},
      );

      if (response.data != null && response.data['success'] == true) {
        final List list = response.data['data'] ?? [];
        setState(() {
          _searchResults = list.map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e))).toList();
          _isLoading = false;
          // Jika tidak ada hasil dan query berupa nomor HP, auto buka form daftar
          if (_searchResults.isEmpty && RegExp(r'^[0-9+]+$').hasMatch(cleanQuery)) {
            _newPhoneController.text = cleanQuery;
            _showRegisterForm = true;
          }
        });
      } else {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _registerNewMember() async {
    final phone = _newPhoneController.text.trim();
    final name = _newNameController.text.trim();

    if (phone.length < 8) {
      AppSnackbar.warning('Nomor Tidak Valid', 'Nomor WhatsApp minimal 8 digit.');
      return;
    }

    setState(() {
      _isRegistering = true;
    });

    try {
      final response = await _apiProvider.post(
        ApiConstants.customers,
        data: {
          'phone': phone,
          if (name.isNotEmpty) 'name': name,
        },
      );

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        final isNew = response.data['is_new'] == true;
        final newCustomer = CustomerModel.fromJson(Map<String, dynamic>.from(data));

        _cartController.selectCustomer(newCustomer);
        HapticFeedback.mediumImpact();

        AppSnackbar.success(
          isNew ? 'Member Terdaftar!' : 'Member Ditemukan',
          isNew
              ? 'Member baru ${newCustomer.displayName} berhasil didaftarkan & dipasang ke pesanan.'
              : 'Member ${newCustomer.displayName} dipasang ke pesanan.',
        );

        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        AppSnackbar.danger('Gagal Mendaftar', response.data['message'] ?? 'Periksa data pendaftaran.');
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Mendaftar', ApiProvider.getErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  void _selectMember(CustomerModel member) {
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    _cartController.selectCustomer(member);
    Navigator.of(context).pop();
    AppSnackbar.success('Member Dipasang', '${member.displayName} aktif di transaksi kasir.');
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isTablet = MediaQuery.of(context).size.width >= 768;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 540 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.card_membership_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih Member Pelanggan',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Cari atau daftarkan member via WhatsApp',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Search Bar
              TextField(
                controller: _searchController,
                autofocus: false,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: 'Ketik No. WhatsApp (08...) atau Nama...',
                  hintStyle: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _searchMembers('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.lightBackground,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                ),
                onChanged: _onSearchChanged,
              ),
              const SizedBox(height: 12),

              // Quick Toggle / Action Row (Daftar Member Baru)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _showRegisterForm
                        ? 'Form Pendaftaran Baru:'
                        : (_lastQuery.length >= 2 ? 'Hasil Pencarian:' : 'Pilih Cepat / Terakhir:'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _showRegisterForm = !_showRegisterForm;
                        if (_showRegisterForm) {
                          final q = _searchController.text.trim();
                          if (RegExp(r'^[0-9+]+$').hasMatch(q)) {
                            _newPhoneController.text = q;
                          } else if (q.isNotEmpty) {
                            _newNameController.text = q;
                          }
                        }
                      });
                    },
                    icon: Icon(
                      _showRegisterForm ? Icons.arrow_back_rounded : Icons.person_add_alt_1_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      _showRegisterForm ? 'Kembali' : '+ Member Baru',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1),

              // Content Area: Quick Register Form OR Search Results OR Hybrid Home View
              Expanded(
                child: _showRegisterForm
                    ? _buildRegisterForm()
                    : (_lastQuery.length >= 2
                        ? _buildSearchResultsList()
                        : _buildHybridHomeView()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHybridHomeView() {
    final activeCustomer = _cartController.selectedCustomer.value;

    if (_isLoadingRecent) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
              SizedBox(height: 10),
              Text('Memuat pelanggan terakhir...', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    if (_recentMembers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline_rounded, size: 40, color: AppColors.textMuted.withAlpha(120)),
              const SizedBox(height: 10),
              const Text(
                'Belum Ada Riwayat Pelanggan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Gunakan kolom pencarian di atas atau klik "+ Member Baru".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _recentMembers.length + (activeCustomer != null ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (activeCustomer != null && index == 0) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aktif saat ini: ${activeCustomer.displayName} (${activeCustomer.formattedPhone})',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _cartController.removeCustomer();
                    Navigator.of(context).pop();
                    AppSnackbar.info('Member Dilepas', 'Transaksi saat ini tanpa status member.');
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Lepaskan',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        }

        final memberIndex = activeCustomer != null ? index - 1 : index;
        return _buildCustomerTile(_recentMembers[memberIndex]);
      },
    );
  }

  Widget _buildSearchResultsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
        ),
      );
    }

    if (_lastQuery.length < 2) {
      return _buildHybridHomeView();
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 44,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: 8),
              Text(
                'Tidak ada member "$_lastQuery"',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pelanggan ini belum terdaftar sebagai member loyalitas.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() {
                    _showRegisterForm = true;
                    if (RegExp(r'^[0-9+]+$').hasMatch(_lastQuery)) {
                      _newPhoneController.text = _lastQuery;
                    } else {
                      _newNameController.text = _lastQuery;
                    }
                  });
                },
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                label: const Text('Daftarkan Sekarang (1 Ketukan)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _buildCustomerTile(_searchResults[index]);
      },
    );
  }

  Widget _buildCustomerTile(CustomerModel member) {
    final isAlreadySelected = _cartController.selectedCustomer.value?.id == member.id;

    return Material(
      color: isAlreadySelected ? AppColors.primarySoft : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _selectMember(member),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isAlreadySelected ? AppColors.primary : AppColors.lightBorder,
              width: isAlreadySelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isAlreadySelected
                        ? [AppColors.primary, AppColors.primaryDark]
                        : [AppColors.lightBackground, AppColors.lightBorder],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    member.initials,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isAlreadySelected ? Colors.white : AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (isAlreadySelected) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Aktif',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.phone_iphone_rounded, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          member.formattedPhone,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Points Chip
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${member.pointsBalance} Poin',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.pointsRupiahFormatted,
                    style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryLight.withAlpha(100)),
            ),
            child: const Row(
              children: [
                Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pendaftaran instan di kasir: Cukup isi Nomor WhatsApp. Pelanggan langsung mendapatkan poin dari pesanan ini!',
                    style: TextStyle(fontSize: 12, color: AppColors.primaryDark, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // No WhatsApp (Wajib)
          const Text(
            'Nomor WhatsApp Pelanggan *',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _newPhoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Misal: 081234567890',
              prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 20),
              filled: true,
              fillColor: AppColors.lightBackground,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lightBorder),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Nama Pelanggan (Opsional)
          const Text(
            'Nama Pelanggan (Opsional)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _newNameController,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'Misal: Kak Rian Pratama',
              prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 20),
              filled: true,
              fillColor: AppColors.lightBackground,
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lightBorder),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Tombol Daftarkan & Pasang
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isRegistering ? null : _registerNewMember,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isRegistering
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Mendaftarkan Member...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Daftar & Pasang Member ke Pesanan',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
