import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/core/utils/app_snackbar.dart';
import 'package:noli_apps/app/data/models/expense_category_model.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import 'admin_manage_categories_dialog.dart';

class AdminAddExpenseDialog {
  static Future<bool?> show(BuildContext context, {String initialType = 'out'}) async {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    if (isTablet) {
      return await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 12,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
            child: _ExpenseFormContent(dialogContext: dialogContext),
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
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.90,
            ),
            child: _ExpenseFormContent(dialogContext: sheetContext, isSheet: true),
          ),
        ),
      );
    }
  }
}

class _ExpenseFormContent extends StatefulWidget {
  final BuildContext dialogContext;
  final bool isSheet;

  const _ExpenseFormContent({
    required this.dialogContext,
    this.isSheet = false,
  });

  @override
  State<_ExpenseFormContent> createState() => _ExpenseFormContentState();
}

class _ExpenseFormContentState extends State<_ExpenseFormContent> {
  final AdminController controller = Get.find<AdminController>();

  String _selectedType = 'out'; // 'out' or 'in'
  String _selectedSource = 'petty_cash'; // 'petty_cash' (Tunai), 'bank' (Non-Tunai)
  ExpenseCategoryModel? _selectedCategory;
  DateTime _movementDate = DateTime.now();
  bool _isCustomDate = false;
  File? _receiptImage;
  String _receiptImageName = '';

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (controller.adminExpenseCategories.isEmpty) {
      controller.fetchAdminExpenseCategories();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _addQuickAmount(int additional) {
    final clean = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final current = int.tryParse(clean) ?? 0;
    final total = current + additional;
    _amountController.text = CurrencyFormatter.formatWithoutSymbol(total);
    setState(() {});
  }

  Future<void> _pickReceiptImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);
        final fileSize = await file.length();

        if (fileSize > 5 * 1024 * 1024) {
          AppSnackbar.warning('File Terlalu Besar', 'Maksimal ukuran file foto nota adalah 5MB.');
          return;
        }

