import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import 'admin_product_form_dialog.dart';

class ProductFilterBar extends StatelessWidget {
  final AdminController controller;

  const ProductFilterBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 720;

          if (isTablet) {
            return Row(
              children: [
                // 1. Search Box
                Expanded(
                  flex: 3,
                  child: _buildSearchBox(),
                ),
                const SizedBox(width: 10),

                // 2. Category Dropdown
                _buildCategoryDropdown(),
                const SizedBox(width: 8),

                // 3. Status Filter Dropdown
                _buildStatusDropdown(),
                const SizedBox(width: 8),

                // 4. Sort Dropdown
                _buildSortDropdown(),

                // 5. Reset Filter (Conditional if any filter active)
                Obx(() {
                  final hasFilter = controller.selectedProductCategoryId.value != null ||
                      controller.selectedProductStatus.value != 'all' ||
                      controller.selectedProductSort.value != 'name';
                  if (!hasFilter) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Tooltip(
                      message: 'Reset Filter',
                      child: InkWell(
                        onTap: controller.clearProductFilters,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.filter_alt_off_outlined, size: 16, color: Color(0xFF64748B)),
                              SizedBox(width: 6),
                              Text(
                                'Reset',
                                style: TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          }

          // Mobile Layout (< 720px)
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _buildSearchBox()),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => AdminProductFormDialog.show(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 4),
                        Text('Tambah', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildCategoryDropdown(),
                    const SizedBox(width: 8),
                    _buildStatusDropdown(),
                    const SizedBox(width: 8),
                    _buildSortDropdown(),
                    Obx(() {
                      final hasFilter = controller.selectedProductCategoryId.value != null ||
                          controller.selectedProductStatus.value != 'all' ||
                          controller.selectedProductSort.value != 'name';
                      if (!hasFilter) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: InkWell(
                          onTap: controller.clearProductFilters,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.filter_alt_off_outlined, size: 16, color: Color(0xFF64748B)),
                                SizedBox(width: 5),
                                Text(
                                  'Reset',
                                  style: TextStyle(fontSize: 12.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBox() {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller.productSearchController,
        textInputAction: TextInputAction.search,
        onChanged: controller.onProductSearchChanged,
        style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Cari menu, SKU, atau barcode...',
          hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
          suffixIcon: Obx(() {
            if (controller.hasProductSearch.value) {
              return IconButton(
                icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF94A3B8)),
                onPressed: controller.clearProductSearch,
              );
            }
            return const SizedBox.shrink();
          }),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          fillColor: const Color(0xFFF8FAFC),
          filled: true,
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
            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.2),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Obx(() {
      final categories = controller.productCategories;
      final selectedId = controller.selectedProductCategoryId.value;
      final isSelected = selectedId != null;

      String getLabel() {
        if (selectedId == null) return 'Kategori: Semua';
        final match = categories.firstWhereOrNull((c) => c.id == selectedId);
        return match != null ? 'Kategori: ${match.name}' : 'Kategori: Semua';
      }

      return SizedBox(
        height: 42,
        child: PopupMenuButton<int>(
          tooltip: 'Pilih Kategori Menu',
          offset: const Offset(0, 48),
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          onSelected: (val) {
            controller.onProductCategoryFilterChanged(val == -1 ? null : val);
          },
          itemBuilder: (context) => [
            _buildMenuItem<int>(
              -1,
              'Semua Kategori',
              isSelected: selectedId == null,
            ),
            ...categories.map((c) => _buildMenuItem<int>(
                  c.id,
                  '${c.name} (${c.productsCount})',
                  isSelected: selectedId == c.id,
                )),
          ],
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getLabel(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.secondary : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isSelected ? AppColors.secondary : const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildStatusDropdown() {
    return Obx(() {
      final status = controller.selectedProductStatus.value;
      final isFiltered = status != 'all';

      String getLabel() {
        switch (status) {
          case 'active':
            return 'Status: Hanya Aktif';
          case 'inactive':
            return 'Status: Nonaktif';
          case 'archived':
            return 'Status: Arsip';
          case 'all':
          default:
            return 'Status: Semua';
        }
      }

      return SizedBox(
        height: 42,
        child: PopupMenuButton<String>(
          tooltip: 'Filter Status Produk',
          offset: const Offset(0, 48),
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          onSelected: controller.onProductStatusFilterChanged,
          itemBuilder: (context) => [
            _buildMenuItem<String>('all', 'Semua Status', isSelected: status == 'all'),
            _buildMenuItem<String>('active', 'Hanya Aktif', isSelected: status == 'active'),
            _buildMenuItem<String>('inactive', 'Nonaktif', isSelected: status == 'inactive'),
            _buildMenuItem<String>('archived', 'Arsip', isSelected: status == 'archived'),
          ],
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isFiltered ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isFiltered ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  getLabel(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isFiltered ? FontWeight.w600 : FontWeight.w500,
                    color: isFiltered ? AppColors.secondary : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isFiltered ? AppColors.secondary : const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSortDropdown() {
    return Obx(() {
      final sort = controller.selectedProductSort.value;
      final isFiltered = sort != 'name';

      String getLabel() {
        switch (sort) {
          case 'price_desc':
            return 'Urutkan: Harga Tertinggi';
          case 'price_asc':
            return 'Urutkan: Harga Terendah';
          case 'margin_desc':
            return 'Urutkan: Margin Tertinggi';
          case 'margin_asc':
            return 'Urutkan: Margin Terendah';
          case 'name':
          default:
            return 'Urutkan: Nama A-Z';
        }
      }

      return SizedBox(
        height: 42,
        child: PopupMenuButton<String>(
          tooltip: 'Urutkan Produk',
          offset: const Offset(0, 48),
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          onSelected: (val) {
            controller.selectedProductSort.value = val;
          },
          itemBuilder: (context) => [
            _buildMenuItem<String>('name', 'Nama A-Z', isSelected: sort == 'name'),
            _buildMenuItem<String>('price_desc', 'Harga Tertinggi', isSelected: sort == 'price_desc'),
            _buildMenuItem<String>('price_asc', 'Harga Terendah', isSelected: sort == 'price_asc'),
            _buildMenuItem<String>('margin_desc', 'Margin Tertinggi', isSelected: sort == 'margin_desc'),
            _buildMenuItem<String>('margin_asc', 'Margin Terendah', isSelected: sort == 'margin_asc'),
          ],
          child: Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isFiltered ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isFiltered ? const Color(0xFF818CF8) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sort_rounded,
                  size: 17,
                  color: isFiltered ? AppColors.secondary : const Color(0xFF64748B),
                ),
                const SizedBox(width: 6),
                Text(
                  getLabel(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isFiltered ? FontWeight.w600 : FontWeight.w500,
                    color: isFiltered ? AppColors.secondary : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: isFiltered ? AppColors.secondary : const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  PopupMenuItem<T> _buildMenuItem<T>(
    T value,
    String label, {
    required bool isSelected,
  }) {
    return PopupMenuItem<T>(
      value: value,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.secondary : const Color(0xFF1E293B),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 14),
            const Icon(
              Icons.check_rounded,
              size: 18,
              color: AppColors.secondary,
            ),
          ],
        ],
      ),
    );
  }
}
