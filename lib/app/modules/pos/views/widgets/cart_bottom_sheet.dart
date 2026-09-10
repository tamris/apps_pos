import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../controllers/cart_controller.dart';
import 'payment_modal_view.dart';
import 'table_selector_sheet.dart';
import 'product_customization_sheet.dart';

class CartBottomSheet extends StatelessWidget {
  const CartBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CartBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
            child: Column(
              children: [
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Obx(
                          () => Text(
                            'Keranjang Pesanan (${cartController.totalItemsCount})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_sweep_outlined,
                        color: AppColors.danger,
                      ),
                      tooltip: 'Kosongkan Keranjang',
                      onPressed: () {
                        if (!cartController.isCartEmpty) {
                          HapticFeedback.mediumImpact();
                          _confirmClearCart(context);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Active Open Bill Banner (jika sedang mengedit bill terbuka)
          Obx(() {
            if (cartController.activeOpenBillId.value == null)
              return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withAlpha(150)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bill #${cartController.activeOpenBillId.value} Aktif (Sedang Diedit)',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      cartController.activeOpenBillId.value = null;
                      cartController.clearCart();
                      if (context.mounted && Navigator.canPop(context)) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Order Type / Table Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                HapticFeedback.selectionClick();
                TableSelectorSheet.show(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryLight.withAlpha(76),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.table_restaurant_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Obx(() {
                        final type = cartController.orderType.value == 'dine_in'
                            ? 'Dine In'
                            : cartController.orderType.value == 'take_away'
                            ? 'Take Away'
                            : 'Delivery';
                        final table = cartController.tableNumber.value;
                        final customer = cartController.customerName.value;

                        String desc = type;
                        if (table.isNotEmpty) desc += ' • Meja $table';
                        if (customer.isNotEmpty) desc += ' ($customer)';

                        return Text(
                          desc,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        );
                      }),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Cart Items List
          Expanded(
            child: Obx(() {
              if (cartController.items.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.remove_shopping_cart_outlined,
                        size: 50,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Keranjang masih kosong',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: cartController.items.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final item = cartController.items[index];
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Item: Nama Menu & Tombol Aksi
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => ProductCustomizationSheet.show(
                                  context,
                                  item.product,
                                  existingItem: item,
                                  itemIndex: index,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (item
                                        .customizationSummary
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.customizationSummary,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.edit_note_rounded,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              tooltip: 'Edit Varian & Catatan',
                              onPressed: () => ProductCustomizationSheet.show(
                                context,
                                item.product,
                                existingItem: item,
                                itemIndex: index,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.danger,
                                size: 20,
                              ),
                              tooltip: 'Hapus Item',
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                cartController.removeItem(index);
                                if (cartController.isCartEmpty &&
                                    context.mounted &&
                                    Navigator.canPop(context)) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Baris Bawah: Harga, Counter, Subtotal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              CurrencyFormatter.format(item.price),
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: AppColors.textSecondary,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    if (item.quantity == 1) {
                                      HapticFeedback.mediumImpact();
                                    } else {
                                      HapticFeedback.lightImpact();
                                    }
                                    cartController.decreaseQuantity(index);
                                    if (cartController.isCartEmpty &&
                                        context.mounted &&
                                        Navigator.canPop(context)) {
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                  ),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    cartController.increaseQuantity(index);
                                  },
                                ),
                              ],
                            ),
                            Text(
                              CurrencyFormatter.format(item.subtotal),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),

          // Bottom Pricing Summary & Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Obx(() {
              return Column(
                children: [
                  // Diskon & Pajak controls (Rapi 50% - 50%)
                  Row(
                    children: [
                      Expanded(child: _buildDiscountButton(context)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTaxButton(context)),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Pricing rows
                  _buildSummaryRow(
                    'Subtotal',
                    CurrencyFormatter.format(cartController.subtotal),
                  ),
                  if (cartController.discountAmount > 0)
                    _buildSummaryRow(
                      'Diskon (${cartController.discountPercent.value.toInt()}%)',
                      '-${CurrencyFormatter.format(cartController.discountAmount)}',
                      color: AppColors.danger,
                    ),
                  if (cartController.taxAmount > 0)
                    _buildSummaryRow(
                      'Pajak (${cartController.taxPercent.value.toInt()}%)',
                      '+${CurrencyFormatter.format(cartController.taxAmount)}',
                      color: AppColors.info,
                    ),
                  const Divider(height: 12),
                  _buildSummaryRow(
                    'Total Tagihan',
                    CurrencyFormatter.format(cartController.grandTotal),
                    isBold: true,
                    fontSize: 17,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),

                  // Action Buttons
                  Row(
                    children: [
                      // Simpan / Hold Order
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: cartController.isCartEmpty
                              ? null
                              : () async {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context).pop();
                                  await cartController.saveOpenBill(
                                    context: context,
                                  );
                                },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Simpan Bill',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bayar Sekarang
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: cartController.isCartEmpty
                              ? null
                              : () {
                                  HapticFeedback.lightImpact();
                                  Navigator.of(context).pop();
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    if (Get.context != null) {
                                      PaymentModalView.show(Get.context!);
                                    }
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payment_rounded, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Bayar ${CurrencyFormatter.format(cartController.grandTotal)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 13,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color:
                  color ??
                  (isBold ? AppColors.textPrimary : AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountButton(BuildContext context) {
    final cartController = Get.find<CartController>();
    return Obx(() {
      final currentDisc = cartController.discountPercent.value.toInt();
      final hasDisc = currentDisc > 0;

      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showDiscountDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: hasDisc ? AppColors.primarySoft : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasDisc ? AppColors.primary : AppColors.lightBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.discount_outlined,
                size: 15,
                color: hasDisc ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                hasDisc ? 'Diskon $currentDisc%' : 'Diskon',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hasDisc
                      ? AppColors.primaryDark
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTaxButton(BuildContext context) {
    final cartController = Get.find<CartController>();
    return Obx(() {
      final currentTax = cartController.taxPercent.value.toInt();
      final hasTax = currentTax > 0;

      return InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showTaxDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: hasTax ? AppColors.infoSoft : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasTax ? AppColors.info : AppColors.lightBorder,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 15,
                color: hasTax ? AppColors.info : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                hasTax ? 'PB1 $currentTax%' : 'Pajak PB1',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hasTax ? AppColors.info : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showDiscountDialog(BuildContext context) {
    final cartController = Get.find<CartController>();
    Get.dialog(
      SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Pilih Diskon Pesanan',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        children: [0, 5, 10, 15, 20, 25, 50, 100].map((d) {
          final isSelected = cartController.discountPercent.value.toInt() == d;
          return SimpleDialogOption(
            onPressed: () {
              cartController.discountPercent.value = d.toDouble();
              Get.back();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    d == 0 ? 'Tanpa Diskon (0%)' : 'Diskon $d%',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.primaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showTaxDialog(BuildContext context) {
    final cartController = Get.find<CartController>();
    Get.dialog(
      SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Pilih Pajak Resto (PB1)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        children: [0, 10, 11, 12].map((t) {
          final isSelected = cartController.taxPercent.value.toInt() == t;
          return SimpleDialogOption(
            onPressed: () {
              cartController.taxPercent.value = t.toDouble();
              Get.back();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.infoSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    t == 0 ? 'Tanpa Pajak (0%)' : 'Pajak Resto PB1 ($t%)',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected
                          ? AppColors.info
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.info,
                      size: 18,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _confirmClearCart(BuildContext context) {
    final cartController = Get.find<CartController>();
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Kosongkan Keranjang?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Seluruh item yang telah dipilih akan dihapus dari keranjang pesanan.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              cartController.clearCart();
              Get.back(); // Tutup dialog konfirmasi
              if (context.mounted && Navigator.canPop(context)) {
                Navigator.of(
                  context,
                ).pop(); // Tutup bottom sheet keranjang agar meluncur turun ke bawah
              }
            },
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
  }
}
