import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../controllers/cash_flow_controller.dart';
import '../controllers/shift_controller.dart';

class CashMovementDialog {
  /// Buka dialog / bottom-sheet pencatatan arus kas (responsif phone & tablet)
  static Future<bool?> show(BuildContext context, {String initialType = 'out'}) async {
    final cashFlowController = Get.isRegistered<CashFlowController>()
        ? Get.find<CashFlowController>()
        : Get.put(CashFlowController());

    cashFlowController.resetForm();
    cashFlowController.setType(initialType);

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
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 740),
            child: _MovementFormContent(dialogContext: dialogContext),
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
            child: _MovementFormContent(dialogContext: sheetContext, isSheet: true),
          ),
        ),
      );
    }
  }
}

class _MovementFormContent extends StatelessWidget {
  final BuildContext dialogContext;
  final bool isSheet;

  const _MovementFormContent({
    required this.dialogContext,
    this.isSheet = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CashFlowController>();
    final shiftController = Get.find<ShiftController>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Handle bar untuk mobile bottom-sheet
        if (isSheet) ...[
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],

        // 1. Header Dialog (PINNED)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withAlpha(40)),
                ),
                child: const Icon(
                  Icons.payments_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pencatatan Arus Kas Laci',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Mutasi uang tunai kasir shift aktif',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.lightBorder),

        // 2. Segmented Switch & Saldo Laci (PINNED AT TOP AGAR TIDAK HILANG SAAT DI-SCROLL)
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Segmented Switch: Kas Keluar vs Kas Masuk
              Obx(() {
                final isOut = controller.selectedType.value == 'out';
                return Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Button Kas Keluar
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.setType('out'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: isOut ? AppColors.danger : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: isOut
                                  ? [
                                      BoxShadow(
                                        color: AppColors.danger.withAlpha(60),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 16,
                                  color: isOut ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Kas Keluar (Petty)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: isOut ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Button Kas Masuk
                      Expanded(
                        child: GestureDetector(
                          onTap: () => controller.setType('in'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: !isOut ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: !isOut
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withAlpha(60),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 16,
                                  color: !isOut ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Kas Masuk (Pay In)',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: !isOut ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 10),

              // Baris Ringkas Saldo Laci Saat Ini
              Obx(() {
                final shift = shiftController.currentShift.value;
                final double expectedCash = shift?.expectedCash ?? 0.0;
                final isOut = controller.selectedType.value == 'out';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isOut ? AppColors.dangerSoft.withAlpha(60) : AppColors.primarySoft.withAlpha(80),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isOut ? AppColors.danger.withAlpha(50) : AppColors.primary.withAlpha(50),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 15,
                            color: isOut ? AppColors.danger : AppColors.primaryDark,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Saldo Laci Kasir:',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isOut ? AppColors.danger : AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        CurrencyFormatter.format(expectedCash),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isOut ? AppColors.danger : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        const Divider(height: 1, color: AppColors.lightBorder),

        // 3. Body Form Scrollable
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A. Input Nominal Uang
                const Text(
                  'Nominal Uang',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: controller.amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _RupiahInputFormatter(),
                  ],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Text(
                        'Rp',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: controller.amountController,
                      builder: (context, value, _) {
                        if (value.text.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                          ),
                          tooltip: 'Hapus Nominal',
                          splashRadius: 18,
                          onPressed: () {
                            controller.amountController.clear();
                          },
                        );
                      },
                    ),
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.normal),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.lightBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.lightBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Quick Amount Chips Sama Rata (4 Kolom Terbagi Rata)
                Row(
                  children: [
                    Expanded(child: _buildQuickChip('+10.000', 10000, controller)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildQuickChip('+20.000', 20000, controller)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildQuickChip('+50.000', 50000, controller)),
                    const SizedBox(width: 6),
                    Expanded(child: _buildQuickChip('+100.000', 100000, controller)),
                  ],
                ),

                const SizedBox(height: 18),

                // B. Pilihan Kategori Dropdown (Lebih Simpel & Ringkas)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() {
                      final isOut = controller.selectedType.value == 'out';
                      return Text(
                        isOut ? 'Kategori Pengeluaran Laci *' : 'Kategori Kas Masuk *',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      );
                    }),
                    Obx(() {
                      if (controller.isLoadingCategories.value) {
                        return const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
                const SizedBox(height: 6),

                Obx(() {
                  final cats = controller.categories;
                  final isOut = controller.selectedType.value == 'out';
                  final selectedId = controller.selectedCategory.value?.id;

                  if (controller.isLoadingCategories.value) {
                    return Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Memuat kategori...',
                            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  if (cats.isEmpty) {
                    return Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 8),
                          Text(
                            'Kategori default: Operasional Toko',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  final currentVal = cats.any((c) => c.id == selectedId) ? selectedId : null;
                  final activeColor = isOut ? AppColors.danger : AppColors.primary;

                  return Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: currentVal,
                        hint: Text(
                          isOut ? 'Pilih Kategori Pengeluaran...' : 'Pilih Kategori Kas Masuk...',
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                        isExpanded: true,
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        selectedItemBuilder: (context) {
                          return cats.map((cat) {
                            final iconData = _getCategoryIcon(cat.name, cat.slug);
                            return Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isOut ? AppColors.dangerSoft : AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    iconData,
                                    size: 15,
                                    color: activeColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                        items: cats.map((cat) {
                          final isItemChosen = cat.id == currentVal;
                          final iconData = _getCategoryIcon(cat.name, cat.slug);

                          return DropdownMenuItem<int>(
                            value: cat.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isItemChosen
                                        ? (isOut ? AppColors.dangerSoft : AppColors.primarySoft)
                                        : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    iconData,
                                    size: 15,
                                    color: isItemChosen ? activeColor : AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isItemChosen ? FontWeight.bold : FontWeight.w500,
                                      color: isItemChosen ? activeColor : AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isItemChosen)
                                  Icon(
                                    Icons.check_circle_rounded,
                                    size: 16,
                                    color: activeColor,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newId) {
                          if (newId != null) {
                            for (final c in cats) {
                              if (c.id == newId) {
                                controller.selectedCategory.value = c;
                                break;
                              }
                            }
                          }
                        },
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                // C. Keterangan / Keperluan (Wajib)
                const Text(
                  'Keterangan / Alasan *',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: controller.notesController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: controller.selectedType.value == 'out'
                        ? 'Contoh: Beli es batu kristal 2 karung di toko sebelah'
                        : 'Contoh: Tambah uang receh modal kembalian dari brankas',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 11.5),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.lightBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.lightBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // D. Lampiran Foto Nota & Cetak Slip Otomatis (Ukuran & Style Sama Rata Presisi 48px)
                Row(
                  children: [
                    // 1. Box Foto Bukti Nota (Tinggi 48px Presisi)
                    Expanded(
                      child: Obx(() {
                        final imageFile = controller.selectedImage.value;
                        final fileName = controller.selectedImageName.value;
                        final bool hasImage = imageFile != null;

                        return Material(
                          color: hasImage ? AppColors.primarySoft : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: controller.pickReceiptImage,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: hasImage ? AppColors.primary.withAlpha(90) : AppColors.lightBorder,
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: hasImage ? AppColors.primary.withAlpha(30) : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: hasImage
                                        ? Image.file(
                                            imageFile,
                                            width: 28,
                                            height: 28,
                                            fit: BoxFit.cover,
                                          )
                                        : const Icon(
                                            Icons.camera_alt_outlined,
                                            size: 15,
                                            color: AppColors.textSecondary,
                                          ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      hasImage ? fileName : 'Foto Bukti Nota',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: hasImage ? FontWeight.bold : FontWeight.w600,
                                        color: hasImage ? AppColors.primaryDark : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  if (hasImage)
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, color: AppColors.danger, size: 16),
                                      onPressed: controller.removeSelectedImage,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      splashRadius: 16,
                                    )
                                  else
                                    const Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 16,
                                      color: AppColors.textMuted,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(width: 8),

                    // 2. Box Cetak Slip 58mm (Tinggi 48px Presisi Sama Rata)
                    Expanded(
                      child: Obx(() {
                        final isChecked = controller.autoPrintReceipt.value;

                        return Material(
                          color: isChecked ? AppColors.primarySoft : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            onTap: () {
                              controller.autoPrintReceipt.value = !isChecked;
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              height: 48,
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isChecked ? AppColors.primary.withAlpha(90) : AppColors.lightBorder,
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isChecked ? AppColors.primary.withAlpha(30) : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: Checkbox(
                                          value: isChecked,
                                          activeColor: AppColors.primary,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          onChanged: (val) {
                                            controller.autoPrintReceipt.value = val ?? false;
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Cetak Slip 58mm',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isChecked ? FontWeight.bold : FontWeight.w600,
                                        color: isChecked ? AppColors.primaryDark : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.print_outlined,
                                    size: 16,
                                    color: isChecked ? AppColors.primary : AppColors.textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // 4. Footer Actions (PINNED)
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.lightBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: AppColors.lightBorder),
                  ),
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Obx(() {
                  final loading = controller.isSubmitting.value;
                  final isOut = controller.selectedType.value == 'out';
                  final Color btnColor = isOut ? AppColors.danger : AppColors.primary;
                  final String btnLabel = isOut ? 'Simpan Kas Keluar' : 'Simpan Kas Masuk';

                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: btnColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(isOut ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 16),
                    label: Text(
                      loading ? 'Menyimpan...' : btnLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: loading
                        ? null
                        : () async {
                            final ok = await controller.submitCashMovement();
                            if (ok && dialogContext.mounted) {
                              Navigator.of(dialogContext).pop(true);
                            }
                          },
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChip(String label, int value, CashFlowController controller) {
    return InkWell(
      onTap: () => controller.addQuickAmount(value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.lightBorder),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  static IconData _getCategoryIcon(String name, String slug) {
    final s = slug.toLowerCase();
    final n = name.toLowerCase();
    if (s.contains('bahan') || n.contains('bahan') || n.contains('darurat')) {
      return Icons.kitchen_outlined;
    }
    if (s.contains('operasional') || n.contains('operasional') || n.contains('utilitas')) {
      return Icons.inventory_2_outlined;
    }
    if (s.contains('konsumsi') || n.contains('konsumsi') || n.contains('tim') || n.contains('makan')) {
      return Icons.lunch_dining_outlined;
    }
    if (s.contains('iuran') || s.contains('sampah') || s.contains('parkir') || n.contains('sampah') || n.contains('parkir')) {
      return Icons.local_parking_rounded;
    }
    if (s.contains('perawatan') || s.contains('servis') || n.contains('servis') || n.contains('alat')) {
      return Icons.handyman_outlined;
    }
    if (s.contains('kembalian') || n.contains('kembalian') || n.contains('receh')) {
      return Icons.change_circle_outlined;
    }
    if (s.contains('setoran') || n.contains('setoran') || n.contains('modal')) {
      return Icons.savings_outlined;
    }
    return Icons.receipt_long_outlined;
  }
}

/// Formatter untuk angka ribuan dengan titik (contoh: 25.000)
class _RupiahInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    final clean = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) {
      return const TextEditingValue();
    }
    final intValue = int.tryParse(clean) ?? 0;
    final formatted = CurrencyFormatter.formatWithoutSymbol(intValue);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
