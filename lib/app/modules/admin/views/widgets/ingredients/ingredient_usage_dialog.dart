import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/app_snackbar.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/data/models/admin_ingredient_model.dart';
import 'package:noli_apps/app/data/models/admin_product_model.dart';
import 'package:noli_apps/app/data/models/product_ingredient_model.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

enum _IngredientDialogStep {
  usages, // Halaman 1: Daftar Resep Terkait & Yield Estimator
  attachForm, // Halaman 2: Form Tautkan / Ubah Takaran Menu
  searchProduct, // Halaman 3: Pencarian Menu dengan Category Filter Chips
}

/// Dialog manajemen keterkaitan bahan baku dengan resep menu produk.
/// Menggunakan konsep Single Dialog Navigation (0 overlay bertumpuk, bersih, rapi, dan terstruktur).
/// Fitur Pro:
/// - Category Filter Chips pada pencarian menu
/// - Quick Portion Presets (chip takaran cepat adaptif)
/// - Yield Estimator (estimasi sisa porsi dari stok gudang)
/// - Quick Edit Takaran (langsung edit gramasi tanpa hapus-tautkan)
class AdminIngredientUsageDialog extends StatefulWidget {
  final AdminIngredientModel ingredient;
  final bool initialAddMode;

  const AdminIngredientUsageDialog({
    super.key,
    required this.ingredient,
    this.initialAddMode = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    required AdminIngredientModel ingredient,
    bool initialAddMode = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AdminIngredientUsageDialog(
        ingredient: ingredient,
        initialAddMode: initialAddMode,
      ),
    );
  }

  @override
  State<AdminIngredientUsageDialog> createState() => _AdminIngredientUsageDialogState();
}

class _AdminIngredientUsageDialogState extends State<AdminIngredientUsageDialog> {
  final AdminController controller = Get.find<AdminController>();

  late _IngredientDialogStep _currentStep;
  final _amountCtrl = TextEditingController(text: '15');
  final _searchProductCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  final Set<int> _selectedProductIds = <int>{};
  int? _selectedProductId;
  String? _editingProductName;
  bool _isEditingExisting = false;

  String _productSearchQuery = '';
  String _selectedCategoryFilter = 'Semua';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialAddMode ? _IngredientDialogStep.attachForm : _IngredientDialogStep.usages;

