import 'package:flutter/material.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/currency_formatter.dart';
import 'package:noli_apps/app/data/models/admin_ingredient_model.dart';
import 'ingredient_usage_dialog.dart';

class IngredientCard extends StatefulWidget {
  final AdminIngredientModel ingredient;
  final VoidCallback onRestock;
  final VoidCallback onOpname;
  final VoidCallback onEdit;
  final VoidCallback onHistory;
  final VoidCallback onDelete;

  const IngredientCard({
    super.key,
    required this.ingredient,
    required this.onRestock,
    required this.onOpname,
    required this.onEdit,
    required this.onHistory,
    required this.onDelete,
  });

  @override
  State<IngredientCard> createState() => _IngredientCardState();
}

class _IngredientCardState extends State<IngredientCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient;

    // Status styling
    final Color statusBg;
    final Color statusTextColor;
    final Color statusBorderColor;
    final String statusLabel;

    final bool isDebt = ing.isDebtStock;

    if (isDebt) {
      statusBg = const Color(0xFFFFF1F2);
      statusTextColor = const Color(0xFFE11D48);
      statusBorderColor = const Color(0xFFFDA4AF);
      statusLabel = 'Hutang Restock';
    } else if (ing.isOutOfStock) {
      statusBg = const Color(0xFFFEF2F2);
      statusTextColor = const Color(0xFFDC2626);
      statusBorderColor = const Color(0xFFFECACA);
      statusLabel = 'Stok Habis';
    } else if (ing.isLowStock) {
      statusBg = const Color(0xFFFFFBEB);
      statusTextColor = const Color(0xFFD97706);
      statusBorderColor = const Color(0xFFFDE68A);
      statusLabel = 'Menipis';
    } else {
      statusBg = const Color(0xFFECFDF5);
      statusTextColor = const Color(0xFF059669);
      statusBorderColor = const Color(0xFFA7F3D0);
      statusLabel = 'Aman';
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? AppColors.primary.withValues(alpha: 0.6)
                : (isDebt
                    ? const Color(0xFFFDA4AF)
                    : (ing.isOutOfStock
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFE2E8F0))),
            width: _isHovered ? 1.2 : 1.0,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.025),
                    blurRadius: 5,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Identity Row (Icon + Name + Category + Status Badge)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDebt
                            ? const Color(0xFFFFF1F2)
                            : (ing.isOutOfStock
                                ? const Color(0xFFFEF2F2)
                                : (ing.isLowStock
                                    ? const Color(0xFFFFFBEB)
                                    : const Color(0xFFEEF2FF))),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDebt
                            ? Icons.assignment_late_rounded
                            : Icons.inventory_2_rounded,
                        color: isDebt
                            ? const Color(0xFFE11D48)
                            : (ing.isOutOfStock
                                ? const Color(0xFFDC2626)
                                : (ing.isLowStock
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF4F46E5))),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ing.name,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                ing.category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (ing.sku.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    ing.sku,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Recipe Usage Badge (Clickable)
                    InkWell(
                      onTap: () => AdminIngredientUsageDialog.show(context, ingredient: ing),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: ing.productsCount > 0 ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: ing.productsCount > 0 ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              ing.productsCount > 0 ? Icons.restaurant_menu_rounded : Icons.link_off_rounded,
                              size: 11,
                              color: ing.productsCount > 0 ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${ing.productsCount} Menu',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: ing.productsCount > 0 ? const Color(0xFF15803D) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),

                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusBorderColor),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusTextColor,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 2. Metric Highlight Box (Stok Saat Ini & Valuasi Inventaris)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      // Sisi Kiri: Sisa Stok
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDebt ? 'Hutang Terpakai' : 'Stok Tersedia',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isDebt ? FontWeight.w700 : FontWeight.w500,
                                color: isDebt ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  ing.formattedStock,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDebt
                                        ? const Color(0xFFE11D48)
                                        : (ing.isOutOfStock
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF0F172A)),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  ing.unit,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDebt ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              isDebt
                                  ? 'Belum dicatat restock'
                                  : 'Min: ${ing.formattedMinStock} ${ing.unit}',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: isDebt ? FontWeight.w600 : FontWeight.normal,
                                color: isDebt ? const Color(0xFFE11D48) : const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Divider Vertikal
                      Container(
                        width: 1,
                        height: 32,
                        color: const Color(0xFFE2E8F0),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),

                      // Sisi Kanan: Valuasi & Harga Satuan
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nilai Inventaris',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.format(ing.totalInventoryValue),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '@ ${CurrencyFormatter.format(ing.costPerUnit)} / ${ing.unit}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 3. Action Buttons Row (Restock, Opname, More Options)
                Row(
                  children: [
                    // Tombol Restock
                    Expanded(
                      child: InkWell(
                        onTap: widget.onRestock,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDebt ? const Color(0xFFFFF1F2) : const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDebt ? const Color(0xFFFDA4AF) : const Color(0xFFC7D2FE),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 14,
                                color: isDebt ? const Color(0xFFE11D48) : const Color(0xFF4F46E5),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isDebt ? 'Restock Segera' : 'Restock',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isDebt ? const Color(0xFFE11D48) : const Color(0xFF4F46E5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Tombol Opname Fisik
                    Expanded(
                      child: InkWell(
                        onTap: widget.onOpname,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          alignment: Alignment.center,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.fact_check_outlined,
                                size: 14,
                                color: Color(0xFF334155),
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Opname',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Tombol Menu Lainnya (Edit, History, Hapus)
                    PopupMenuButton<String>(
                      tooltip: 'Pilihan lainnya',
                      offset: const Offset(0, 36),
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      color: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      onSelected: (action) {
                        switch (action) {
                          case 'attach':
                            AdminAttachIngredientDialog.show(context, ingredient: ing);
                            break;
                          case 'usage':
                            AdminIngredientUsageDialog.show(context, ingredient: ing);
                            break;
                          case 'edit':
                            widget.onEdit();
                            break;
                          case 'history':
                            widget.onHistory();
                            break;
                          case 'delete':
                            widget.onDelete();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'attach',
                          height: 36,
                          child: Row(
                            children: [
                              Icon(Icons.add_link_rounded, size: 16, color: Color(0xFF4F46E5)),
                              SizedBox(width: 8),
                              Text('Tautkan ke Menu', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5))),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'usage',
                          height: 36,
                          child: Row(
                            children: [
                              Icon(Icons.restaurant_menu_rounded, size: 16, color: Color(0xFF334155)),
                              SizedBox(width: 8),
                              Text('Lihat Menu Terkait', style: TextStyle(fontSize: 12.5)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          height: 36,
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined, size: 16, color: Color(0xFF334155)),
                              SizedBox(width: 8),
                              Text('Edit Data Bahan', style: TextStyle(fontSize: 12.5)),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'history',
                          height: 36,
                          child: Row(
                            children: [
                              Icon(Icons.history_rounded, size: 16, color: Color(0xFF334155)),
                              SizedBox(width: 8),
                              Text('Riwayat Mutasi', style: TextStyle(fontSize: 12.5)),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(height: 1),
                        const PopupMenuItem(
                          value: 'delete',
                          height: 36,
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.danger),
                              SizedBox(width: 8),
                              Text(
                                'Hapus Bahan',
                                style: TextStyle(fontSize: 12.5, color: AppColors.danger),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(
                          Icons.more_vert_rounded,
                          size: 17,
                          color: Color(0xFF64748B),
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
    );
  }
}
