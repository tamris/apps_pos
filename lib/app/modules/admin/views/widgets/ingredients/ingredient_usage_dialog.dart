import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/app_snackbar.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/data/models/admin_ingredient_model.dart';
import 'package:noli_apps/app/data/models/admin_product_model.dart';
import 'package:noli_apps/app/data/models/product_ingredient_model.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

class AdminIngredientUsageDialog extends StatelessWidget {
  final AdminIngredientModel ingredient;

  const AdminIngredientUsageDialog({
    super.key,
    required this.ingredient,
  });

  static Future<void> show(BuildContext context, {required AdminIngredientModel ingredient}) {
    return showDialog<void>(
      context: context,
      builder: (context) => AdminIngredientUsageDialog(ingredient: ingredient),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AdminController>();

    return Obx(() {
      // Find the fresh ingredient data from controller
      final currentIng = controller.ingredients.firstWhereOrNull((i) => i.id == ingredient.id) ?? ingredient;
      final usages = currentIng.usedInProducts;

      return Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540, maxHeight: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.restaurant_menu_rounded,
                        color: Color(0xFF4F46E5),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentIng.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Digunakan di ${usages.length} Racikan Resep Menu',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: const Color(0xFF64748B),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ),

              // 2. Action Bar: "+ Tautkan ke Menu Baru"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: const Color(0xFFF8FAFC),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daftar Resep Terkait:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => AdminAttachIngredientDialog.show(context, ingredient: currentIng),
                      icon: const Icon(Icons.add_link_rounded, size: 16),
                      label: const Text(
                        'Tautkan ke Menu',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // 3. Content List
              Flexible(
                child: usages.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.link_off_rounded,
                                color: Color(0xFF94A3B8),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Belum Terhubung ke Resep Menu',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Bahan baku ini belum ditambahkan ke racikan menu apa pun.\nKlik tombol "Tautkan ke Menu" di atas untuk menambahkan.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: usages.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = usages[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: const Icon(
                                    Icons.coffee_rounded,
                                    size: 18,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item.categoryName,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(color: const Color(0xFFC7D2FE)),
                                      ),
                                      child: Text(
                                        '${item.amount % 1 == 0 ? item.amount.toInt() : item.amount} ${item.unit} / porsi',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF4F46E5),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Modal: ${CurrencyFormatter.format(item.subtotal)}',
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                // Tombol Hapus Tautan
                                IconButton(
                                  icon: const Icon(Icons.link_off_rounded, size: 18, color: Color(0xFFEF4444)),
                                  tooltip: 'Hapus dari resep ${item.productName}',
                                  splashRadius: 18,
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
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // 4. Footer Info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Stok Gudang: ${currentIng.formattedStock} ${currentIng.unit}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// -----------------------------------------------------------------------------
// DIALOG FORM TAUTKAN BAHAN BAKU KE RESEP MENU
// -----------------------------------------------------------------------------
class AdminAttachIngredientDialog extends StatefulWidget {
  final AdminIngredientModel ingredient;

  const AdminAttachIngredientDialog({super.key, required this.ingredient});

  static Future<bool?> show(BuildContext context, {required AdminIngredientModel ingredient}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminAttachIngredientDialog(ingredient: ingredient),
    );
  }

  @override
  State<AdminAttachIngredientDialog> createState() => _AdminAttachIngredientDialogState();
}

class _AdminAttachIngredientDialogState extends State<AdminAttachIngredientDialog> {
  final AdminController controller = Get.find<AdminController>();
  final _amountCtrl = TextEditingController(text: '15');
  int? _selectedProductId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final unit = widget.ingredient.unit.toLowerCase();
    final defaultAmount = (unit == 'pcs' || unit == 'sachet')
        ? '1'
        : (unit == 'ml' ? '30' : '15');
    _amountCtrl.text = defaultAmount;

    // Filter out products already linked to this ingredient
    final linkedIds = widget.ingredient.usedInProducts.map((u) => u.productId).toSet();
    final available = controller.products.where((p) => !linkedIds.contains(p.id)).toList();
    if (available.isNotEmpty) {
      _selectedProductId = available.first.id;
    } else {
      _selectedProductId = null;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _openSearchProductPickerModal(
    BuildContext context,
    List<AdminProductModel> availableProducts,
  ) async {
    String query = '';
    await showDialog(
      context: context,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = availableProducts.where((p) {
              if (query.trim().isEmpty) return true;
              final q = query.trim().toLowerCase();
              return p.name.toLowerCase().contains(q) ||
                  p.categoryName.toLowerCase().contains(q);
            }).toList();

            return AlertDialog(
              backgroundColor: Colors.white,
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
                      Icons.local_cafe_rounded,
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
                          'Pilih Menu Produk',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Pilih menu yang belum ditautkan dengan bahan ini',
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
                width: 440,
                height: 380,
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
                        hintText: 'Ketik nama menu produk...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF64748B)),
                        suffixIcon: query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () => setModalState(() => query = ''),
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
                    Expanded(
                      child: filtered.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.search_off_rounded,
                                    size: 36,
                                    color: Color(0xFFCBD5E1),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    query.isEmpty
                                        ? 'Tidak ada menu tersedia'
                                        : 'Menu "$query" tidak ditemukan',
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
                                final isSelected = item.id == _selectedProductId;
                                return InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedProductId = item.id;
                                    });
                                    Navigator.of(modalCtx).pop();
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
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
                                                  fontSize: 13,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w600,
                                                  color: isSelected
                                                      ? const Color(0xFF4F46E5)
                                                      : const Color(0xFF1E293B),
                                                ),
                                              ),
                                              if (item.categoryName.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  item.categoryName,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.format(item.price),
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFF4F46E5)
                                                : const Color(0xFF0F172A),
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

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient;
    final amt = double.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    final subtotal = ProductIngredientModel.calculateLocalSubtotal(
      amt,
      ing.unit,
      ing.buyPrice,
      ing.buyAmount,
      ing.buyUnit,
    );

    // Filter out products that are already linked to this ingredient
    final linkedIds = ing.usedInProducts.map((u) => u.productId).toSet();
    final availableProducts = controller.products.where((p) => !linkedIds.contains(p.id)).toList();
    final selectedProduct = _selectedProductId != null
        ? availableProducts.firstWhereOrNull((p) => p.id == _selectedProductId)
        : null;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.add_link_rounded, color: Color(0xFF4F46E5), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tautkan ${ing.name}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner Bahan Baku
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Harga Modal: ${CurrencyFormatter.format(ing.buyPrice)} / ${ing.buyAmount % 1 == 0 ? ing.buyAmount.toInt() : ing.buyAmount} ${ing.buyUnit}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Satuan: ${ing.unit}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Pilih Menu / Produk
              const Text(
                'Pilih Menu Produk *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              if (availableProducts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Semua menu produk saat ini sudah ditautkan dengan bahan baku ini.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: () {
                    _openSearchProductPickerModal(context, availableProducts);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedProduct != null
                            ? const Color(0xFF818CF8)
                            : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          selectedProduct != null
                              ? Icons.local_cafe_rounded
                              : Icons.search_rounded,
                          size: 16,
                          color: selectedProduct != null
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: selectedProduct != null
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        selectedProduct.name,
                                        style: const TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF0F172A),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      CurrencyFormatter.format(selectedProduct.price),
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  '-- Pilih / Cari Menu Produk --',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 20,
                          color: Color(0xFF64748B),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),

              // Takaran per Porsi
              Text(
                'Takaran per Porsi (${ing.unit}) *',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Contoh: 15',
                  suffixText: ing.unit,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),

              // Live Cost Calculation Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calculate_rounded, size: 20, color: Color(0xFF0F172A)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Kontribusi Modal HPP per Porsi:',
                            style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                          ),
                          Text(
                            CurrencyFormatter.format(subtotal),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
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
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: (_isLoading || availableProducts.isEmpty)
              ? null
              : () async {
                  if (_selectedProductId == null || amt <= 0) {
                    AppSnackbar.warning('Data Belum Lengkap', 'Pilih menu dan masukkan takaran yang valid.');
                    return;
                  }

                  final nav = Navigator.of(context);
                  setState(() => _isLoading = true);
                  final success = await controller.attachIngredientToProduct(
                    ingredientId: ing.id,
                    productId: _selectedProductId!,
                    amount: amt,
                    unit: ing.unit,
                  );
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }

                  if (success) {
                    nav.pop(true);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F46E5),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isLoading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Tautkan Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
