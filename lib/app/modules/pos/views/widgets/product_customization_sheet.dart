import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/cart_item_model.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../controllers/cart_controller.dart';

class ProductCustomizationSheet extends StatefulWidget {
  final ProductModel product;
  final CartItemModel? existingItem;
  final int? itemIndex;

  const ProductCustomizationSheet({
    super.key,
    required this.product,
    this.existingItem,
    this.itemIndex,
  });

  static void show(
    BuildContext context,
    ProductModel product, {
    CartItemModel? existingItem,
    int? itemIndex,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductCustomizationSheet(
        product: product,
        existingItem: existingItem,
        itemIndex: itemIndex,
      ),
    );
  }

  @override
  State<ProductCustomizationSheet> createState() => _ProductCustomizationSheetState();
}

class _ProductCustomizationSheetState extends State<ProductCustomizationSheet> {
  int _quantity = 1;
  String _sugarLevel = 'Normal';
  String _iceLevel = 'Normal Ice';
  late TextEditingController _notesController;

  final List<String> _sugarOptions = [
    'Normal',
    'Less Sugar (50%)',
    'Slight Sugar (25%)',
    'No Sugar (0%)',
  ];

  final List<String> _iceOptions = [
    'Normal Ice',
    'Less Ice',
    'No Ice',
    'Hot / Hangat',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      _quantity = widget.existingItem!.quantity;
      _sugarLevel = widget.existingItem!.sugarLevel;
      _iceLevel = widget.existingItem!.iceLevel;
      _notesController = TextEditingController(text: widget.existingItem!.notes);
    } else {
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bool isEditMode = widget.existingItem != null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // Header Mode Indicator
            if (isEditMode) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text(
                          'Edit Kustomisasi Menu',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                    tooltip: 'Hapus Item dari Keranjang',
                    onPressed: () {
                      if (widget.itemIndex != null) {
                        Get.find<CartController>().removeItem(widget.itemIndex!);
                        Get.back();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Info Produk & Harga
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(widget.product.price),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Quantity Counter
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: () {
                          if (_quantity > 1) {
                            setState(() => _quantity--);
                          }
                        },
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () {
                          setState(() => _quantity++);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Opsi Level Gula
            const Text(
              'Level Gula (Sugar):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sugarOptions.map((opt) {
                final isSelected = _sugarLevel == opt;
                return ChoiceChip(
                  label: Text(opt),
                  selected: isSelected,
                  selectedColor: AppColors.primarySoft,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.lightBorder,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _sugarLevel = opt);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Opsi Level Es
            const Text(
              'Level Es (Ice):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _iceOptions.map((opt) {
                final isSelected = _iceLevel == opt;
                return ChoiceChip(
                  label: Text(opt),
                  selected: isSelected,
                  selectedColor: AppColors.primarySoft,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.lightBorder,
                  ),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _iceLevel = opt);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Catatan Khusus
            const Text(
              'Catatan Tambahan (Opsional):',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Misal: Bungkus terpisah, saus jangan dicampur...',
                prefixIcon: Icon(Icons.edit_note_rounded, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Simpan / Tambah
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final cartController = Get.find<CartController>();
                  if (isEditMode && widget.itemIndex != null) {
                    // Update item existing
                    final updatedItem = widget.existingItem!.copyWith(
                      quantity: _quantity,
                      sugarLevel: _sugarLevel,
                      iceLevel: _iceLevel,
                      notes: _notesController.text.trim(),
                    );
                    cartController.updateItem(widget.itemIndex!, updatedItem);
                  } else {
                    // Tambah baru
                    cartController.addItem(
                      widget.product,
                      quantity: _quantity,
                      sugarLevel: _sugarLevel,
                      iceLevel: _iceLevel,
                      notes: _notesController.text.trim(),
                    );
                  }
                  Get.back();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditMode ? 'Simpan Perubahan' : 'Tambahkan ke Pesanan',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      CurrencyFormatter.format(widget.product.price * _quantity),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