    _resetDefaultAmount();
    _initDefaultProduct();
  }

  void _resetDefaultAmount() {
    final unit = widget.ingredient.unit.toLowerCase();
    final defaultAmount = (unit == 'pcs' || unit == 'sachet')
        ? '1'
        : (unit == 'ml' ? '30' : '15');
    _amountCtrl.text = defaultAmount;
  }

  void _initDefaultProduct() {
    _isEditingExisting = false;
    _editingProductName = null;
    _selectedProductIds.clear();
    _selectedProductId = null;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _searchProductCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<double> _getQuickAmounts(String unit) {
    final u = unit.toLowerCase().trim();
    if (u == 'gram' || u == 'g' || u == 'gr') {
      return [10, 15, 18, 20, 25, 30];
    } else if (u == 'ml') {
      return [10, 15, 20, 30, 45, 60];
    } else if (u == 'pcs' || u == 'sachet' || u == 'butir' || u == 'lembar') {
      return [1, 2, 3, 4, 5];
    }
    return [1, 5, 10, 20, 50];
  }

  String _formatUnitShort(String unit) {
    final u = unit.toLowerCase().trim();
    if (u == 'gram' || u == 'g' || u == 'gr') return 'g';
    if (u == 'mililiter' || u == 'ml') return 'ml';
    if (u == 'kilogram' || u == 'kg') return 'kg';
    if (u == 'pcs' || u == 'buah' || u == 'butir' || u == 'lembar' || u == 'sachet') return '';
    return u;
  }

  void _handleBack() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_currentStep == _IngredientDialogStep.searchProduct) {
      setState(() => _currentStep = _IngredientDialogStep.attachForm);
    } else if (_currentStep == _IngredientDialogStep.attachForm) {
      if (widget.initialAddMode) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _isEditingExisting = false;
          _editingProductName = null;
          _selectedProductIds.clear();
          _selectedProductId = null;
          _currentStep = _IngredientDialogStep.usages;
        });
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  void _startEditUsage(dynamic item) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _isEditingExisting = true;
      _selectedProductId = item.productId;
      _selectedProductIds.clear();
      _selectedProductIds.add(item.productId);
      _editingProductName = item.productName;
      _amountCtrl.text = item.amount % 1 == 0 ? item.amount.toInt().toString() : item.amount.toString();
      _currentStep = _IngredientDialogStep.attachForm;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == _IngredientDialogStep.usages || (widget.initialAddMode && _currentStep == _IngredientDialogStep.attachForm),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack();
        }
      },
      child: Obx(() {
        final currentIng = controller.ingredients.firstWhereOrNull((i) => i.id == widget.ingredient.id) ?? widget.ingredient;
        final usages = currentIng.usedInProducts;

        // Filter produk yang belum ditautkan (kecuali saat mengedit menu saat ini)
        final linkedIds = usages.map((u) => u.productId).toSet();
        final availableProducts = controller.products.where((p) {
          if (_isEditingExisting && p.id == _selectedProductId) return true;
          return !linkedIds.contains(p.id);
        }).toList();

        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540, maxHeight: 670),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: _buildCurrentStepView(currentIng, usages, availableProducts),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStepView(
    AdminIngredientModel currentIng,
    List<dynamic> usages,
    List<AdminProductModel> availableProducts,
  ) {
    switch (_currentStep) {
      case _IngredientDialogStep.usages:
        return _buildUsagesView(currentIng, usages);
      case _IngredientDialogStep.attachForm:
        return _buildAttachFormView(currentIng, availableProducts);
      case _IngredientDialogStep.searchProduct:
        return _buildSearchProductView(availableProducts);
    }
  }

  // ===========================================================================
  // HALAMAN 1: DAFTAR RESEP TERKAIT & YIELD ESTIMATOR
  // ===========================================================================
  // ===========================================================================
  // HALAMAN 1: DAFTAR RESEP TERKAIT (CLEAN, SPACIOUS & ORGANIZED)
  // ===========================================================================
  Widget _buildUsagesView(AdminIngredientModel currentIng, List<dynamic> usages) {
    return KeyedSubtree(
      key: const ValueKey('step_usages'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Bersih, Elegan & Terintegrasi
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    color: Color(0xFF4F46E5),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              currentIng.name,
                              style: const TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                              currentIng.category,
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${usages.length} menu terhubung • Stok: ${currentIng.formattedStock} ${currentIng.unit}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!currentIng.isArchived) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _resetDefaultAmount();
                        _initDefaultProduct();
                        _currentStep = _IngredientDialogStep.attachForm;
                      });
                    },
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text(
                      'Tautkan Menu',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: const Color(0xFF94A3B8),
                  splashRadius: 18,
                ),
              ],
            ),
          ),

          // 2. Daftar Resep Menu Terhubung
          Flexible(
            child: usages.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 52),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: const Icon(Icons.link_off_rounded, color: Color(0xFF94A3B8), size: 28),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Belum Terhubung ke Resep Menu',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'Bahan baku ini belum ditautkan ke racikan menu produk apa pun.\nKlik tombol di bawah untuk mulai menambahkan racikan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.45),
                        ),
                        if (!currentIng.isArchived) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _resetDefaultAmount();
                                _initDefaultProduct();
                                _currentStep = _IngredientDialogStep.attachForm;
                              });
                            },
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Tautkan ke Menu Sekarang', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: usages.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = usages[index];
                      final portions = (item.amount > 0 && currentIng.stock > 0)
                          ? (currentIng.stock / item.amount).floor()
                          : 0;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.local_cafe_outlined, size: 19, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          item.productName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF2FF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${item.amount % 1 == 0 ? item.amount.toInt() : item.amount} ${item.unit}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF4F46E5),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(text: '${item.categoryName} • Modal: ${CurrencyFormatter.format(item.subtotal)}'),
                                        if (portions > 0) ...[
                                          const TextSpan(text: ' • '),
                                          TextSpan(
                                            text: '±$portions porsi',
                                            style: const TextStyle(
                                              color: Color(0xFF059669),
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (!currentIng.isArchived) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE0E7FF)),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF4F46E5)),
                                  tooltip: 'Ubah takaran ${item.productName}',
                                  splashRadius: 16,
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _startEditUsage(item),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFEE2E2)),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.link_off_rounded, size: 16, color: Color(0xFFEF4444)),
                                  tooltip: 'Hapus dari resep ${item.productName}',
                                  splashRadius: 16,
                                  padding: EdgeInsets.zero,
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        backgroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        title: const Text('Hapus dari Resep', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                        content: Text(
                                          "Apakah Anda yakin ingin menghapus '${currentIng.name}' dari resep menu '${item.productName}'?",
                                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(ctx).pop(false),
                                            child: const Text('Batal'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppColors.danger,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                            ),
                                            onPressed: () => Navigator.of(ctx).pop(true),
                                            child: const Text('Hapus'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await controller.detachIngredientFromProduct(
                                        ingredientId: currentIng.id,
                                        productId: item.productId,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 3. Footer Bersih (Stok & Aksi)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFF475569)),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Stok Gudang: ${currentIng.formattedStock} ${currentIng.unit}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!currentIng.isArchived && usages.length > 1) ...[
                  TextButton.icon(
                    onPressed: () => _confirmDetachAll(context, controller, currentIng, usages),
                    icon: const Icon(Icons.link_off_rounded, size: 15, color: Color(0xFFEF4444)),
                    label: Text(
                      'Putuskan Semua (${usages.length})',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text(
                    'Tutup',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HALAMAN 2: FORM TAUTKAN / EDIT TAKARAN (ORGANIZED & PROFESSIONAL)
  // ===========================================================================
  Widget _buildAttachFormView(
    AdminIngredientModel currentIng,
    List<AdminProductModel> availableProducts,
  ) {
    final amt = double.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    final subtotal = ProductIngredientModel.calculateLocalSubtotal(
      amt,
      currentIng.unit,
      currentIng.buyPrice,
      currentIng.buyAmount,
      currentIng.buyUnit,
    );

    // Estimasi porsi tersisa
    final estimatedPortions = (amt > 0 && currentIng.stock > 0)
        ? (currentIng.stock / amt).floor()
        : 0;

    final selectedProduct = _selectedProductId != null
        ? controller.products.firstWhereOrNull((p) => p.id == _selectedProductId)
        : null;

    final selectedProducts = controller.products.where((p) => _selectedProductIds.contains(p.id)).toList();

    return KeyedSubtree(
      key: const ValueKey('step_attach_form'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bersih & Terpadu
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _handleBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  color: const Color(0xFF475569),
                  tooltip: 'Kembali',
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditingExisting
                            ? 'Ubah Takaran: ${_editingProductName ?? selectedProduct?.name ?? currentIng.name}'
                            : 'Tautkan ${currentIng.name}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Harga beli: ${CurrencyFormatter.format(currentIng.buyPrice)} / ${currentIng.buyAmount % 1 == 0 ? currentIng.buyAmount.toInt() : currentIng.buyAmount} ${currentIng.buyUnit}',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: const Color(0xFF94A3B8),
                  splashRadius: 18,
                ),
              ],
            ),
          ),

          // Body Form Terstruktur
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Selector Menu Produk
                  const Text(
                    'MENU PRODUK',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  if (availableProducts.isEmpty && !_isEditingExisting)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Semua menu saat ini sudah ditautkan dengan bahan baku ini.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    InkWell(
                      onTap: _isEditingExisting
                          ? null
                          : () {
                              FocusManager.instance.primaryFocus?.unfocus();
                              setState(() {
                                _productSearchQuery = '';
                                _searchProductCtrl.clear();
                                _selectedCategoryFilter = 'Semua';
                                _currentStep = _IngredientDialogStep.searchProduct;
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _searchFocusNode.unfocus();
                                FocusManager.instance.primaryFocus?.unfocus();
                              });
                            },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_isEditingExisting ? selectedProduct != null : _selectedProductIds.isNotEmpty)
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFFCBD5E1),
                            width: (_isEditingExisting ? selectedProduct != null : _selectedProductIds.isNotEmpty) ? 1.5 : 1,
                          ),
                        ),
                        child: _isEditingExisting
                            ? Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _editingProductName ?? selectedProduct?.name ?? 'Menu Produk',
                                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (selectedProduct != null)
                                          Text(
                                            '${selectedProduct.categoryName} • ${CurrencyFormatter.format(selectedProduct.price)}',
                                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : (_selectedProductIds.isEmpty
                                ? Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.playlist_add_rounded, size: 20, color: Color(0xFF4F46E5)),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Pilih Menu Produk (Bisa Multi-Menu)',
                                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                            ),
                                            Text(
                                              'Ketuk di sini untuk memilih dari katalog toko',
                                              style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEEF2FF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Pilih Menu →',
                                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                                        ),
                                      ),
                                    ],
                                  )
                                : (_selectedProductIds.length == 1
                                    ? Row(
                                        children: [
                                          Container(
                                            width: 38,
                                            height: 38,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEEF2FF),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: const Icon(Icons.local_cafe_rounded, size: 19, color: Color(0xFF4F46E5)),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  selectedProducts.isNotEmpty ? selectedProducts.first.name : '1 Menu Terpilih',
                                                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (selectedProducts.isNotEmpty)
                                                  Text(
                                                    '${selectedProducts.first.categoryName} • ${CurrencyFormatter.format(selectedProducts.first.price)}',
                                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Text('Ganti', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 24,
                                                      height: 24,
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEEF2FF),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: const Icon(Icons.done_all_rounded, size: 15, color: Color(0xFF4F46E5)),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Flexible(
                                                      child: Text(
                                                        '${selectedProducts.length} Menu Produk Dipilih',
                                                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEEF2FF),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Kelola (${selectedProducts.length}) →',
                                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            selectedProducts.map((p) => p.name).join(', '),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ))),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // 2. Takaran per Porsi Input
                  Text(
                    'TAKARAN PER PORSI (${currentIng.unit.toUpperCase()})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B), letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: false,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Contoh: 15',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      suffixText: currentIng.unit,
                      suffixStyle: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                    ),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 10),

                  // Quick Portion Chips (Single-Row Horizontal Segmented Carousel)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Preset',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: _getQuickAmounts(currentIng.unit).map((val) {
                              final strVal = val % 1 == 0 ? val.toInt().toString() : val.toString();
                              final isSelected = _amountCtrl.text == strVal;
                              final unitShort = _formatUnitShort(currentIng.unit);
                              final label = unitShort.isNotEmpty ? '$strVal$unitShort' : strVal;

                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: InkWell(
                                  onTap: () => setState(() => _amountCtrl.text = strVal),
                                  borderRadius: BorderRadius.circular(20),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                        color: isSelected ? Colors.white : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. Executive Dual-Stat KPI Box (Clean & Clear)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Stat 1: Modal HPP
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Biaya Modal / Porsi',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    CurrencyFormatter.format(subtotal),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Dihitung dari modal beli',
                                    style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 38, color: const Color(0xFFCBD5E1)),
                            const SizedBox(width: 16),
                            // Stat 2: Estimasi Porsi
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Estimasi Sisa Porsi',
                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    (amt > 0 && currentIng.stock > 0)
                                        ? '±$estimatedPortions porsi'
                                        : (currentIng.stock <= 0 ? 'Stok Habis' : '-'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: (amt > 0 && currentIng.stock > 0)
                                          ? const Color(0xFF059669)
                                          : (currentIng.stock <= 0 ? const Color(0xFFEF4444) : const Color(0xFF64748B)),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Dari stok ${currentIng.formattedStock} ${currentIng.unit}',
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!_isEditingExisting && _selectedProductIds.length > 1) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF4F46E5)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Takaran ini akan diterapkan serentak ke ${_selectedProductIds.length} menu terpilih.',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF4338CA), fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons Form
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isLoading ? null : _handleBack,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text('Batal', style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: (_isLoading || (!_isEditingExisting && _selectedProductIds.isEmpty && availableProducts.isEmpty))
                      ? null
                      : () async {
                          if (!_isEditingExisting && _selectedProductIds.isEmpty) {
                            AppSnackbar.warning('Pilih Menu', 'Silakan pilih minimal satu menu produk.');
                            return;
                          }
                          if (_isEditingExisting && _selectedProductId == null) {
                            AppSnackbar.warning('Data Belum Lengkap', 'Menu produk tidak valid.');
                            return;
                          }
                          if (amt <= 0) {
                            AppSnackbar.warning('Takaran Tidak Valid', 'Masukkan takaran per porsi yang lebih dari 0.');
                            return;
                          }

                          setState(() => _isLoading = true);

                          if (_isEditingExisting) {
                            final success = await controller.attachIngredientToProduct(
                              ingredientId: currentIng.id,
                              productId: _selectedProductId!,
                              amount: amt,
                              unit: currentIng.unit,
                            );

                            if (mounted) {
                              setState(() => _isLoading = false);
                              if (success) {
                                _isEditingExisting = false;
                                _editingProductName = null;
                                _selectedProductIds.clear();
                                if (widget.initialAddMode) {
                                  Navigator.of(context).pop(true);
                                } else {
                                  setState(() {
                                    _currentStep = _IngredientDialogStep.usages;
                                  });
                                }
                              }
                            }
                          } else {
                            final productIds = _selectedProductIds.toList();
                            final count = await controller.attachIngredientToMultipleProducts(
                              ingredientId: currentIng.id,
                              productIds: productIds,
                              amount: amt,
                              unit: currentIng.unit,
                            );

                            if (mounted) {
                              setState(() => _isLoading = false);
                              if (count > 0) {
                                _selectedProductIds.clear();
                                if (widget.initialAddMode) {
                                  Navigator.of(context).pop(true);
                                } else {
                                  setState(() {
                                    _currentStep = _IngredientDialogStep.usages;
                                  });
                                }
                              }
                            }
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(
                          _isEditingExisting
                              ? 'Simpan Perubahan'
                              : (_selectedProductIds.length > 1
                                  ? 'Tautkan ke ${_selectedProductIds.length} Menu Sekaligus'
                                  : (_selectedProductIds.length == 1
                                      ? 'Tautkan ke 1 Menu'
                                      : 'Pilih Menu')),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HALAMAN 3: PENCARIAN & MULTI-SELECT MENU (CLEAN & INTUITIVE)
  // ===========================================================================
  Widget _buildSearchProductView(List<AdminProductModel> availableProducts) {
    final query = _productSearchQuery.trim().toLowerCase();

    // Kumpulkan daftar kategori unik dan pastikan kategori Espresso selalu di sebelah 'Semua'
    final uniqueCategories = availableProducts
        .map((p) => p.categoryName.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList();

    uniqueCategories.sort((a, b) {
      final aLower = a.toLowerCase();
      final bLower = b.toLowerCase();
      final aIsEspresso = aLower.contains('espresso');
      final bIsEspresso = bLower.contains('espresso');
      if (aIsEspresso && !bIsEspresso) return -1;
      if (!aIsEspresso && bIsEspresso) return 1;

      final aIsCoffee = aLower.contains('coffee') || aLower.contains('kopi');
      final bIsCoffee = bLower.contains('coffee') || bLower.contains('kopi');
      if (aIsCoffee && !bIsCoffee) return -1;
      if (!aIsCoffee && bIsCoffee) return 1;

      return a.compareTo(b);
    });

    final categories = ['Semua', ...uniqueCategories];

    final filtered = availableProducts.where((p) {
      final matchesCategory = _selectedCategoryFilter == 'Semua' || p.categoryName == _selectedCategoryFilter;
      if (!matchesCategory) return false;
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) || p.categoryName.toLowerCase().contains(query);
    }).toList();

    final filteredIds = filtered.map((p) => p.id).toSet();
    final bool isAllFilteredSelected = filtered.isNotEmpty && filteredIds.every((id) => _selectedProductIds.contains(id));

    return KeyedSubtree(
      key: const ValueKey('step_search_product'),
      child: FocusScope(
        autofocus: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bersih
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => setState(() => _currentStep = _IngredientDialogStep.attachForm),
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    color: const Color(0xFF475569),
                    tooltip: 'Kembali ke Formulir',
                    splashRadius: 18,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Menu Produk',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A), letterSpacing: -0.2),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Centang menu yang menggunakan racikan bahan ini',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                    color: const Color(0xFF94A3B8),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),

            // Input Pencarian
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
              child: TextField(
                controller: _searchProductCtrl,
                focusNode: _searchFocusNode,
                autofocus: false,
                onChanged: (val) => setState(() => _productSearchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Cari nama menu produk...',
                  hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                  suffixIcon: _productSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 16),
                          onPressed: () {
                            _searchProductCtrl.clear();
                            setState(() => _productSearchQuery = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: const Color(0xFFF1F5F9),
                ),
                style: const TextStyle(fontSize: 13.5),
              ),
            ),

            // Category Filter Chips (Outlined Style - Bersih & Rapi)
            if (categories.length > 1)
              Container(
                height: 34,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final cat = categories[idx];
                    final isSelected = _selectedCategoryFilter == cat;
                    return InkWell(
                      onTap: () => setState(() => _selectedCategoryFilter = cat),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Clean Minimal Action Row (Status & Pilih Semua)
            if (filtered.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: '${filtered.length} menu tersedia',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          children: [
                            if (_selectedProductIds.isNotEmpty) ...[
                              const TextSpan(text: ' • '),
                              TextSpan(
                                text: '${_selectedProductIds.length} dipilih',
                                style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700),
                              ),
                            ],
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isAllFilteredSelected) {
                            _selectedProductIds.removeAll(filteredIds);
                          } else {
                            _selectedProductIds.addAll(filteredIds);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        child: Text(
                          isAllFilteredSelected ? 'Batalkan Filter Ini' : 'Pilih Semua (${filtered.length})',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // List Produk
            Flexible(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFFCBD5E1)),
                            const SizedBox(height: 8),
                            Text(
                              _productSearchQuery.isEmpty
                                  ? 'Tidak ada menu di kategori ini'
                                  : 'Menu "$_productSearchQuery" tidak ditemukan',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (ctx, i) {
                        final item = filtered[i];
                        final isSelected = _selectedProductIds.contains(item.id);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selectedProductIds.remove(item.id);
                              } else {
                                _selectedProductIds.add(item.id);
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF5F7FF) : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFC7D2FE) : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Checkbox Modern
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF4F46E5) : Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFCBD5E1),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                          color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      if (item.categoryName.isNotEmpty) ...[
                                        const SizedBox(height: 1),
                                        Text(
                                          item.categoryName,
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  CurrencyFormatter.format(item.price),
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Bottom Confirmation Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedProductIds.isEmpty
                              ? 'Belum ada menu dipilih'
                              : '${_selectedProductIds.length} Menu Terpilih',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: _selectedProductIds.isEmpty
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF4F46E5),
                          ),
                        ),
                        if (_selectedProductIds.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Takaran: ${_amountCtrl.text} ${widget.ingredient.unit} / porsi',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _selectedProductIds.isEmpty
                        ? null
                        : () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            setState(() => _currentStep = _IngredientDialogStep.attachForm);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      _selectedProductIds.isEmpty
                          ? 'Pilih Menu'
                          : 'Gunakan (${_selectedProductIds.length}) Menu',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // MASS DETACH CONFIRMATION DIALOG
  // ===========================================================================
  Future<void> _confirmDetachAll(
    BuildContext context,
    AdminController controller,
    AdminIngredientModel currentIng,
    List<dynamic> usages,
  ) async {
    final menuNames = usages.map((u) => u.productName).take(4).join(', ');
    final extraCount = usages.length > 4 ? ' dan ${usages.length - 4} menu lainnya' : '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Putuskan Semua Menu?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                children: [
                  const TextSpan(text: 'Anda akan memutuskan kaitan bahan baku '),
                  TextSpan(
                    text: "'${currentIng.name}'",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  TextSpan(
                    text: " dari seluruh ${usages.length} menu ($menuNames$extraCount).",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Menu tidak akan terhapus dari katalog toko. Namun penjualan menu tersebut tidak akan lagi memotong stok bahan ini dan HPP akan disesuaikan.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Ya, Putuskan Semua (${usages.length})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await controller.detachIngredientFromAllProducts(
        ingredientId: currentIng.id,
      );
    }
  }
}

/// Helper kompatibilitas untuk pemanggilan langsung tautkan dari menu kartu.
class AdminAttachIngredientDialog {
  static Future<bool?> show(
    BuildContext context, {
    required AdminIngredientModel ingredient,
  }) {
    if (ingredient.isArchived) {
      AppSnackbar.warning(
        'Bahan Terarsip',
        'Bahan baku ini sedang diarsip dan tidak dapat ditautkan ke resep menu. Pulihkan bahan terlebih dahulu.',
      );
      return Future.value(false);
    }
    return AdminIngredientUsageDialog.show(
      context,
      ingredient: ingredient,
      initialAddMode: true,
    );
  }
}
