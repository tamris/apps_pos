import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/data/models/admin_ingredient_model.dart';
import 'package:noli_apps/app/data/models/admin_stock_mutation_model.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

// -----------------------------------------------------------------------------
// 1. DIALOG FORM TAMBAH / EDIT BAHAN BAKU
// -----------------------------------------------------------------------------
class AdminIngredientFormDialog extends StatefulWidget {
  final AdminIngredientModel? ingredient;

  const AdminIngredientFormDialog({super.key, this.ingredient});

  static Future<bool?> show(BuildContext context, {AdminIngredientModel? ingredient}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminIngredientFormDialog(ingredient: ingredient),
    );
  }

  @override
  State<AdminIngredientFormDialog> createState() => _AdminIngredientFormDialogState();
}

class _AdminIngredientFormDialogState extends State<AdminIngredientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = Get.find<AdminController>();

  late TextEditingController _nameController;
  late TextEditingController _skuController;
  late TextEditingController _stockController;
  late TextEditingController _minStockController;
  late TextEditingController _buyPriceController;
  late TextEditingController _buyAmountController;

  String _category = 'Kopi';
  String _unit = 'gram';
  String _buyUnit = 'kg';
  bool _isLoading = false;

  final List<String> _categories = [
    'Kopi',
    'Dairy & Susu',
    'Syrup & Sauce',
    'Powder & Bubuk',
    'Teh',
    'Topping & Add-on',
    'Kemasan & Cup',
    'Lainnya',
  ];

  final List<String> _units = ['gram', 'ml', 'pcs', 'shot', 'slice', 'sachet', 'porsi'];
  final List<String> _buyUnits = ['kg', 'liter', 'gram', 'ml', 'pcs', 'pack', 'dus', 'botol'];

  @override
  void initState() {
    super.initState();
    final ing = widget.ingredient;
    _nameController = TextEditingController(text: ing?.name ?? '');
    _skuController = TextEditingController(text: ing?.sku ?? '');
    _stockController = TextEditingController(text: ing != null ? ing.formattedStock : '0');
    _minStockController = TextEditingController(text: ing != null ? ing.formattedMinStock : '100');
    _buyPriceController = TextEditingController(
      text: (ing != null && ing.buyPrice > 0)
          ? CurrencyFormatter.formatWithoutSymbol(ing.buyPrice.toInt())
          : '0',
    );
    _buyAmountController = TextEditingController(
      text: (ing != null && ing.buyAmount > 0) ? ing.buyAmount.toInt().toString() : '1',
    );

    if (ing != null) {
      if (_categories.contains(ing.category)) {
        _category = ing.category;
      }
      if (_units.contains(ing.unit.toLowerCase())) {
        _unit = ing.unit.toLowerCase();
      }
      if (_buyUnits.contains(ing.buyUnit.toLowerCase())) {
        _buyUnit = ing.buyUnit.toLowerCase();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _buyPriceController.dispose();
    _buyAmountController.dispose();
    super.dispose();
  }

  double _calculateCostPerUnit() {
    final price = double.tryParse(_buyPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    final amount = double.tryParse(_buyAmountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1.0;
    if (amount <= 0 || price <= 0) return 0.0;

    // Hitung konversi standar bila satuan beli kg -> gram atau liter -> ml
    double multiplier = 1.0;
    if ((_buyUnit == 'kg' && _unit == 'gram') || (_buyUnit == 'liter' && _unit == 'ml')) {
      multiplier = 1000.0;
    }
    return price / (amount * multiplier);
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final cost = _calculateCostPerUnit();
    final buyPrice = double.tryParse(_buyPriceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
    final buyAmount = double.tryParse(_buyAmountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 1.0;
    final stock = double.tryParse(_stockController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final minStock = double.tryParse(_minStockController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    final payload = {
      'name': _nameController.text.trim(),
      'category': _category,
      'sku': _skuController.text.trim(),
      'unit': _unit,
      'min_stock': minStock,
      'cost_per_unit': cost,
      'buy_price': buyPrice,
      'buy_amount': buyAmount,
      'buy_unit': _buyUnit,
      'stock': stock,
    };

    final bool success;
    if (widget.ingredient != null) {
      success = await _controller.updateIngredient(widget.ingredient!.id, payload);
    } else {
      success = await _controller.createIngredient(payload);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.ingredient != null;
    final estimatedCost = _calculateCostPerUnit();

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
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1E000000),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.inventory_2_rounded,
                              color: Color(0xFF4F46E5),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit ? 'Edit Bahan Baku' : 'Tambah Bahan Baku',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEdit
                                      ? 'Perbarui informasi dan takaran biaya bahan'
                                      : 'Daftarkan bahan baku baru ke sistem inventaris',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF1F5F9),
                              padding: const EdgeInsets.all(8),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Nama Bahan
                      _buildFieldLabel('Nama Bahan Baku', required: true),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                        decoration: _buildInputDecoration(
                          hint: 'Contoh: Biji Kopi Arabika, Susu Segar',
                          prefixIcon: Icons.inventory_2_outlined,
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Nama bahan baku wajib diisi';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // Kategori & SKU
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Kategori Bahan'),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  initialValue: _categories.contains(_category) ? _category : _categories.first,
                                  isExpanded: true,
                                  isDense: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                                  dropdownColor: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  decoration: _buildInputDecoration(hint: 'Pilih Kategori'),
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                  items: _categories.map((c) {
                                    return DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _category = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('SKU / Kode'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _skuController,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                  decoration: _buildInputDecoration(hint: 'Opsional'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Satuan Resep & Batas Minimum
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Satuan Resep / POS', required: true),
                                const SizedBox(height: 6),
                                DropdownButtonFormField<String>(
                                  key: ValueKey('stock_unit_$_unit'),
                                  initialValue: _units.contains(_unit) ? _unit : _units.first,
                                  isExpanded: true,
                                  isDense: true,
                                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                                  dropdownColor: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  decoration: _buildInputDecoration(hint: 'Pilih Satuan'),
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                  items: _units.map((u) {
                                    return DropdownMenuItem(
                                      value: u,
                                      child: Text(
                                        u,
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _unit = val;
                                        // Smart defaults for stock unit:
                                        if (val == 'pcs' || val == 'sachet' || val == 'slice' || val == 'shot' || val == 'porsi') {
                                          if (_minStockController.text == '100' || _minStockController.text.isEmpty) {
                                            _minStockController.text = '20';
                                          }
                                          if (_buyUnit == 'kg' || _buyUnit == 'liter') {
                                            _buyUnit = val == 'sachet' ? 'sachet' : 'pcs';
                                          }
                                        } else if (val == 'gram') {
                                          if (_minStockController.text == '20' || _minStockController.text.isEmpty) {
                                            _minStockController.text = '100';
                                          }
                                          if (_buyUnit == 'pcs' || _buyUnit == 'liter' || _buyUnit == 'sachet') {
                                            _buyUnit = 'kg';
                                          }
                                        } else if (val == 'ml') {
                                          if (_minStockController.text == '20' || _minStockController.text.isEmpty) {
                                            _minStockController.text = '200';
                                          }
                                          if (_buyUnit == 'pcs' || _buyUnit == 'kg' || _buyUnit == 'sachet') {
                                            _buyUnit = 'liter';
                                          }
                                        }
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Batas Min. Stok'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _minStockController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                  decoration: _buildInputDecoration(
                                    hint: '100',
                                    suffixText: _unit,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Harga Beli Terakhir & Kalkulasi Otomatis Biaya per Satuan
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.calculate_rounded, size: 16, color: Color(0xFF4F46E5)),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Kalkulasi Biaya Satuan (HPP Bahan)',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      SizedBox(height: 1),
                                      Text(
                                        'Konversi otomatis biaya beli ke takaran resep POS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('Harga Beli Saat Ini (Rp)'),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _buyPriceController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                          CurrencyInputFormatter(),
                                        ],
                                        onChanged: (_) => setState(() {}),
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                        decoration: _buildInputDecoration(
                                          hint: '0',
                                          prefixText: 'Rp ',
                                          fillColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('Jumlah Beli'),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _buyAmountController,
                                        keyboardType: TextInputType.number,
                                        onChanged: (_) => setState(() {}),
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                        decoration: _buildInputDecoration(hint: '1', fillColor: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildFieldLabel('Satuan Beli'),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<String>(
                                        key: ValueKey('stock_buy_unit_$_buyUnit'),
                                        initialValue: _buyUnits.contains(_buyUnit) ? _buyUnit : _buyUnits.first,
                                        isExpanded: true,
                                        isDense: true,
                                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                                        dropdownColor: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        decoration: _buildInputDecoration(hint: 'Satuan', fillColor: Colors.white),
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                        items: _buyUnits.map((bu) {
                                          return DropdownMenuItem(
                                            value: bu,
                                            child: Text(
                                              bu,
                                              style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) setState(() => _buyUnit = val);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Unit Mismatch Warning
                            Builder(
                              builder: (context) {
                                final isCountUnit = (_unit == 'pcs' || _unit == 'sachet' || _unit == 'slice' || _unit == 'shot' || _unit == 'porsi');
                                final isWeightUnit = (_unit == 'gram');
                                final isVolumeUnit = (_unit == 'ml');

                                final isBuyCount = (_buyUnit == 'pcs' || _buyUnit == 'pack' || _buyUnit == 'dus' || _buyUnit == 'sachet');
                                final isBuyWeight = (_buyUnit == 'kg' || _buyUnit == 'gram');
                                final isBuyVolume = (_buyUnit == 'liter' || _buyUnit == 'ml' || _buyUnit == 'botol');

                                final isUnitMismatch = (isCountUnit && (isBuyWeight || isBuyVolume)) ||
                                    (isWeightUnit && (isBuyCount || isBuyVolume)) ||
                                    (isVolumeUnit && (isBuyCount || isBuyWeight));

                                if (!isUnitMismatch) return const SizedBox.shrink();

                                return Container(
                                  margin: const EdgeInsets.only(top: 10, bottom: 2),
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
                                          'Satuan resep/POS ($_unit) berbeda jenis dengan satuan beli ($_buyUnit). Sesuaikan Satuan Beli ke ${isCountUnit ? 'pcs/pack' : (isWeightUnit ? 'kg' : 'liter')} agar HPP bahan akurat.',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFC7D2FE)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4F46E5),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.auto_awesome_rounded, size: 13, color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Biaya Riil per Satuan Resep:',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF3730A3),
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          estimatedCost > 0
                                              ? 'Dihitung otomatis ke HPP produk'
                                              : 'Isi harga & satuan beli untuk hitung biaya',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF6366F1),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFC7D2FE)),
                                      boxShadow: const [
                                        BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
                                      ],
                                    ),
                                    child: Text(
                                      '${CurrencyFormatter.format(estimatedCost)} / $_unit',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF312E81),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (!isEdit) ...[
                        const SizedBox(height: 16),
                        _buildFieldLabel('Stok Awal di Gudang / Bar'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
                          decoration: _buildInputDecoration(
                            hint: '0',
                            suffixText: _unit,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: EdgeInsets.zero,
                                ),
                                child: const Text(
                                  'Batal',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: SizedBox(
                              height: 44,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSave,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: EdgeInsets.zero,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                                          const SizedBox(width: 6),
                                          Text(
                                            isEdit ? 'Simpan Perubahan' : 'Daftarkan Bahan',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool required = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
            letterSpacing: -0.1,
          ),
        ),
        if (required)
          const Text(
            ' *',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger),
          ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    IconData? prefixIcon,
    String? prefixText,
    String? suffixText,
    Color fillColor = const Color(0xFFF8FAFC),
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 17, color: const Color(0xFF94A3B8)) : null,
      prefixText: prefixText,
      prefixStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
      suffixText: suffixText,
      suffixStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      isDense: true,
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
        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. DIALOG RESTOCK BAHAN BAKU
// -----------------------------------------------------------------------------
class AdminIngredientRestockDialog extends StatefulWidget {
  final AdminIngredientModel ingredient;

  const AdminIngredientRestockDialog({super.key, required this.ingredient});

  static Future<bool?> show(BuildContext context, {required AdminIngredientModel ingredient}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminIngredientRestockDialog(ingredient: ingredient),
    );
  }

  @override
  State<AdminIngredientRestockDialog> createState() => _AdminIngredientRestockDialogState();
}

class _AdminIngredientRestockDialogState extends State<AdminIngredientRestockDialog> {
  final _controller = Get.find<AdminController>();
  final _amountController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  bool _recordToExpense = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleRestock() async {
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final totalCost = double.tryParse(_costController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;

    if (amount <= 0) {
      Get.snackbar('Perhatian', 'Jumlah restock harus lebih dari 0', backgroundColor: Colors.amber.shade100);
      return;
    }

    setState(() => _isLoading = true);

    final success = await _controller.restockIngredient(
      widget.ingredient.id,
      amount: amount,
      totalCost: totalCost,
      notes: _notesController.text.trim(),
      recordToExpense: _recordToExpense,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient;
    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final newStock = ing.stock + amount;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1E000000),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_shopping_cart_rounded,
                          color: Color(0xFF4F46E5),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Restock ${ing.name}',
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
                              ing.isDebtStock
                                  ? 'Hutang stok saat ini: ${ing.stock.abs().toInt()} ${ing.unit} (Terpakai belum dicatat)'
                                  : 'Stok saat ini: ${ing.formattedStock} ${ing.unit}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: ing.isDebtStock ? FontWeight.w600 : FontWeight.normal,
                                color: ing.isDebtStock ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Input Jumlah Restock
                  const Text(
                    'Jumlah Stok Masuk',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Contoh: 1000',
                      suffixText: ing.unit,
                      suffixStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),

                  if (ing.isDebtStock) ...[
                    Builder(builder: (_) {
                      final inputVal = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
                      final finalStock = ing.stock + inputVal;
                      final isCovered = finalStock >= 0;

                      return Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: isCovered ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCovered ? const Color(0xFFA7F3D0) : const Color(0xFFFDA4AF),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCovered ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                              size: 14,
                              color: isCovered ? const Color(0xFF059669) : const Color(0xFFE11D48),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                inputVal == 0
                                    ? 'Hutang ${ing.stock.abs().toInt()} ${ing.unit} akan otomatis terpotong saat restock.'
                                    : 'Stok akhir: (${ing.stock.toInt()} + ${inputVal.toInt()}) = ${finalStock % 1 == 0 ? finalStock.toInt() : finalStock.toStringAsFixed(1)} ${ing.unit}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isCovered ? const Color(0xFF065F46) : const Color(0xFF9F1239),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 14),

                  // Total Biaya Beli
                  const Text(
                    'Total Biaya Restock (Rp)',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      CurrencyInputFormatter(),
                    ],
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: '0',
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Catatan Supplier
                  const Text(
                    'Catatan / Nama Supplier',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Beli di Supplier A (No. Nota 1234)',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Switch Beban Pengeluaran Kas
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 18, color: Color(0xFF4F46E5)),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Catat otomatis ke Arus Kas Toko (Beban Belanja Bahan)',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ),
                        Switch(
                          value: _recordToExpense,
                          activeThumbColor: const Color(0xFF4F46E5),
                          onChanged: (val) => setState(() => _recordToExpense = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Proyeksi Stok Baru Box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Proyeksi Stok Akhir:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)),
                        ),
                        Text(
                          '${newStock % 1 == 0 ? newStock.toInt() : newStock.toStringAsFixed(1)} ${ing.unit}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF3730A3)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Batal', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleRestock,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Simpan Restock',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. DIALOG STOCK OPNAME FISIK
// -----------------------------------------------------------------------------
class AdminIngredientOpnameDialog extends StatefulWidget {
  final AdminIngredientModel ingredient;

  const AdminIngredientOpnameDialog({super.key, required this.ingredient});

  static Future<bool?> show(BuildContext context, {required AdminIngredientModel ingredient}) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminIngredientOpnameDialog(ingredient: ingredient),
    );
  }

  @override
  State<AdminIngredientOpnameDialog> createState() => _AdminIngredientOpnameDialogState();
}

class _AdminIngredientOpnameDialogState extends State<AdminIngredientOpnameDialog> {
  final _controller = Get.find<AdminController>();
  late TextEditingController _actualStockController;
  final _notesController = TextEditingController();

  String _reason = 'adjustment';
  bool _isLoading = false;

  Map<String, String> _getReasons(double diff) {
    final ing = widget.ingredient;
    final isPackaging = !ing.isPerishable;

    if (diff > 0) {
      return {
        'adjustment': 'Koreksi Stok (Temuan Fisik Lebih / Surplus)',
      };
    } else if (diff < 0) {
      final reasons = <String, String>{};
      reasons['waste'] = isPackaging
          ? 'Barang Rusak / Cacat / Pecah'
          : 'Bahan Rusak / Basi / Terbuang';
      reasons['missing'] = 'Selisih Hitung / Hilang';
      if (!isPackaging) {
        reasons['expired'] = 'Kadaluarsa';
      }
      reasons['adjustment'] = 'Koreksi Stok Rutin (Susut)';
      return reasons;
    } else {
      return {
        'adjustment': 'Stok Sesuai (Klop / Sama)',
      };
    }
  }

  @override
  void initState() {
    super.initState();
    _actualStockController = TextEditingController(text: widget.ingredient.formattedStock);
    _reason = 'adjustment';
  }

  @override
  void dispose() {
    _actualStockController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleOpname() async {
    final actual = double.tryParse(_actualStockController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    setState(() => _isLoading = true);

    final success = await _controller.opnameIngredient(
      id: widget.ingredient.id,
      actualStock: actual,
      reason: _reason,
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient;
    final actual = double.tryParse(_actualStockController.text.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    final diff = actual - ing.stock;
    final reasons = _getReasons(diff);
    if (!reasons.containsKey(_reason)) {
      _reason = reasons.keys.first;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1E000000),
                  blurRadius: 30,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fact_check_outlined,
                          color: Color(0xFF0F172A),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stock Opname ${ing.name}',
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
                            const Text(
                              'Sesuaikan stok tercatat dengan hasil hitung fisik',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Stok Sistem Saat Ini
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Stok Sistem (Aplikasi):',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        Text(
                          '${ing.formattedStock} ${ing.unit}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Input Stok Fisik Riil
                  const Text(
                    'Hasil Hitung Stok Fisik Riil',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _actualStockController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: '0',
                      suffixText: ing.unit,
                      suffixStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Badge Selisih
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: diff < 0
                          ? const Color(0xFFFEF2F2)
                          : (diff > 0 ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: diff < 0
                            ? const Color(0xFFFECACA)
                            : (diff > 0 ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          diff < 0
                              ? 'Selisih Berkurang (Susut / Hilang):'
                              : (diff > 0 ? 'Selisih Bertambah (Lebih):' : 'Status Selisih:'),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: diff < 0
                                ? const Color(0xFFDC2626)
                                : (diff > 0 ? const Color(0xFF059669) : const Color(0xFF64748B)),
                          ),
                        ),
                        Text(
                          diff == 0
                              ? 'Sesuai (Klop)'
                              : '${diff > 0 ? '+' : ''}${diff % 1 == 0 ? diff.toInt() : diff.toStringAsFixed(1)} ${ing.unit}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: diff < 0
                                ? const Color(0xFFDC2626)
                                : (diff > 0 ? const Color(0xFF059669) : const Color(0xFF0F172A)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Alasan Penyesuaian
                  const Text(
                    'Alasan Penyesuaian',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: reasons.containsKey(_reason) ? _reason : reasons.keys.first,
                        isExpanded: true,
                        items: reasons.entries.map((e) {
                          return DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value, style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A))),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _reason = val);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Catatan
                  const Text(
                    'Catatan Pemeriksa (Opsional)',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Opname penutupan shift sore',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Batal', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleOpname,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text(
                                  'Terapkan Opname',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. DIALOG RIWAYAT MUTASI BAHAN BAKU
// -----------------------------------------------------------------------------
class AdminIngredientMutationsDialog extends StatefulWidget {
  final AdminIngredientModel ingredient;

  const AdminIngredientMutationsDialog({super.key, required this.ingredient});

  static void show(BuildContext context, {required AdminIngredientModel ingredient}) {
    showDialog(
      context: context,
      builder: (context) => AdminIngredientMutationsDialog(ingredient: ingredient),
    );
  }

  @override
  State<AdminIngredientMutationsDialog> createState() => _AdminIngredientMutationsDialogState();
}

class _AdminIngredientMutationsDialogState extends State<AdminIngredientMutationsDialog> {
  final _controller = Get.find<AdminController>();
  final ScrollController _scrollController = ScrollController();
  List<AdminStockMutationModel> _mutations = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  int _currentPage = 1;
  int _totalRecords = 0;
  double _serverTotalIn = 0.0;
  double _serverTotalOut = 0.0;
  double _serverNetChange = 0.0;

  String _selectedPeriod = '7d'; // '7d', '30d', 'all'
  String _selectedType = 'all'; // 'all', 'restock', 'pos', 'opname', 'waste'

  String? get _startDate {
    final now = DateTime.now();
    if (_selectedPeriod == '7d') {
      return DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 7)));
    } else if (_selectedPeriod == '30d') {
      return DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 30)));
    }
    return null;
  }

  String? get _endDate {
    if (_selectedPeriod == 'all') return null;
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMutations();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 50) {
      _loadMore();
    }
  }

  Future<void> _loadMutations() async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _hasMore = false;
      _serverTotalIn = 0.0;
      _serverTotalOut = 0.0;
      _serverNetChange = 0.0;
      _mutations.clear();
    });

    final res = await _controller.fetchIngredientMutationsPaginated(
      widget.ingredient.id,
      type: _selectedType == 'all' ? null : _selectedType,
      startDate: _startDate,
      endDate: _endDate,
      page: 1,
      perPage: 20,
    );

    if (mounted) {
      setState(() {
        _mutations = res.items;
        _currentPage = res.currentPage;
        _hasMore = res.hasMore;
        _totalRecords = res.total;
        _serverTotalIn = res.totalIn;
        _serverTotalOut = res.totalOut;
        _serverNetChange = res.netChange;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    final res = await _controller.fetchIngredientMutationsPaginated(
      widget.ingredient.id,
      type: _selectedType == 'all' ? null : _selectedType,
      startDate: _startDate,
      endDate: _endDate,
      page: _currentPage + 1,
      perPage: 20,
    );

    if (mounted) {
      setState(() {
        _mutations.addAll(res.items);
        _currentPage = res.currentPage;
        _hasMore = res.hasMore;
        _totalRecords = res.total;
        _isLoadingMore = false;
      });
    }
  }

  Widget _buildPeriodTab(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return InkWell(
      onTap: () {
        if (_selectedPeriod != value) {
          setState(() => _selectedPeriod = value);
          _loadMutations();
        }
      },
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String label, String value, IconData icon) {
    final isSelected = _selectedType == value;
    return InkWell(
      onTap: () {
        if (_selectedType != value) {
          setState(() => _selectedType = value);
          _loadMutations();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF64748B),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 620,
            maxHeight: 720,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 32,
                  offset: Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        color: Color(0xFF0F172A),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  'Riwayat Mutasi: ${ing.name}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.2,
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
                                  'Stok: ${ing.formattedStock} ${ing.unit}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4F46E5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Catatan riwayat keluar-masuk & koreksi stok bahan',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF1F5F9),
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(32, 32),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),

                // 1. Unified Filter Row: Type Filters (Left) + Period Segmented Bar (Right)
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildTypeChip('Semua Tipe', 'all', Icons.all_inclusive_rounded),
                            const SizedBox(width: 6),
                            _buildTypeChip('Restock', 'restock', Icons.add_shopping_cart_rounded),
                            const SizedBox(width: 6),
                            _buildTypeChip('Kasir POS', 'pos', Icons.point_of_sale_rounded),
                            const SizedBox(width: 6),
                            _buildTypeChip('Opname', 'opname', Icons.fact_check_outlined),
                            const SizedBox(width: 6),
                            _buildTypeChip('Rusak', 'waste', Icons.delete_outline_rounded),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPeriodTab('7 Hari', '7d'),
                          _buildPeriodTab('30 Hari', '30d'),
                          _buildPeriodTab('Semua', 'all'),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 2. 3-Column Balanced Metrics Strip (Filling 100% width with 0 empty gaps)
                Builder(builder: (_) {
                  final totalIn = _serverTotalIn != 0.0 || _serverTotalOut != 0.0
                      ? _serverTotalIn
                      : _mutations.where((m) => m.isIncrease).fold(0.0, (s, m) => s + m.amount);
                  final totalOut = _serverTotalIn != 0.0 || _serverTotalOut != 0.0
                      ? _serverTotalOut
                      : _mutations.where((m) => !m.isIncrease).fold(0.0, (s, m) => s + m.amount.abs());
                  final netChange = _serverTotalIn != 0.0 || _serverTotalOut != 0.0
                      ? _serverNetChange
                      : totalIn - totalOut;

                  String fmt(double val) =>
                      val % 1 == 0 ? val.toInt().toString() : val.toStringAsFixed(1);

                  Widget buildSummaryCard({
                    required String title,
                    required String value,
                    required String unit,
                    required IconData icon,
                    required Color bg,
                    required Color border,
                    required Color iconBg,
                    required Color iconColor,
                    required Color titleColor,
                    required Color valueColor,
                  }) {
                    return Expanded(
                      child: Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: iconBg,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Icon(icon, size: 11, color: iconColor),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: titleColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    value,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: valueColor,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(width: 2.5),
                                  Text(
                                    unit,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: valueColor.withValues(alpha: 0.8),
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

                  return Row(
                    children: [
                      // Total Masuk
                      buildSummaryCard(
                        title: 'Total Masuk',
                        value: '+${fmt(totalIn)}',
                        unit: ing.unit,
                        icon: Icons.arrow_upward_rounded,
                        bg: const Color(0xFFF0FDF4),
                        border: const Color(0xFFBBF7D0),
                        iconBg: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        titleColor: const Color(0xFF15803D),
                        valueColor: const Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 6),
                      // Total Keluar
                      buildSummaryCard(
                        title: 'Total Keluar',
                        value: '-${fmt(totalOut)}',
                        unit: ing.unit,
                        icon: Icons.arrow_downward_rounded,
                        bg: const Color(0xFFFEF2F2),
                        border: const Color(0xFFFECACA),
                        iconBg: const Color(0xFFFEE2E2),
                        iconColor: const Color(0xFFDC2626),
                        titleColor: const Color(0xFFB91C1C),
                        valueColor: const Color(0xFFDC2626),
                      ),
                      const SizedBox(width: 6),
                      // Mutasi / Netto
                      buildSummaryCard(
                        title: 'Mutasi (${_totalRecords > 0 ? _totalRecords : _mutations.length})',
                        value: '${netChange >= 0 ? '+' : ''}${fmt(netChange)}',
                        unit: ing.unit,
                        icon: Icons.swap_vert_rounded,
                        bg: const Color(0xFFF8FAFC),
                        border: const Color(0xFFE2E8F0),
                        iconBg: const Color(0xFFE2E8F0),
                        iconColor: const Color(0xFF475569),
                        titleColor: const Color(0xFF64748B),
                        valueColor: netChange > 0
                            ? const Color(0xFF16A34A)
                            : netChange < 0
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF475569),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 10),

                // 3. Content Area: Flexible so if 3 items, it snugly wraps with NO empty white space at the bottom!
                Flexible(
                  fit: FlexFit.loose,
                  child: _isLoading
                      ? const SizedBox(
                          height: 445,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Memuat riwayat mutasi...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _mutations.isEmpty
                          ? Container(
                              width: double.infinity,
                              height: 180,
                              margin: const EdgeInsets.only(top: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.inbox_outlined, size: 34, color: Color(0xFF94A3B8)),
                                    SizedBox(height: 8),
                                    Text(
                                      'Belum ada riwayat mutasi pada filter ini',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxHeight: 455,
                              ),
                              child: ListView.separated(
                                controller: _scrollController,
                                shrinkWrap: true,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.only(top: 2, bottom: 4),
                                itemCount: _mutations.length + (_hasMore || _isLoadingMore ? 1 : 0),
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  if (index == _mutations.length) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      child: Center(
                                        child: _isLoadingMore
                                            ? const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: AppColors.secondary,
                                                    ),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text(
                                                    'Memuat mutasi berikutnya...',
                                                    style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                                  ),
                                                ],
                                              )
                                            : InkWell(
                                                onTap: _loadMore,
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF1F5F9),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: const Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(Icons.expand_more_rounded, size: 16, color: Color(0xFF475569)),
                                                      SizedBox(width: 4),
                                                      Text(
                                                        'Muat riwayat lebih banyak...',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w600,
                                                          color: Color(0xFF475569),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                      ),
                                    );
                                  }

                                  final mut = _mutations[index];
                                  final isPlus = mut.isIncrease;

                                  return Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      children: [
                                        // Indicator Icon
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: isPlus ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            isPlus ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                            color: isPlus ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      mut.typeLabel,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w700,
                                                        color: Color(0xFF0F172A),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '${isPlus ? '+' : ''}${mut.amount % 1 == 0 ? mut.amount.toInt() : mut.amount.toStringAsFixed(1)} ${ing.unit}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w800,
                                                      color: isPlus ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      'Sebelum: ${mut.stockBefore % 1 == 0 ? mut.stockBefore.toInt() : mut.stockBefore.toStringAsFixed(1)} ➔ Sesudah: ${mut.stockAfter % 1 == 0 ? mut.stockAfter.toInt() : mut.stockAfter.toStringAsFixed(1)}',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: Color(0xFF64748B),
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    mut.formattedDateTime,
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Color(0xFF94A3B8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (mut.notes.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Catatan: ${mut.notes} • Oleh: ${mut.userName}',
                                                  style: const TextStyle(
                                                    fontSize: 10.5,
                                                    fontStyle: FontStyle.italic,
                                                    color: Color(0xFF475569),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
}
