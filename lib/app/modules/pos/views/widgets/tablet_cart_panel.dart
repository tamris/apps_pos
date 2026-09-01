import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../controllers/cart_controller.dart';
import 'payment_modal_view.dart';
import 'table_selector_sheet.dart';
import 'product_customization_sheet.dart';

class TabletCartPanel extends StatelessWidget {
  const TabletCartPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();

    return Container(
      width: 410,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          left: BorderSide(color: AppColors.lightBorder, width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 16,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Header Bar (Pesanan Aktif & Clear Button)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.lightBorder, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pesanan Aktif',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Obx(() => Text(
                              '${cartController.totalItemsCount} item dalam keranjang',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            )),
                      ],
                    ),
                  ],
                ),
                Obx(() {
                  if (cartController.isCartEmpty) return const SizedBox.shrink();
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _confirmClearCart(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                          SizedBox(width: 4),
                          Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Active Open Bill Alert Banner (jika sedang mengedit bill terbuka)
          Obx(() {
            if (cartController.activeOpenBillId.value == null) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning.withAlpha(150)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: AppColors.warning, size: 20),
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
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.lightBorder),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // 2. Order Type & Table Bar (Dine In / Take Away)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Material(
              color: AppColors.lightBackground,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => TableSelectorSheet.show(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.table_restaurant_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Obx(() {
                          final type = cartController.orderType.value == 'dine_in'
                              ? 'Dine In (Makan di Tempat)'
                              : cartController.orderType.value == 'take_away'
                                  ? 'Take Away (Bungkus)'
                                  : 'Delivery';
                          final table = cartController.tableNumber.value;
                          final customer = cartController.customerName.value;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                table.isNotEmpty ? 'Meja $table • $type' : type,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (customer.isNotEmpty)
                                Text(
                                  'Pelanggan: $customer',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          );
                        }),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.lightBorder),
                        ),
                        child: const Row(
                          children: [
                            Text(
                              'Ubah',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 10,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. List Item Pesanan
          Expanded(
            child: Obx(() {
              if (cartController.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.lightBackground,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.remove_shopping_cart_outlined,
                          size: 36,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Keranjang Masih Kosong',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ketuk menu di sebelah kiri untuk memesan',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                itemCount: cartController.items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = cartController.items[index];
                  final hasCustom = item.customizationSummary.isNotEmpty;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.lightBorder, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Baris Atas: Nama Produk & Subtotal
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.product.name,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              CurrencyFormatter.format(item.subtotal),
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),

                        // Baris Kustomisasi (Varian & Catatan) jika ada
                        if (hasCustom) ...[
                          const SizedBox(height: 6),
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => ProductCustomizationSheet.show(
                              context,
                              item.product,
                              existingItem: item,
                              itemIndex: index,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.tune_rounded,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      item.customizationSummary,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.edit_outlined,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),

                        // Baris Bawah: Harga Satuan & Quantity Stepper Control
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Harga Satuan + Tombol Tambah Catatan jika belum ada kustomisasi
                            Row(
                              children: [
                                Text(
                                  CurrencyFormatter.format(item.price),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (!hasCustom) ...[
                                  const SizedBox(width: 8),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(4),
                                    onTap: () => ProductCustomizationSheet.show(
                                      context,
                                      item.product,
                                      existingItem: item,
                                      itemIndex: index,
                                    ),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit_note_rounded,
                                            size: 15,
                                            color: AppColors.primary,
                                          ),
                                          SizedBox(width: 2),
                                          Text(
                                            'Catatan',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            // Quantity Stepper (Pill Container)
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.lightBackground,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.lightBorder),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Minus / Delete button
                                  InkWell(
                                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                    onTap: () => cartController.decreaseQuantity(index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      child: Icon(
                                        item.quantity == 1
                                            ? Icons.delete_outline_rounded
                                            : Icons.remove_rounded,
                                        size: 16,
                                        color: item.quantity == 1
                                            ? AppColors.danger
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  // Quantity display
                                  Container(
                                    constraints: const BoxConstraints(minWidth: 26),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  // Plus button
                                  InkWell(
                                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                    onTap: () => cartController.increaseQuantity(index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      child: const Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
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

          // 4. Pricing Summary & Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                top: BorderSide(color: AppColors.lightBorder, width: 1.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Obx(() {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Quick Action Chips: Diskon & Pajak
                  Row(
                    children: [
                      Expanded(child: _buildDiscountButton(context)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTaxButton(context)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Ringkasan Subtotal, Diskon, Pajak
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
                      'Pajak PB1 (${cartController.taxPercent.value.toInt()}%)',
                      '+${CurrencyFormatter.format(cartController.taxAmount)}',
                      color: AppColors.info,
                    ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1, color: AppColors.lightBorder),
                  ),

                  // Total Tagihan Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Tagihan',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(cartController.grandTotal),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tombol Simpan Bill & Bayar
                  Row(
                    children: [
                      // Simpan Bill
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: cartController.isCartEmpty
                              ? null
                              : () => cartController.saveOpenBill(),
                          icon: const Icon(Icons.bookmark_border_rounded, size: 16),
                          label: const Text(
                            'Simpan Bill',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Tombol Bayar
                      Expanded(
                        flex: 3,
                        child: ElevatedButton.icon(
                          onPressed: cartController.isCartEmpty
                              ? null
                              : () => PaymentModalView.show(context),
                          icon: const Icon(Icons.payments_outlined, size: 18),
                          label: Text(
                            'Bayar ${CurrencyFormatter.format(cartController.grandTotal)}',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
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
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: color ?? AppColors.textPrimary,
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
                  color: hasDisc ? AppColors.primaryDark : AppColors.textPrimary,
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
        children: [0, 5, 10, 15, 20, 25, 50].map((d) {
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
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
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.info : AppColors.textPrimary,
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle_rounded, color: AppColors.info, size: 18),
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
          'Seluruh item akan dihapus dari keranjang pesanan aktif.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              cartController.clearCart();
              Get.back();
            },
            child: const Text('Kosongkan'),
          ),
        ],
      ),
    );
  }
}
