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
      width: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(left: BorderSide(color: AppColors.lightBorder, width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Obx(() => Text(
                          'Pesanan Aktif (${cartController.totalItemsCount})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.danger),
                  tooltip: 'Kosongkan Keranjang',
                  onPressed: () {
                    if (!cartController.isCartEmpty) {
                      _confirmClearCart(context);
                    }
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Tipe Pesanan & Meja Card
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => TableSelectorSheet.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryLight.withAlpha(76)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.table_restaurant_rounded, size: 20, color: AppColors.primary),
                    const SizedBox(width: 10),
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
                    const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),

          // List Items
          Expanded(
            child: Obx(() {
              if (cartController.items.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.textMuted),
                      SizedBox(height: 8),
                      Text('Belum ada menu yang dipilih', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: cartController.items.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final item = cartController.items[index];
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Item: Nama Menu & Tombol Aksi (Edit & Hapus)
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
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                    if (item.customizationSummary.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.customizationSummary,
                                        style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            // Tombol Edit Customization
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 20),
                              tooltip: 'Edit Varian & Catatan',
                              onPressed: () => ProductCustomizationSheet.show(
                                context,
                                item.product,
                                existingItem: item,
                                itemIndex: index,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Tombol Hapus Langsung
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                              tooltip: 'Hapus Item',
                              onPressed: () => cartController.removeItem(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Baris Bawah: Harga Satuan, Quantity Counter, dan Subtotal
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              CurrencyFormatter.format(item.price),
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary, size: 20),
                                  onPressed: () => cartController.decreaseQuantity(index),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 20),
                                  onPressed: () => cartController.increaseQuantity(index),
                                ),
                              ],
                            ),
                            Text(
                              CurrencyFormatter.format(item.subtotal),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
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

          // Pricing Summary & Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppColors.lightBorder)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Obx(() {
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDiscountButton(context),
                      _buildTaxButton(context),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow('Subtotal', CurrencyFormatter.format(cartController.subtotal)),
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
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: cartController.isCartEmpty
                              ? null
                              : () => cartController.saveOpenBill(),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text('Simpan Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: cartController.isCartEmpty
                              ? null
                              : () => PaymentModalView.show(context),
                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.payment_rounded, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Bayar ${CurrencyFormatter.format(cartController.grandTotal)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, double fontSize = 13, Color? color}) {
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
              color: color ?? (isBold ? AppColors.textPrimary : AppColors.textSecondary),
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
      return ActionChip(
        avatar: const Icon(Icons.discount_outlined, size: 16, color: AppColors.primary),
        label: Text(currentDisc > 0 ? 'Diskon $currentDisc%' : 'Diskon'),
        backgroundColor: currentDisc > 0 ? AppColors.primarySoft : AppColors.lightBackground,
        side: BorderSide(color: currentDisc > 0 ? AppColors.primary : AppColors.lightBorder),
        onPressed: () => _showDiscountDialog(context),
      );
    });
  }

  Widget _buildTaxButton(BuildContext context) {
    final cartController = Get.find<CartController>();
    return Obx(() {
      final currentTax = cartController.taxPercent.value.toInt();
      return ActionChip(
        avatar: const Icon(Icons.receipt_long_outlined, size: 16, color: AppColors.info),
        label: Text(currentTax > 0 ? 'Pajak $currentTax%' : 'Pajak'),
        backgroundColor: currentTax > 0 ? AppColors.infoSoft : AppColors.lightBackground,
        side: BorderSide(color: currentTax > 0 ? AppColors.info : AppColors.lightBorder),
        onPressed: () => _showTaxDialog(context),
      );
    });
  }

  void _showDiscountDialog(BuildContext context) {
    final cartController = Get.find<CartController>();
    Get.dialog(
      SimpleDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Pilih Persentase Diskon', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        children: [0, 5, 10, 15, 20, 25, 50].map((d) {
          return SimpleDialogOption(
            onPressed: () {
              cartController.discountPercent.value = d.toDouble();
              Get.back();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(d == 0 ? 'Tanpa Diskon (0%)' : 'Diskon $d%', style: const TextStyle(fontSize: 14)),
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
        title: const Text('Pilih Persentase Pajak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        children: [0, 10, 11, 12].map((t) {
          return SimpleDialogOption(
            onPressed: () {
              cartController.taxPercent.value = t.toDouble();
              Get.back();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(t == 0 ? 'Tanpa Pajak (0%)' : 'Pajak PB1 ($t%)', style: const TextStyle(fontSize: 14)),
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
        title: const Text('Kosongkan Keranjang?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Seluruh item akan dihapus dari keranjang pesanan.'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
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
