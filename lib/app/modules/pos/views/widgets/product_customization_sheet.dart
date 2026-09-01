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
    showDialog(
      context: context,
      barrierDismissible: true,
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
  String _spicyLevel = ''; // Single select: 'Tidak Pedas', 'Sedang', 'Pedas'
  final Set<String> _selectedFoodRequests = <String>{}; // Multi select: 'Pisah Saus', 'Tanpa Bawang', 'Bungkus Terpisah'
  late TextEditingController _notesController;

  final List<String> _sugarOptions = [
    'Normal',
    'Less Sugar',
    'No Sugar',
  ];

  final List<String> _iceOptions = [
    'Normal Ice',
    'Less Ice',
    'No Ice',
    'Hot / Hangat',
  ];

  final List<String> _spicyOptions = [
    'Tidak Pedas',
    'Sedang',
    'Pedas',
  ];

  final List<String> _foodSpecialRequests = [
    'Pisah Saus',
    'Tanpa Bawang',
    'Bungkus Terpisah',
  ];

  bool get _isDrink {
    final cat = widget.product.categoryName.toLowerCase();
    final name = widget.product.name.toLowerCase();
    return cat.contains('coffee') ||
        cat.contains('kopi') ||
        cat.contains('tea') ||
        cat.contains('teh') ||
        cat.contains('drink') ||
        cat.contains('beverage') ||
        cat.contains('minuman') ||
        cat.contains('espresso') ||
        name.contains('latte') ||
        name.contains('coffee') ||
        name.contains('tea') ||
        name.contains('matcha') ||
        name.contains('americano');
  }

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      _quantity = widget.existingItem!.quantity;
      _sugarLevel = widget.existingItem!.sugarLevel.isNotEmpty ? widget.existingItem!.sugarLevel : 'Normal';
      _iceLevel = widget.existingItem!.iceLevel.isNotEmpty ? widget.existingItem!.iceLevel : 'Normal Ice';

      final existingNotes = widget.existingItem!.notes;
      String remainingNotes = existingNotes;

      // Extract existing spicy level if any
      for (final sp in _spicyOptions) {
        if (existingNotes.contains(sp)) {
          _spicyLevel = sp;
          remainingNotes = remainingNotes.replaceAll(sp, '');
        }
      }

      // Extract existing special requests if any
      for (final req in _foodSpecialRequests) {
        if (existingNotes.contains(req)) {
          _selectedFoodRequests.add(req);
          remainingNotes = remainingNotes.replaceAll(req, '');
        }
      }

      // Clean remaining custom notes
      remainingNotes = remainingNotes.replaceAll(RegExp(r',\s*,?'), ',').trim();
      if (remainingNotes.startsWith(',')) remainingNotes = remainingNotes.substring(1).trim();
      if (remainingNotes.endsWith(',')) remainingNotes = remainingNotes.substring(0, remainingNotes.length - 1).trim();

      _notesController = TextEditingController(text: remainingNotes);
    } else {
      _notesController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String _compileFinalNotes() {
    final List<String> parts = [];
    if (!_isDrink && _spicyLevel.isNotEmpty) {
      parts.add(_spicyLevel);
    }
    if (!_isDrink && _selectedFoodRequests.isNotEmpty) {
      parts.addAll(_selectedFoodRequests);
    }
    final custom = _notesController.text.trim();
    if (custom.isNotEmpty) {
      parts.add(custom);
    }
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditMode = widget.existingItem != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Bar (Mode Indicator & Close / Delete Button)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isEditMode ? AppColors.primarySoft : AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isEditMode ? Icons.edit_rounded : Icons.tune_rounded,
                            size: 14,
                            color: isEditMode ? AppColors.primaryDark : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isEditMode ? 'Edit Kustomisasi Menu' : 'Kustomisasi Menu',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isEditMode ? AppColors.primaryDark : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (isEditMode) ...[
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                            tooltip: 'Hapus Item dari Keranjang',
                            onPressed: () {
                              if (widget.itemIndex != null) {
                                Get.find<CartController>().removeItem(widget.itemIndex!);
                                Navigator.of(context).pop();
                              }
                            },
                          ),
                          const SizedBox(width: 4),
                        ],
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                          tooltip: 'Tutup',
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Info Produk & Stepper Kuantitas
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
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            CurrencyFormatter.format(widget.product.price),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quantity Stepper
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.lightBackground,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.remove_rounded, size: 18),
                            onPressed: () {
                              if (_quantity > 1) {
                                setState(() => _quantity--);
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.add_rounded, size: 18),
                            onPressed: () {
                              setState(() => _quantity++);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Opsi Kustomisasi Minuman (Gula & Es) vs Makanan (Pedas & Request Khusus)
                if (_isDrink) ...[
                  // Level Gula (3 Opsi Sama Rata)
                  const Text(
                    'Level Gula (Sugar):',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  _buildEqualWidthSelector(
                    options: _sugarOptions,
                    selectedValue: _sugarLevel,
                    onChanged: (val) => setState(() => _sugarLevel = val),
                  ),
                  const SizedBox(height: 16),

                  // Level Es (4 Opsi Sama Rata)
                  const Text(
                    'Level Es (Ice):',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  _buildEqualWidthSelector(
                    options: _iceOptions,
                    selectedValue: _iceLevel,
                    onChanged: (val) => setState(() => _iceLevel = val),
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // 1. Level Pedas (Single-Select: Hanya bisa pilih 1 opsi)
                  const Text(
                    'Tingkat Kepedasan:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  _buildEqualWidthSelector(
                    options: _spicyOptions,
                    selectedValue: _spicyLevel,
                    allowDeselect: true,
                    onChanged: (val) {
                      setState(() {
                        _spicyLevel = (_spicyLevel == val) ? '' : val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Request Khusus Makanan (Multi-Select: Bisa pilih lebih dari 1)
                  const Text(
                    'Request Khusus Makanan:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  _buildMultiSelectRow(
                    options: _foodSpecialRequests,
                    selectedValues: _selectedFoodRequests,
                    onToggle: (val) {
                      setState(() {
                        if (_selectedFoodRequests.contains(val)) {
                          _selectedFoodRequests.remove(val);
                        } else {
                          _selectedFoodRequests.add(val);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Catatan Tambahan (Opsional)
                const Text(
                  'Catatan Tambahan Manual (Opsional):',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    hintText: 'Misal: Saus jangan dicampur, kuah sedikit...',
                    prefixIcon: Icon(Icons.edit_note_rounded, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(height: 22),

                // Tombol Simpan / Tambah
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      final cartController = Get.find<CartController>();
                      final sugar = _isDrink ? _sugarLevel : '';
                      final ice = _isDrink ? _iceLevel : '';
                      final finalNotes = _compileFinalNotes();

                      if (isEditMode && widget.itemIndex != null) {
                        // Update item existing
                        final updatedItem = widget.existingItem!.copyWith(
                          quantity: _quantity,
                          sugarLevel: sugar,
                          iceLevel: ice,
                          notes: finalNotes,
                        );
                        cartController.updateItem(widget.itemIndex!, updatedItem);
                      } else {
                        // Tambah baru
                        cartController.addItem(
                          widget.product,
                          quantity: _quantity,
                          sugarLevel: sugar,
                          iceLevel: ice,
                          notes: finalNotes,
                        );
                      }
                      Navigator.of(context).pop();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditMode ? 'Simpan Perubahan' : 'Tambahkan ke Pesanan',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          CurrencyFormatter.format(widget.product.price * _quantity),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Komponen Selector Pilihan Sama Lebar Single-Select (Radio Group)
  Widget _buildEqualWidthSelector({
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onChanged,
    bool allowDeselect = false,
  }) {
    return Row(
      children: options.map((opt) {
        final isSelected = selectedValue == opt;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: Material(
              color: isSelected ? AppColors.primarySoft : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onChanged(opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
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
                      if (isSelected) ...[
                        const Icon(Icons.check_rounded, size: 14, color: AppColors.primaryDark),
                        const SizedBox(width: 3),
                      ],
                      Flexible(
                        child: Text(
                          opt,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Komponen Selector Pilihan Sama Lebar Multi-Select (Bisa pilih beberapa)
  Widget _buildMultiSelectRow({
    required List<String> options,
    required Set<String> selectedValues,
    required ValueChanged<String> onToggle,
  }) {
    return Row(
      children: options.map((opt) {
        final isSelected = selectedValues.contains(opt);
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3.0),
            child: Material(
              color: isSelected ? AppColors.primarySoft : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onToggle(opt),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
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
                      if (isSelected) ...[
                        const Icon(Icons.check_rounded, size: 14, color: AppColors.primaryDark),
                        const SizedBox(width: 3),
                      ],
                      Flexible(
                        child: Text(
                          opt,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