        setState(() {
          _receiptImage = file;
          _receiptImageName = result.files.single.name;
        });
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Memilih Gambar', e.toString());
    }
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _isCustomDate ? _movementDate : now,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 30)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_isCustomDate ? _movementDate : now),
    );
    if (!mounted) return;

    final hour = pickedTime?.hour ?? (_isCustomDate ? _movementDate.hour : now.hour);
    final minute = pickedTime?.minute ?? (_isCustomDate ? _movementDate.minute : now.minute);

    setState(() {
      _isCustomDate = true;
      _movementDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        hour,
        minute,
      );
    });
  }

  Future<void> _submit() async {
    final cleanAmount = _amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final double? parsedAmount = double.tryParse(cleanAmount);

    if (parsedAmount == null || parsedAmount <= 0) {
      AppSnackbar.warning('Nominal Tidak Valid', 'Silakan masukkan nominal uang lebih dari Rp 0.');
      return;
    }

    if (_notesController.text.trim().isEmpty) {
      AppSnackbar.warning('Keterangan Diperlukan', 'Silakan isi catatan atau keperluan transaksi.');
      return;
    }

    final actualDate = _isCustomDate ? _movementDate : DateTime.now();

    final success = await controller.storeGeneralExpense(
      type: _selectedType,
      source: _selectedSource,
      amount: parsedAmount,
      categoryId: _selectedCategory?.id,
      categoryName: _selectedCategory?.name ?? (_selectedType == 'out' ? 'Beban Toko' : 'Setoran Kas'),
      notes: _notesController.text.trim(),
      movementDate: actualDate,
      receiptImage: _receiptImage,
    );

    if (success && widget.dialogContext.mounted) {
      Navigator.of(widget.dialogContext).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOut = _selectedType == 'out';
    final accentColor = isOut ? const Color(0xFFE11D48) : const Color(0xFF059669);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Header (Pinned)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isOut ? const Color(0xFFFFF1F2) : const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isOut ? const Color(0xFFFECDD3) : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Icon(
                  isOut ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isOut ? 'Catat Pengeluaran Toko' : 'Catat Kas Masuk (Pay In)',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      isOut
                          ? 'Beban operasional, belanja supplier, atau biaya toko'
                          : 'Setoran modal atau kas masuk non-penjualan',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                onPressed: () => Navigator.of(widget.dialogContext).pop(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // 2. Scrollable Body Form
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A. Segmented Type Switcher (Kas Keluar vs Kas Masuk)
                Container(
                  height: 40,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTypeSegment(
                          label: 'Kas Keluar (Beban)',
                          type: 'out',
                          icon: Icons.arrow_upward_rounded,
                          activeColor: const Color(0xFFE11D48),
                        ),
                      ),
                      Expanded(
                        child: _buildTypeSegment(
                          label: 'Kas Masuk (Pay In)',
                          type: 'in',
                          icon: Icons.arrow_downward_rounded,
                          activeColor: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // B. Hero Input Nominal (Rp)
                _buildFieldLabel('Nominal Transaksi (Rp)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ThousandsSeparatorInputFormatter(),
                  ],
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 8),
                      child: Text(
                        'Rp',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _amountController,
                      builder: (context, value, child) {
                        if (value.text.isEmpty) return const SizedBox.shrink();
                        return IconButton(
                          tooltip: 'Hapus Nominal',
                          icon: const Icon(Icons.cancel, size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _amountController.clear();
                            setState(() {});
                          },
                        );
                      },
                    ),
                    hintText: '0',
                    hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.normal),
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
                      borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Quick Amount Chips
                Row(
                  children: [
                    Expanded(child: _buildQuickChip('+50k', 50000)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildQuickChip('+100k', 100000)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildQuickChip('+500k', 500000)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildQuickChip('+1 Jt', 1000000)),
                  ],
                ),
                const SizedBox(height: 16),

                // C. Sumber Dana (Clean Duo Segmented Bar: Tunai vs Non-Tunai)
                _buildFieldLabel('Sumber Dana'),
                const SizedBox(height: 6),
                Container(
                  height: 42,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSourceSegment(
                          id: 'petty_cash',
                          label: 'Tunai (Cash)',
                          icon: Icons.payments_rounded,
                          activeColor: const Color(0xFF059669),
                        ),
                      ),
                      Expanded(
                        child: _buildSourceSegment(
                          id: 'bank',
                          label: 'Non-Tunai (Bank / Transfer)',
                          icon: Icons.account_balance_rounded,
                          activeColor: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // D. Kategori Dropdown (Clean & Uncluttered)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFieldLabel(isOut ? 'Kategori Pengeluaran' : 'Kategori Kas Masuk'),
                    InkWell(
                      onTap: () async {
                        await AdminManageCategoriesDialog.show(context);
                        setState(() {});
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: const Text(
                        '+ Kelola Kategori',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Obx(() {
                  final allCats = controller.adminExpenseCategories;
                  final filteredCats = allCats.where((c) {
                    if (isOut) return c.isExpense;
                    return c.isCashIn;
                  }).toList();

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedCategory?.id,
                        hint: Text(
                          isOut ? 'Pilih Kategori Beban...' : 'Pilih Kategori Kas Masuk...',
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        items: filteredCats.map((cat) {
                          return DropdownMenuItem<int>(
                            value: cat.id,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.label_outline_rounded,
                                  size: 15,
                                  color: _selectedCategory?.id == cat.id
                                      ? AppColors.secondary
                                      : const Color(0xFF64748B),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  cat.name,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: _selectedCategory?.id == cat.id
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _selectedCategory?.id == cat.id
                                        ? AppColors.secondary
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            _selectedCategory = filteredCats.firstWhereOrNull((c) => c.id == val);
                          });
                        },
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // E. Waktu & Tanggal Transaksi (Otomatis sekarang dengan opsi Ubah Tanggal)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: _isCustomDate ? const Color(0xFFFFFBEB) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isCustomDate ? const Color(0xFFFDE68A) : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isCustomDate ? Icons.edit_calendar_rounded : Icons.schedule_rounded,
                        size: 15,
                        color: _isCustomDate ? const Color(0xFFD97706) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                            children: [
                              TextSpan(
                                text: _isCustomDate ? 'Tanggal manual: ' : 'Waktu transaksi: ',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              TextSpan(
                                text: _isCustomDate
                                    ? DateFormat('d MMM yyyy, HH:mm').format(_movementDate)
                                    : 'Otomatis sekarang (${DateFormat('d MMM, HH:mm').format(DateTime.now())})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: _isCustomDate ? const Color(0xFFB45309) : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isCustomDate) ...[
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isCustomDate = false;
                              _movementDate = DateTime.now();
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            child: Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      InkWell(
                        onTap: _pickCustomDate,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isCustomDate ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _isCustomDate ? 'Ubah' : 'Ubah Tanggal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isCustomDate ? const Color(0xFFB45309) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // F. Keterangan / Keperluan
                _buildFieldLabel('Keterangan / Keperluan'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: isOut
                        ? 'Contoh: Bayar sewa ruko bulan ini, beli bahan baku kopi...'
                        : 'Contoh: Tambahan modal kas toko dari owner...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                      borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // G. Foto Bukti Nota / Kwitansi (Compact & Clean)
                _buildFieldLabel('Foto Bukti Nota (Opsional)'),
                const SizedBox(height: 6),
                if (_receiptImage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            _receiptImage!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _receiptImageName,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Foto nota berhasil dipilih',
                                style: TextStyle(fontSize: 10.5, color: Color(0xFF059669)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hapus Foto',
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                          onPressed: () {
                            setState(() {
                              _receiptImage = null;
                              _receiptImageName = '';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: _pickReceiptImage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFFCBD5E1),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo_outlined, size: 16, color: Color(0xFF475569)),
                          SizedBox(width: 8),
                          Text(
                            'Unggah Foto Bukti Nota / Kwitansi',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 3. Footer Action Buttons (Pinned)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Navigator.of(widget.dialogContext).pop(),
                  child: const Text(
                    'Batal',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Obx(() {
                  final isSubmitting = controller.isSubmittingGeneralExpense.value;
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOut ? const Color(0xFFE11D48) : const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: isSubmitting ? null : _submit,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle_outline_rounded, size: 17),
                    label: Text(
                      isSubmitting ? 'Menyimpan...' : 'Simpan Transaksi',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
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

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildTypeSegment({
    required String label,
    required String type,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedType == type;
    return Material(
      color: isSelected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      elevation: isSelected ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _selectedType = type;
            _selectedCategory = null;
          });
        },
        child: Container(
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? activeColor : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSourceSegment({
    required String id,
    required String label,
    required IconData icon,
    required Color activeColor,
  }) {
    final isSelected = _selectedSource == id;
    return Material(
      color: isSelected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      elevation: isSelected ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() {
            _selectedSource = id;
          });
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? activeColor : const Color(0xFF64748B),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeColor : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label, int amount) {
    return Material(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _addQuickAmount(amount),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue();
    }

    final number = int.tryParse(digitsOnly);
    if (number == null) {
      return oldValue;
    }

    final newString = CurrencyFormatter.formatWithoutSymbol(number);

    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
