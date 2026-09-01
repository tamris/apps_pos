import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../data/models/product_model.dart';
import '../../controllers/pos_controller.dart';

class MenuAvailabilityDialog extends StatefulWidget {
  const MenuAvailabilityDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const MenuAvailabilityDialog(),
    );
  }

  @override
  State<MenuAvailabilityDialog> createState() => _MenuAvailabilityDialogState();
}

class _MenuAvailabilityDialogState extends State<MenuAvailabilityDialog> {
  final PosController posController = Get.find<PosController>();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _selectedCatId = 0; // 0 = Semua Kategori
  String _statusFilter = 'all'; // 'all', 'active', 'inactive'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ketersediaan Menu',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Atur status menu Ready atau Habis untuk kasir',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Filter Controls (Search + Status Pills + Category Pills)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari menu berdasarkan nama atau SKU...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        filled: true,
                        fillColor: AppColors.lightBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() => _searchQuery = val.trim().toLowerCase());
                      },
                    ),
                    const SizedBox(height: 10),

                    // Status Filters (Semua, Tersedia, Habis)
                    Obx(() {
                      final total = posController.products.length;
                      final activeCount = posController.products.where((p) => p.isActive).length;
                      final inactiveCount = total - activeCount;

                      return Row(
                        children: [
                          _buildStatusTab('all', 'Semua ($total)'),
                          const SizedBox(width: 6),
                          _buildStatusTab('active', 'Tersedia ($activeCount)', color: AppColors.primary),
                          const SizedBox(width: 6),
                          _buildStatusTab('inactive', 'Habis ($inactiveCount)', color: AppColors.danger),
                        ],
                      );
                    }),
                    const SizedBox(height: 8),

                    // Category Filter Scroll
                    Obx(() {
                      if (posController.categories.isEmpty) return const SizedBox.shrink();

                      return SizedBox(
                        height: 32,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildCategoryChip(0, 'Semua Kategori'),
                            ...posController.categories.map((cat) {
                              return _buildCategoryChip(cat.id, cat.name);
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Product List with Toggle Switch
              Expanded(
                child: Obx(() {
                  var list = posController.products.toList();

                  // Filter by Search Query
                  if (_searchQuery.isNotEmpty) {
                    list = list.where((p) {
                      final name = p.name.toLowerCase();
                      final sku = p.sku?.toLowerCase() ?? '';
                      return name.contains(_searchQuery) || sku.contains(_searchQuery);
                    }).toList();
                  }

                  // Filter by Category
                  if (_selectedCatId != 0) {
                    list = list.where((p) => p.categoryId == _selectedCatId).toList();
                  }

                  // Filter by Status
                  if (_statusFilter == 'active') {
                    list = list.where((p) => p.isActive).toList();
                  } else if (_statusFilter == 'inactive') {
                    list = list.where((p) => !p.isActive).toList();
                  }

                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 44,
                            color: AppColors.textMuted.withAlpha(120),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Tidak ada menu yang sesuai',
                            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final product = list[index];
                      return _buildProductRow(product);
                    },
                  );
                }),
              ),

              // Footer Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppColors.lightBackground,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
                  border: Border(top: BorderSide(color: AppColors.lightBorder)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Perubahan status langsung tersinkronisasi ke POS.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Selesai', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductRow(ProductModel product) {
    final isAvailable = product.isActive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isAvailable ? Colors.white : AppColors.dangerSoft.withAlpha(50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvailable ? AppColors.lightBorder : AppColors.danger.withAlpha(80),
          width: isAvailable ? 1 : 1.2,
        ),
      ),
      child: Row(
        children: [
          // Image / Initial Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isAvailable ? AppColors.primarySoft : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildInitials(product.name, isAvailable),
                    ),
                  )
                : _buildInitials(product.name, isAvailable),
          ),
          const SizedBox(width: 12),

          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isAvailable ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAvailable ? AppColors.primarySoft : AppColors.dangerSoft,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isAvailable ? 'READY' : 'HABIS',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: isAvailable ? AppColors.primaryDark : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      product.categoryName,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                    const SizedBox(width: 6),
                    const Text('•', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(width: 6),
                    Text(
                      CurrencyFormatter.format(product.price),
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Toggle Switch (Ready / Habis)
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: isAvailable,
              activeThumbColor: AppColors.primary,
              activeTrackColor: AppColors.primaryLight.withAlpha(120),
              inactiveThumbColor: AppColors.danger,
              inactiveTrackColor: AppColors.dangerSoft,
              onChanged: (val) {
                posController.toggleProductAvailability(product);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(String name, bool isAvailable) {
    final clean = name.trim();
    final letter = clean.isNotEmpty ? clean.substring(0, 1).toUpperCase() : 'P';
    return Center(
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isAvailable ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildStatusTab(String status, String label, {Color color = AppColors.textPrimary}) {
    final isSelected = _statusFilter == status;
    return Expanded(
      child: Material(
        color: isSelected ? AppColors.primarySoft : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() => _statusFilter = status),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.lightBorder,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(int catId, String name) {
    final isSelected = _selectedCatId == catId;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: ActionChip(
        label: Text(
          name,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
          ),
        ),
        backgroundColor: isSelected ? AppColors.primarySoft : AppColors.lightBackground,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.lightBorder,
          width: isSelected ? 1.2 : 0.8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onPressed: () => setState(() => _selectedCatId = catId),
      ),
    );
  }
}
