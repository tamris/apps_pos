import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

class IngredientFilterBar extends StatelessWidget {
  final AdminController controller;
  final VoidCallback onAddPressed;

  const IngredientFilterBar({
    super.key,
    required this.controller,
    required this.onAddPressed,
  });

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

                // 2. Status Filter Dropdown
                _buildStatusDropdown(),
                const SizedBox(width: 8),

                // 3. Sort Filter Dropdown
                _buildSortDropdown(),

                // 4. Reset Button
                Obx(() {
                  final hasFilter = controller.selectedIngredientStatus.value != 'all' ||
                      controller.selectedIngredientSort.value != 'name' ||
                      controller.hasIngredientSearch.value;

                  if (!hasFilter) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Tooltip(
                      message: 'Reset Filter',
                      child: InkWell(
                        onTap: controller.clearIngredientFilters,
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.filter_alt_off_outlined, size: 15, color: Color(0xFF64748B)),
                              SizedBox(width: 5),
                              Text(
                                'Reset',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF475569),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(width: 10),

                // 5. Action Button: Tambah Bahan
                ElevatedButton.icon(
                  onPressed: onAddPressed,
                  icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                  label: const Text(
                    'Tambah Bahan',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
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
                    onPressed: onAddPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, size: 18, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Tambah',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildStatusDropdown(),
                    const SizedBox(width: 8),
                    _buildSortDropdown(),
                    Obx(() {
                      final hasFilter = controller.selectedIngredientStatus.value != 'all' ||
                          controller.selectedIngredientSort.value != 'name' ||
                          controller.hasIngredientSearch.value;

                      if (!hasFilter) return const SizedBox.shrink();

                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: InkWell(
                          onTap: controller.clearIngredientFilters,
                          borderRadius: BorderRadius.circular(9),
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.filter_alt_off_outlined, size: 15, color: Color(0xFF64748B)),
                                SizedBox(width: 4),
                                Text(
                                  'Reset',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF475569),
                                    fontWeight: FontWeight.w600,
                                  ),
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
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller.ingredientSearchController,
        onChanged: controller.onIngredientSearchChanged,
        style: const TextStyle(fontSize: 12.5, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Cari bahan baku atau SKU...',
          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
          suffixIcon: Obx(() {
            if (controller.hasIngredientSearch.value) {
              return IconButton(
                icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF64748B)),
                onPressed: controller.clearIngredientSearch,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              );
            }
            return const SizedBox.shrink();
          }),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 9),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Obx(() {
      final status = controller.selectedIngredientStatus.value;
      final isFiltered = status != 'all';

      String getLabel() {
        switch (status) {
          case 'safe':
            return 'Status: Stok Aman';
          case 'low_stock':
            return 'Status: Stok Menipis';
          case 'out_of_stock':
            return 'Status: Stok Habis';
          case 'all':
          default:
            return 'Status: Semua';
        }
      }

      return SizedBox(
        height: 38,
        child: PopupMenuButton<String>(
          tooltip: 'Filter Status Stok',
          offset: const Offset(0, 44),
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          onSelected: (val) {
            controller.selectedIngredientStatus.value = val;
            controller.fetchIngredients(showLoader: false);
          },
          itemBuilder: (context) => [
            _buildMenuItem('all', 'Semua Status', isSelected: status == 'all'),
            _buildMenuItem('safe', 'Stok Aman', isSelected: status == 'safe'),
            _buildMenuItem('low_stock', 'Stok Menipis', isSelected: status == 'low_stock'),
            _buildMenuItem('out_of_stock', 'Stok Habis', isSelected: status == 'out_of_stock'),
          ],
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isFiltered ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(9),
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
                    fontSize: 12,
                    fontWeight: isFiltered ? FontWeight.w600 : FontWeight.w500,
                    color: isFiltered ? AppColors.secondary : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
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
      final sort = controller.selectedIngredientSort.value;
      final isFiltered = sort != 'name';

      String getLabel() {
        switch (sort) {
          case 'stock_asc':
            return 'Urut: Stok Terendah';
          case 'stock_desc':
            return 'Urut: Stok Tertinggi';
          case 'value_desc':
            return 'Urut: Valuasi Tertinggi';
          case 'name':
          default:
            return 'Urut: Nama (A-Z)';
        }
      }

      return SizedBox(
        height: 38,
        child: PopupMenuButton<String>(
          tooltip: 'Urutkan Bahan',
          offset: const Offset(0, 44),
          elevation: 3,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          onSelected: (val) {
            controller.selectedIngredientSort.value = val;
            controller.fetchIngredients(showLoader: false);
          },
          itemBuilder: (context) => [
            _buildMenuItem('name', 'Nama (A-Z)', isSelected: sort == 'name'),
            _buildMenuItem('stock_asc', 'Stok Terendah', isSelected: sort == 'stock_asc'),
            _buildMenuItem('stock_desc', 'Stok Tertinggi', isSelected: sort == 'stock_desc'),
            _buildMenuItem('value_desc', 'Valuasi Tertinggi', isSelected: sort == 'value_desc'),
          ],
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isFiltered ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(9),
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
                    fontSize: 12,
                    fontWeight: isFiltered ? FontWeight.w600 : FontWeight.w500,
                    color: isFiltered ? AppColors.secondary : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: isFiltered ? AppColors.secondary : const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    String label, {
    required bool isSelected,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.secondary : const Color(0xFF1E293B),
            ),
          ),
          if (isSelected)
            const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppColors.secondary,
            ),
        ],
      ),
    );
  }
}
