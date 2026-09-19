import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/app_snackbar.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/core/widgets/app_cached_image.dart';
import 'package:noli_apps/app/data/models/admin_product_model.dart';
import 'package:noli_apps/app/data/models/product_ingredient_model.dart';
import 'package:noli_apps/app/data/models/admin_ingredient_model.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

class AdminProductFormDialog {
  static Future<bool?> show(
    BuildContext context, {
    AdminProductModel? product,
    List<ProductIngredientModel>? prefilledIngredients,
    String? initialName,
    double? initialPrice,
  }) async {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    if (isTablet) {
      return await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: Colors.white,
          elevation: 12,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
            child: _ProductFormContent(
              dialogContext: dialogContext,
              product: product,
              prefilledIngredients: prefilledIngredients,
              initialName: initialName,
              initialPrice: initialPrice,
            ),
          ),
        ),
      );
    } else {
      return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.92,
            ),
            child: _ProductFormContent(
              dialogContext: sheetContext,
              product: product,
              prefilledIngredients: prefilledIngredients,
              initialName: initialName,
              initialPrice: initialPrice,
              isSheet: true,
            ),
          ),
        ),
      );
    }
  }
}

class _ProductFormContent extends StatefulWidget {
  final BuildContext dialogContext;
  final AdminProductModel? product;
  final List<ProductIngredientModel>? prefilledIngredients;
  final String? initialName;
  final double? initialPrice;
  final bool isSheet;

  const _ProductFormContent({
    required this.dialogContext,
    this.product,
    this.prefilledIngredients,
    this.initialName,
    this.initialPrice,
    this.isSheet = false,
  });

  @override
  State<_ProductFormContent> createState() => _ProductFormContentState();
}

class _ProductFormContentState extends State<_ProductFormContent> {
  final AdminController controller = Get.find<AdminController>();

  // Sub-tabs in form: 0 = Informasi Utama, 1 = Resep Bahan Baku & HPP
  int _activeSubTab = 0;

  // Controllers & Form fields
  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _barcodeController;
  late TextEditingController _priceController;
  late TextEditingController _manualHppController;
  late TextEditingController _descriptionController;
  late TextEditingController _operationalCostController;

  int? _selectedCategoryId;
  bool _isActive = true;
  bool _useManualHpp = false;
  File? _pickedImage;

  // Ingredients list
  final List<ProductIngredientModel> _ingredients = [];

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _nameController = TextEditingController(
      text: p?.name ?? widget.initialName ?? '',
    );
    _skuController = TextEditingController(text: p?.sku ?? '');
    _barcodeController = TextEditingController(text: p?.barcode ?? '');
    _priceController = TextEditingController(
      text: p != null && p.price > 0
          ? CurrencyFormatter.formatWithoutSymbol(p.price)
          : widget.initialPrice != null && widget.initialPrice! > 0
          ? CurrencyFormatter.formatWithoutSymbol(widget.initialPrice!)
          : '',
    );
    _manualHppController = TextEditingController(
      text: p != null && p.hargaBeli > 0
          ? CurrencyFormatter.formatWithoutSymbol(p.hargaBeli)
          : '',
    );
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _operationalCostController = TextEditingController(
      text: p != null && p.operationalCost > 0
          ? CurrencyFormatter.formatWithoutSymbol(p.operationalCost)
          : '1.000',
    );

    _selectedCategoryId =
        p?.categoryId ??
        (controller.productCategories.isNotEmpty
            ? controller.productCategories.first.id
            : null);
    _isActive = p?.isActive ?? true;

    // Load initial ingredients
    if (p != null && p.ingredients.isNotEmpty) {
      _ingredients.addAll(p.ingredients);
      _useManualHpp = false;
    } else if (widget.prefilledIngredients != null &&
        widget.prefilledIngredients!.isNotEmpty) {
      _ingredients.addAll(widget.prefilledIngredients!);
      _useManualHpp = false;
    } else if (p != null && p.hargaBeli > 0) {
      _useManualHpp = true;
    }

    // Jika sedang edit dan ada detail lengkap di server, muat resep aslinya
    if (p != null && p.ingredients.isEmpty && p.ingredientsCount > 0) {
      _fetchFullDetail(p.id);
    }
  }

  Future<void> _fetchFullDetail(int id) async {
    final detail = await controller.fetchProductDetail(id);
    if (detail != null && mounted) {
      setState(() {
        _ingredients.clear();
        _ingredients.addAll(detail.ingredients);
        if (_ingredients.isNotEmpty) {
          _useManualHpp = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    _manualHppController.dispose();
    _descriptionController.dispose();
    _operationalCostController.dispose();
    super.dispose();
  }

  double get _calculatedTotalVariableCost {
    double sum = 0;
    for (final ing in _ingredients) {
      sum += ing.subtotal;
    }
    return sum;
  }

  double get _effectiveHpp {
    if (_useManualHpp) {
      final clean = _manualHppController.text.replaceAll(RegExp(r'[^\d]'), '');
      return double.tryParse(clean) ?? 0.0;
    }
    final cleanOps = _operationalCostController.text.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
    final ops = double.tryParse(cleanOps) ?? 0.0;
    return _calculatedTotalVariableCost + ops;
  }

  double get _sellingPrice {
    final clean = _priceController.text.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  double get _profit {
    return (_sellingPrice - _effectiveHpp).clamp(0, double.infinity);
  }

  double get _marginPercent {
    if (_sellingPrice <= 0) return 0.0;
    return (_profit / _sellingPrice) * 100;
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _pickedImage = File(result.files.single.path!);
        });
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Memilih Gambar', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Drag handle on mobile sheet
        if (widget.isSheet) ...[
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Color(0xFF0F172A),
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product != null
                          ? 'Edit Menu Cafe'
                          : 'Tambah Menu Baru',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      widget.product != null
                          ? 'Perbarui data menu, resep bahan & estimasi modal'
                          : 'Lengkapi info menu, resep bahan baku & perhitungan margin',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(widget.dialogContext).pop(),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 17,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // Segmented Sub-tab Header (Informasi Menu <-> Resep Bahan & HPP)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSubTabBtn(
                    index: 0,
                    label: 'Informasi Menu',
                    icon: Icons.info_outline_rounded,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _buildSubTabBtn(
                    index: 1,
                    label: 'Resep Bahan & HPP',
                    icon: Icons.calculate_outlined,
                    badgeText: _ingredients.isNotEmpty
                        ? '${_ingredients.length}'
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Scrollable Tab Body
        Flexible(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: _activeSubTab == 0 ? _buildInfoTab() : _buildRecipeTab(),
          ),
        ),

        // Live Margin Summary Bar at bottom
        _buildBottomMarginSummary(),

        // Bottom Action Buttons
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(widget.dialogContext).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() {
                  final isSaving = controller.isSubmittingProduct.value;
                  return ElevatedButton(
                    onPressed: isSaving ? null : _saveProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            widget.product != null
                                ? 'Simpan Perubahan'
                                : 'Tambah Menu Sekarang',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubTabBtn({
    required int index,
    required String label,
    required IconData icon,
    String? badgeText,
  }) {
    final isSelected = _activeSubTab == index;
    return Material(
      color: isSelected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(7),
      elevation: isSelected ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: () => setState(() => _activeSubTab = index),
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7.5, horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: isSelected ? const Color(0xFFE2E8F0) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeText != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF64748B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHppModeOption({
    required bool isSelected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isSelected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      elevation: isSelected ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFFE2E8F0) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? AppColors.primary : const Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF0F172A)
                            : const Color(0xFF475569),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: INFORMASI MENU
  // ---------------------------------------------------------------------------
  Widget _buildInfoTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Upload Section
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: _pickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.file(_pickedImage!, fit: BoxFit.cover),
                          )
                        : widget.product?.imageUrl != null &&
                              widget.product!.imageUrl!.isNotEmpty
                        ? AppCachedImage(
                            imageUrl: widget.product!.imageUrl,
                            width: 72,
                            height: 72,
                            borderRadius: 9,
                            fit: BoxFit.cover,
                            placeholderIcon: Icons.restaurant_menu_rounded,
                          )
                        : const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Color(0xFF94A3B8),
                            size: 28,
                          ),
                  ),
                  if (_pickedImage != null)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: InkWell(
                        onTap: () => setState(() => _pickedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Foto Menu Cafe',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Format: JPG, PNG, WEBP (maks. 5MB). Ditampilkan di POS kasir & struk digital.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(
                        Icons.upload_file_outlined,
                        size: 14,
                        color: Color(0xFF0F172A),
                      ),
                      label: Text(
                        _pickedImage != null ? 'Ganti Foto' : 'Pilih Foto...',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Nama Menu & Kategori
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Nama Menu *'),
                  SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _nameController,
                      onChanged: (_) => setState(() {}),
                      decoration: _buildInputDecoration(
                        hint: 'Contoh: Iced Caramel Macchiato',
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildLabel('Kategori *'), _buildCategorySelect()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Harga Jual & Status Aktif
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Harga Jual (Rp) *'),
                  SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: _buildInputDecoration(
                        hint: '0',
                        prefix: 'Rp ',
                      ),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Status Penjualan'),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isActive
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isActive ? 'Aktif (Dijual)' : 'Nonaktif',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _isActive
                                    ? const Color(0xFF047857)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 28,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Switch.adaptive(
                              value: _isActive,
                              activeTrackColor: AppColors.primary,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              onChanged: (val) =>
                                  setState(() => _isActive = val),
                            ),
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
        const SizedBox(height: 14),

        // HPP / Resep Shortcut Banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Icon(
                  Icons.calculate_outlined,
                  color: Color(0xFF0F172A),
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _ingredients.isNotEmpty
                          ? 'Resep & HPP: ${_currencyFormat.format(_effectiveHpp)} (${_ingredients.length} Bahan)'
                          : (_effectiveHpp > 0
                                ? 'Modal HPP: ${_currencyFormat.format(_effectiveHpp)}'
                                : 'Modal HPP Belum Ditentukan'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _sellingPrice > 0 && _effectiveHpp > 0
                          ? 'Est. Margin: ${_marginPercent.toStringAsFixed(1)}% • Laba: ${_currencyFormat.format(_profit)}'
                          : 'Kelola takaran gram/ml bahan baku untuk pantau margin',
                      style: TextStyle(
                        fontSize: 11,
                        color: _marginPercent >= 40
                            ? const Color(0xFF059669)
                            : const Color(0xFF64748B),
                        fontWeight: _marginPercent >= 40
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => setState(() => _activeSubTab = 1),
                icon: const Icon(
                  Icons.tune_rounded,
                  size: 13,
                  color: Color(0xFF0F172A),
                ),
                label: Text(
                  _ingredients.isNotEmpty ? 'Ubah Resep' : 'Atur Resep',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // SKU & Barcode (Optional)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('SKU / Kode Menu', isOptional: true),
                  SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _skuController,
                      decoration: _buildInputDecoration(
                        hint: 'Otomatis dibuat jika kosong',
                      ),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Barcode / Scan', isOptional: true),
                  SizedBox(
                    height: 48,
                    child: TextField(
                      controller: _barcodeController,
                      decoration: _buildInputDecoration(
                        hint: 'Scan atau ketik kode barcode',
                      ),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Deskripsi Menu
        _buildLabel('Deskripsi Menu', isOptional: true),
        TextField(
          controller: _descriptionController,
          maxLines: 2,
          decoration: _buildInputDecoration(
            hint: 'Catatan rasa, asal biji kopi, varian suhu...',
            isMultiline: true,
          ),
          style: const TextStyle(fontSize: 12.5),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: RESEP BAHAN & HPP
  // ---------------------------------------------------------------------------
  Widget _buildRecipeTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Selector: Gunakan Resep Bahan vs Input Manual
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildHppModeOption(
                  isSelected: !_useManualHpp,
                  icon: Icons.kitchen_rounded,
                  title: 'Kalkulasi Resep',
                  subtitle: '${_ingredients.length} bahan baku',
                  onTap: () {
                    setState(() {
                      _useManualHpp = false;
                    });
                  },
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildHppModeOption(
                  isSelected: _useManualHpp,
                  icon: Icons.edit_note_rounded,
                  title: 'Nominal HPP Manual',
                  subtitle: 'Bebas atur nominal',
                  onTap: () {
                    setState(() {
                      _useManualHpp = true;
                      if (_manualHppController.text.isEmpty ||
                          _manualHppController.text == '0') {
                        final currentHpp =
                            _calculatedTotalVariableCost +
                            (double.tryParse(
                                  _operationalCostController.text.replaceAll(
                                    RegExp(r'[^\d]'),
                                    '',
                                  ),
                                ) ??
                                0.0);
                        if (currentHpp > 0) {
                          _manualHppController.text =
                              CurrencyFormatter.formatWithoutSymbol(currentHpp);
                        }
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_useManualHpp) ...[
          _buildLabel('Harga Beli / Modal HPP Satuan (Rp) *'),
          SizedBox(
            height: 48,
            child: TextField(
              controller: _manualHppController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              onChanged: (_) => setState(() {}),
              decoration: _buildInputDecoration(
                hint: 'Contoh: 8.500',
                prefix: 'Rp ',
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          _buildLabel(
            'Alokasi Biaya Operasional Toko (Rp / porsi)',
            isOptional: true,
          ),
          SizedBox(
            height: 48,
            child: TextField(
              controller: _operationalCostController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              onChanged: (_) => setState(() {}),
              decoration: _buildInputDecoration(
                hint: 'Contoh: 1.000',
                prefix: 'Rp ',
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ] else ...[
          // Header Resep + Tombol AI Resep & Tambah Bahan
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daftar Bahan Baku & Takaran',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Total Bahan: ${_ingredients.length} item • Total Food Cost: ${_currencyFormat.format(_calculatedTotalVariableCost)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Estimate Recipe Button
              ElevatedButton.icon(
                onPressed: _triggerAiRecipe,
                icon: const Icon(
                  Icons.calculate_outlined,
                  size: 15,
                  color: Colors.white,
                ),
                label: const Text(
                  'Estimasi Resep',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 8),
              // Add Manual Row Button
              OutlinedButton.icon(
                onPressed: _addIngredientDialog,
                icon: const Icon(
                  Icons.add_rounded,
                  size: 15,
                  color: AppColors.primary,
                ),
                label: const Text(
                  'Tambah Bahan',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Table / List of Ingredients
          if (_ingredients.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.kitchen_rounded,
                    color: Color(0xFF94A3B8),
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Belum Ada Bahan Baku',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tambahkan bahan secara manual atau klik tombol "Estimasi Resep" untuk formulasi takaran porsi standar.',
                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // ElevatedButton.icon(
                  //   onPressed: _triggerAiRecipe,
                  //   icon: const Icon(Icons.calculate_outlined, size: 15, color: Colors.white),
                  //   label: const Text('Estimasi Resep Otomatis', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white)),
                  //   style: ElevatedButton.styleFrom(
                  //     backgroundColor: const Color(0xFF0F172A),
                  //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  //   ),
                  // ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ingredients.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final ing = _ingredients[index];
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => _showIngredientDialog(index: index),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ing.name,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  'Takaran: ${ing.amount % 1 == 0 ? ing.amount.toInt() : ing.amount} ${ing.unit} • Beli: ${_currencyFormat.format(ing.buyPrice)} / ${ing.buyAmount % 1 == 0 ? ing.buyAmount.toInt() : ing.buyAmount} ${ing.buyUnit}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _currencyFormat.format(ing.subtotal),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'Edit Bahan',
                            icon: const Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: Color(0xFF0F172A),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            onPressed: () =>
                                _showIngredientDialog(index: index),
                          ),
                          IconButton(
                            tooltip: 'Hapus Bahan',
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 16,
                              color: AppColors.danger,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            onPressed: () {
                              setState(() {
                                _ingredients.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 16),
          // Operational Overhead Allocation
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(
                      'Alokasi Biaya Operasional / Cup (Rp)',
                      isOptional: true,
                    ),
                    SizedBox(
                      height: 48,
                      child: TextField(
                        controller: _operationalCostController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter(),
                        ],
                        onChanged: (_) => setState(() {}),
                        decoration: _buildInputDecoration(
                          hint: '1.000',
                          prefix: 'Rp ',
                        ),
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Total HPP Recipe Summary & Quick Edit Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Food Cost + Operasional:',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      _currencyFormat.format(_effectiveHpp),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                // OutlinedButton.icon(
                //   onPressed: () {
                //     setState(() {
                //       _useManualHpp = true;
                //       _manualHppController.text = CurrencyFormatter.formatWithoutSymbol(_effectiveHpp);
                //     });
                //   },
                //   icon: const Icon(Icons.tune_rounded, size: 13, color: Color(0xFF0F172A)),
                //   label: const Text(
                //     'Ubah Nominal HPP',
                //     style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                //   ),
                //   style: OutlinedButton.styleFrom(
                //     visualDensity: VisualDensity.compact,
                //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                //     side: const BorderSide(color: Color(0xFFCBD5E1)),
                //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // BOTTOM SUMMARY: LIVE FOOD COST & MARGIN PREVIEW
  // ---------------------------------------------------------------------------
  Widget _buildBottomMarginSummary() {
    final hasPrice = _sellingPrice > 0;
    final hasHpp = _effectiveHpp > 0;
    final marginVal = _marginPercent;
    final isHealthy = marginVal >= 45.0;
    final isCritical = marginVal < 35.0;

    // 1. If selling price is not entered yet
    if (!hasPrice) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          border: Border(
            top: BorderSide(color: Color(0xFFE2E8F0)),
            bottom: BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF64748B),
              size: 18,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        hasHpp
                            ? 'Estimasi Modal HPP: ${_currencyFormat.format(_effectiveHpp)}'
                            : 'Modal HPP Belum Ditentukan',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (hasHpp && _ingredients.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${_ingredients.length} Bahan)',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    'Isi Harga Jual di atas untuk melihat simulasi margin dan potensi laba.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 2. Selling price is filled, calculate live margin
    final color = isCritical
        ? AppColors.danger
        : isHealthy
        ? const Color(0xFF059669)
        : const Color(0xFFD97706);
    final bgColor = isCritical
        ? const Color(0xFFFEF2F2)
        : isHealthy
        ? const Color(0xFFECFDF5)
        : const Color(0xFFFFFBEB);
    final borderColor = isCritical
        ? const Color(0xFFFECACA)
        : isHealthy
        ? const Color(0xFFA7F3D0)
        : const Color(0xFFFDE68A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          top: BorderSide(color: borderColor),
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCritical
                ? Icons.warning_amber_rounded
                : isHealthy
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Estimasi HPP: ${_currencyFormat.format(_effectiveHpp)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• Laba Bersih: ${_currencyFormat.format(_profit)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Margin Menu: ${marginVal.toStringAsFixed(1)}% (${isHealthy
                      ? "Sangat Sehat (>= 45%)"
                      : isCritical
                      ? "Margin Rendah (< 35%), pertimbangkan penyesuaian harga"
                      : "Cukup Sehat"})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool isOptional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          if (isOptional) ...[
            const SizedBox(width: 4),
            const Text(
              '(opsional)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.normal,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    String? prefix,
    double height = 48,
    bool isMultiline = false,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefix,
      prefixStyle: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F172A),
      ),
      hintStyle: const TextStyle(
        fontSize: 12.5,
        color: Color(0xFF94A3B8),
        fontWeight: FontWeight.normal,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: isMultiline ? 11 : 14,
      ),
      constraints: isMultiline
          ? null
          : BoxConstraints(minHeight: height, maxHeight: height),
      filled: true,
      fillColor: Colors.white,
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
      isDense: true,
    );
  }

  Widget _buildCategorySelect() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedCategoryId,
          isDense: true,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: Color(0xFF64748B),
          ),
          hint: const Text(
            'Pilih Kategori',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
          ),
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
          ),
          items: controller.productCategories.map((c) {
            return DropdownMenuItem<int?>(
              value: c.id,
              child: Text(
                c.name,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedCategoryId = val;
            });
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AI RECIPE GENERATOR
  // ---------------------------------------------------------------------------
  Future<void> _triggerAiRecipe() async {
    final currentName = _nameController.text.trim();
    final nameInput = TextEditingController(text: currentName);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.calculate_outlined, color: Color(0xFF0F172A), size: 22),
            SizedBox(width: 8),
            Text(
              'Estimasi Resep Bahan Baku',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sistem akan menghitung takaran porsi bahan baku standar cafe (biji kopi, susu, sirup, cup) beserta estimasi harga modal pasaran.',
              style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameInput,
              decoration: InputDecoration(
                labelText: 'Nama Menu Cafe',
                hintText: 'Misal: Iced Vanilla Latte',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
            ),
            child: const Text(
              'Hitung Resep',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && nameInput.text.trim().isNotEmpty) {
      final success = await controller.generateAiRecipe(nameInput.text.trim());
      if (success && mounted) {
        setState(() {
          _nameController.text = nameInput.text.trim();
          _ingredients.clear();
          _ingredients.addAll(controller.simulationIngredients);
          _useManualHpp = false;
          if (_priceController.text.isEmpty &&
              controller.simulationSellingPrice.value > 0) {
            _priceController.text = CurrencyFormatter.formatWithoutSymbol(
              controller.simulationSellingPrice.value,
            );
          }
          _activeSubTab = 1; // Pindah ke tab resep untuk review
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // SEARCH INGREDIENT PICKER MODAL (Master Gudang)
  // ---------------------------------------------------------------------------
  Future<void> _openSearchIngredientPickerModal(
    BuildContext parentContext,
    int? currentIngredientId,
    ValueChanged<AdminIngredientModel?> onSelected,
  ) async {
    String query = '';
    await showDialog(
      context: parentContext,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allIngredients = controller.ingredients;
            final filtered = allIngredients.where((i) {
              if (query.trim().isEmpty) return true;
              final q = query.trim().toLowerCase();
              return i.name.toLowerCase().contains(q) ||
                  i.unit.toLowerCase().contains(q) ||
                  i.category.toLowerCase().contains(q);
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: Color(0xFF4F46E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cari Bahan Baku Master',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Pilih bahan gudang untuk dimasukkan ke resep',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(modalCtx).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Color(0xFF94A3B8),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              content: SizedBox(
                width: 460,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      autofocus: true,
                      onChanged: (val) {
                        setModalState(() {
                          query = val;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Ketik nama bahan baku...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  setModalState(() {
                                    query = '';
                                  });
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    // Opsi Input Manual / Kosongkan
                    InkWell(
                      onTap: () {
                        onSelected(null);
                        Navigator.of(modalCtx).pop();
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: currentIngredientId == null
                              ? const Color(0xFFF1F5F9)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.edit_note_rounded,
                              size: 16,
                              color: Color(0xFF64748B),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '-- Input Manual / Bahan Baru (Tanpa Link Gudang) --',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.inventory_2_outlined,
                                    size: 36,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    query.isEmpty
                                        ? 'Belum ada data bahan di master gudang'
                                        : 'Bahan "$query" tidak ditemukan',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                color: Color(0xFFF1F5F9),
                              ),
                              itemBuilder: (ctx, i) {
                                final item = filtered[i];
                                final isSelected =
                                    item.id == currentIngredientId;
                                return InkWell(
                                  onTap: () {
                                    onSelected(item);
                                    Navigator.of(modalCtx).pop();
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFEEF2FF)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w600,
                                                  color: isSelected
                                                      ? const Color(0xFF4F46E5)
                                                      : const Color(0xFF1E293B),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Beli: ${CurrencyFormatter.format(item.buyPrice)} / ${item.buyAmount % 1 == 0 ? item.buyAmount.toInt() : item.buyAmount} ${item.buyUnit}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: item.isOutOfStock
                                                ? const Color(0xFFFEE2E2)
                                                : (item.isLowStock
                                                    ? const Color(0xFFFEF3C7)
                                                    : const Color(0xFFDCFCE7)),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'Stok: ${item.formattedStock} ${item.unit}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: item.isOutOfStock
                                                  ? const Color(0xFFDC2626)
                                                  : (item.isLowStock
                                                      ? const Color(0xFFD97706)
                                                      : const Color(
                                                          0xFF16A34A,
                                                        )),
                                            ),
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            size: 18,
                                            color: Color(0xFF4F46E5),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // ADD & EDIT INGREDIENT DIALOG
  // ---------------------------------------------------------------------------
  void _addIngredientDialog() => _showIngredientDialog();

  void _showIngredientDialog({int? index}) {
    final isEditing =
        index != null && index >= 0 && index < _ingredients.length;
    final existing = isEditing ? _ingredients[index] : null;

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final amountCtrl = TextEditingController(
      text: existing != null
          ? (existing.amount % 1 == 0
                ? existing.amount.toInt().toString()
                : existing.amount.toString())
          : '15',
    );
    String unit = existing?.unit ?? 'gram';
    final buyPriceCtrl = TextEditingController(
      text: existing != null
          ? CurrencyFormatter.formatWithoutSymbol(existing.buyPrice)
          : '100.000',
    );
    final buyAmountCtrl = TextEditingController(
      text: existing != null
          ? (existing.buyAmount % 1 == 0
                ? existing.buyAmount.toInt().toString()
                : existing.buyAmount.toString())
          : '1',
    );
    String buyUnit = existing?.buyUnit ?? 'kg';
    int? ingredientId = existing?.ingredientId;
    if (ingredientId == null && existing != null && controller.ingredients.isNotEmpty) {
      final matched = controller.ingredients.firstWhereOrNull(
        (i) => i.name.trim().toLowerCase() == existing.name.trim().toLowerCase(),
      );
      if (matched != null) {
        ingredientId = matched.id;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) {
          final amt =
              double.tryParse(
                amountCtrl.text.replaceAll(RegExp(r'[^\d.]'), ''),
              ) ??
              0.0;
          final bp =
              double.tryParse(
                buyPriceCtrl.text.replaceAll(RegExp(r'[^\d]'), ''),
              ) ??
              0.0;
          final ba =
              double.tryParse(
                buyAmountCtrl.text.replaceAll(RegExp(r'[^\d.]'), ''),
              ) ??
              1.0;
          final liveSubtotal = ProductIngredientModel.calculateLocalSubtotal(
            amt,
            unit,
            bp,
            ba,
            buyUnit,
          );

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(
                  isEditing
                      ? Icons.edit_note_rounded
                      : Icons.add_circle_outline_rounded,
                  color: const Color(0xFF0F172A),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'Edit Bahan Baku' : 'Tambah Bahan Baku',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Pick dari Master Bahan Baku Gudang
                    if (controller.ingredients.isNotEmpty) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF4F46E5)),
                                SizedBox(width: 6),
                                Text(
                                  'Pilih dari Master Bahan Baku (Gudang):',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (ctx) {
                                final selectedIng = ingredientId != null
                                    ? controller.ingredients.firstWhereOrNull((i) => i.id == ingredientId)
                                    : null;

                                void applyPicked(AdminIngredientModel? picked) {
                                  setDlgState(() {
                                    if (picked != null) {
                                      ingredientId = picked.id;
                                      nameCtrl.text = picked.name;
                                      final pickedUnit = ['gram', 'ml', 'pcs', 'sachet', 'kg', 'liter'].contains(picked.unit.toLowerCase())
                                          ? picked.unit.toLowerCase()
                                          : 'gram';
                                      unit = pickedUnit;
                                      // Smart auto-set default amount based on picked unit
                                      if (amountCtrl.text == '15' || amountCtrl.text == '1' || amountCtrl.text.isEmpty) {
                                        amountCtrl.text = (pickedUnit == 'pcs' || pickedUnit == 'sachet')
                                            ? '1'
                                            : (pickedUnit == 'ml' ? '30' : '15');
                                      }
                                      buyPriceCtrl.text = CurrencyFormatter.formatWithoutSymbol(picked.buyPrice);
                                      buyAmountCtrl.text = picked.buyAmount % 1 == 0
                                          ? picked.buyAmount.toInt().toString()
                                          : picked.buyAmount.toString();
                                      buyUnit = ['kg', 'liter', 'pcs', 'gram', 'ml', 'sachet'].contains(picked.buyUnit.toLowerCase())
                                          ? picked.buyUnit.toLowerCase()
                                          : 'kg';
                                    } else {
                                      ingredientId = null;
                                    }
                                  });
                                }

                                return InkWell(
                                  onTap: () {
                                    _openSearchIngredientPickerModal(
                                      context,
                                      ingredientId,
                                      (picked) => applyPicked(picked),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: selectedIng != null
                                            ? const Color(0xFF818CF8)
                                            : const Color(0xFFCBD5E1),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          selectedIng != null
                                              ? Icons.inventory_2_rounded
                                              : Icons.search_rounded,
                                          size: 16,
                                          color: selectedIng != null
                                              ? const Color(0xFF4F46E5)
                                              : const Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: selectedIng != null
                                              ? Row(
                                                  children: [
                                                    Flexible(
                                                      child: Text(
                                                        selectedIng.name,
                                                        style: const TextStyle(
                                                          fontSize: 12.5,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF0F172A),
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: selectedIng.isOutOfStock
                                                            ? const Color(0xFFFEE2E2)
                                                            : (selectedIng.isLowStock
                                                                ? const Color(0xFFFEF3C7)
                                                                : const Color(0xFFDCFCE7)),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: Text(
                                                        'Stok: ${selectedIng.formattedStock} ${selectedIng.unit}',
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight: FontWeight.w700,
                                                          color: selectedIng.isOutOfStock
                                                              ? const Color(0xFFDC2626)
                                                              : (selectedIng.isLowStock
                                                                  ? const Color(0xFFD97706)
                                                                  : const Color(0xFF16A34A)),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : const Text(
                                                  '-- Cari / Pilih Bahan Baku Gudang --',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF94A3B8),
                                                  ),
                                                ),
                                        ),
                                        if (selectedIng != null) ...[
                                          InkWell(
                                            onTap: () => applyPicked(null),
                                            borderRadius: BorderRadius.circular(12),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              child: Icon(
                                                Icons.cancel_rounded,
                                                size: 16,
                                                color: Color(0xFF94A3B8),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                        ],
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 20,
                                          color: Color(0xFF64748B),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Bahan *',
                        hintText: 'Contoh: Susu Segar (Fresh Milk)',
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setDlgState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Takaran Porsi *',
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('recipe_unit_$unit'),
                            initialValue:
                                [
                                  'gram',
                                  'ml',
                                  'pcs',
                                  'sachet',
                                  'kg',
                                  'liter',
                                ].contains(unit)
                                ? unit
                                : 'gram',
                            menuMaxHeight: 220,
                            borderRadius: BorderRadius.circular(8),
                            dropdownColor: Colors.white,
                            decoration: const InputDecoration(
                              labelText: 'Satuan',
                            ),
                            items:
                                ['gram', 'ml', 'pcs', 'sachet', 'kg', 'liter']
                                    .map(
                                      (u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(
                                          u,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDlgState(() {
                                  unit = val;
                                  // Smart defaults when unit changes
                                  if (val == 'pcs' || val == 'sachet') {
                                    if (amountCtrl.text == '15' || amountCtrl.text.isEmpty) {
                                      amountCtrl.text = '1';
                                    }
                                    if (buyUnit == 'kg' || buyUnit == 'liter') {
                                      buyUnit = 'pcs';
                                      if (buyPriceCtrl.text == '100.000') {
                                        buyPriceCtrl.text = '1.000';
                                      }
                                    }
                                  } else if (val == 'gram') {
                                    if (amountCtrl.text == '1' || amountCtrl.text.isEmpty) {
                                      amountCtrl.text = '15';
                                    }
                                    if (buyUnit == 'pcs' || buyUnit == 'liter') {
                                      buyUnit = 'kg';
                                      if (buyPriceCtrl.text == '1.000') {
                                        buyPriceCtrl.text = '100.000';
                                      }
                                    }
                                  } else if (val == 'ml') {
                                    if (amountCtrl.text == '15' || amountCtrl.text == '1' || amountCtrl.text.isEmpty) {
                                      amountCtrl.text = '30';
                                    }
                                    if (buyUnit == 'pcs' || buyUnit == 'kg') {
                                      buyUnit = 'liter';
                                      if (buyPriceCtrl.text == '1.000') {
                                        buyPriceCtrl.text = '25.000';
                                      }
                                    }
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: buyPriceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      onChanged: (_) => setDlgState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Harga Beli Kemasan (Rp) *',
                        prefixText: 'Rp ',
                        hintText: 'Contoh: 20.000',
                      ),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: buyAmountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setDlgState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Isi Kemasan Beli *',
                            ),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('recipe_buy_unit_$buyUnit'),
                            initialValue:
                                [
                                  'kg',
                                  'liter',
                                  'pcs',
                                  'gram',
                                  'ml',
                                  'sachet',
                                ].contains(buyUnit)
                                ? buyUnit
                                : 'kg',
                            menuMaxHeight: 220,
                            borderRadius: BorderRadius.circular(8),
                            dropdownColor: Colors.white,
                            decoration: const InputDecoration(
                              labelText: 'Satuan Beli',
                            ),
                            items:
                                ['kg', 'liter', 'pcs', 'gram', 'ml', 'sachet']
                                    .map(
                                      (u) => DropdownMenuItem(
                                        value: u,
                                        child: Text(
                                          u,
                                          style: const TextStyle(
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (val) {
                              if (val != null) setDlgState(() => buyUnit = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Unit Mismatch Warning
                    Builder(
                      builder: (context) {
                        final isCount = (unit == 'pcs' || unit == 'sachet');
                        final isWeight = (unit == 'gram' || unit == 'kg');
                        final isVolume = (unit == 'ml' || unit == 'liter');

                        final isBuyCount = (buyUnit == 'pcs' || buyUnit == 'sachet');
                        final isBuyWeight = (buyUnit == 'kg' || buyUnit == 'gram');
                        final isBuyVolume = (buyUnit == 'liter' || buyUnit == 'ml');

                        final isMismatch = (isCount && !isBuyCount) ||
                            (isWeight && !isBuyWeight) ||
                            (isVolume && !isBuyVolume);

                        if (!isMismatch) return const SizedBox.shrink();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFD97706)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Satuan resep ($unit) berbeda jenis dengan satuan beli ($buyUnit). Sesuaikan Satuan Beli ke ${isCount ? 'pcs' : (isWeight ? 'kg' : 'liter')} agar HPP akurat.',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    // Live Calculation Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calculate_rounded,
                            size: 20,
                            color: Color(0xFF0F172A),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Subtotal Biaya per Porsi:',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  _currencyFormat.format(liveSubtotal),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
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
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final amount =
                      double.tryParse(
                        amountCtrl.text.replaceAll(RegExp(r'[^\d.]'), ''),
                      ) ??
                      0;
                  final buyPrice =
                      double.tryParse(
                        buyPriceCtrl.text.replaceAll(RegExp(r'[^\d]'), ''),
                      ) ??
                      0;
                  final buyAmount =
                      double.tryParse(
                        buyAmountCtrl.text.replaceAll(RegExp(r'[^\d.]'), ''),
                      ) ??
                      1;

                  if (name.isEmpty || amount <= 0 || buyPrice <= 0) {
                    AppSnackbar.warning(
                      'Data Belum Lengkap',
                      'Lengkapi nama, takaran, dan harga beli bahan.',
                    );
                    return;
                  }

                  final newIng = ProductIngredientModel(
                    id: existing?.id,
                    productId: existing?.productId,
                    ingredientId: ingredientId,
                    name: name,
                    amount: amount,
                    unit: unit,
                    buyPrice: buyPrice,
                    buyAmount: buyAmount,
                    buyUnit: buyUnit,
                    subtotal: liveSubtotal,
                  );

                  setState(() {
                    if (isEditing) {
                      _ingredients[index] = newIng;
                    } else {
                      _ingredients.add(newIng);
                    }
                  });
                  Navigator.of(ctx).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isEditing ? 'Simpan Perubahan' : 'Tambah Bahan',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SAVE / SUBMIT PRODUCT
  // ---------------------------------------------------------------------------
  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final price = _sellingPrice;
    final categoryId = _selectedCategoryId;

    if (name.isEmpty) {
      AppSnackbar.warning('Nama Wajib Diisi', 'Silakan masukkan nama menu.');
      setState(() => _activeSubTab = 0);
      return;
    }
    if (categoryId == null) {
      AppSnackbar.warning(
        'Kategori Wajib Dipilih',
        'Pilih salah satu kategori menu.',
      );
      setState(() => _activeSubTab = 0);
      return;
    }
    if (price <= 0) {
      AppSnackbar.warning(
        'Harga Tidak Valid',
        'Harga jual harus lebih besar dari Rp 0.',
      );
      setState(() => _activeSubTab = 0);
      return;
    }

    final effectiveHppVal = _effectiveHpp;
    final opsCost =
        double.tryParse(
          _operationalCostController.text.replaceAll(RegExp(r'[^\d]'), ''),
        ) ??
        0.0;

    bool success = false;
    if (widget.product != null) {
      success = await controller.updateProduct(
        widget.product!.id,
        name: name,
        categoryId: categoryId,
        price: price,
        sku: _skuController.text.trim(),
        barcode: _barcodeController.text.trim(),
        description: _descriptionController.text.trim(),
        isActive: _isActive,
        hargaBeli: effectiveHppVal,
        operationalCost: opsCost,
        ingredients: _ingredients,
        imageFile: _pickedImage,
      );
    } else {
      success = await controller.storeProduct(
        name: name,
        categoryId: categoryId,
        price: price,
        sku: _skuController.text.trim(),
        barcode: _barcodeController.text.trim(),
        description: _descriptionController.text.trim(),
        isActive: _isActive,
        hargaBeli: effectiveHppVal,
        operationalCost: opsCost,
        ingredients: _ingredients,
        imageFile: _pickedImage,
      );
    }

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }
}
