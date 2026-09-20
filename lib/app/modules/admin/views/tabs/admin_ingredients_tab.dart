import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/data/models/admin_ingredient_model.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';
import '../widgets/common/admin_load_more_footer.dart';
import '../widgets/ingredients/ingredient_metrics_strip.dart';
import '../widgets/ingredients/ingredient_filter_bar.dart';
import '../widgets/ingredients/ingredient_card.dart';
import '../widgets/ingredients/ingredient_empty_state.dart';
import '../widgets/ingredients/ingredient_dialogs.dart';
import '../widgets/ingredients/ingredient_skeleton.dart';

class AdminIngredientsTab extends GetView<AdminController> {
  const AdminIngredientsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // 1. KPI Metrics Summary Strip
          IngredientMetricsStrip(controller: controller),

          // 2. Search & Multi-Filter Bar + Actions
          IngredientFilterBar(
            controller: controller,
            onAddPressed: () => AdminIngredientFormDialog.show(context),
          ),

          // 3. Responsive Data Grid / List with Infinite Scroll
          Expanded(
            child: Obx(() {
              if (controller.isLoadingIngredients.value) {
                return const IngredientGridSkeleton();
              }

              final displayList = controller.filteredIngredients;

              return RefreshIndicator(
                color: AppColors.secondary,
                onRefresh: () => controller.fetchIngredients(showLoader: true),
                child: displayList.isEmpty
                    ? IngredientEmptyState(
                        onResetFilter: controller.clearIngredientFilters,
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final isDesktop = width >= 1150;
                          final isTablet = width >= 750;
                          final crossAxisCount = isDesktop ? 3 : 2;

                          return CustomScrollView(
                            controller: controller.ingredientScrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 20 : 16,
                                  vertical: isTablet ? 16 : 14,
                                ),
                                sliver: isTablet
                                    ? SliverGrid(
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          crossAxisSpacing: 14,
                                          mainAxisSpacing: 14,
                                          mainAxisExtent: 198,
                                        ),
                                        delegate: SliverChildBuilderDelegate(
                                          (context, i) {
                                            final ing = displayList[i];
                                            return IngredientCard(
                                              ingredient: ing,
                                              onRestock: () => AdminIngredientRestockDialog.show(
                                                context,
                                                ingredient: ing,
                                              ),
                                              onOpname: () => AdminIngredientOpnameDialog.show(
                                                context,
                                                ingredient: ing,
                                              ),
                                              onEdit: () => AdminIngredientFormDialog.show(
                                                context,
                                                ingredient: ing,
                                              ),
                                              onHistory: () => AdminIngredientMutationsDialog.show(
                                                context,
                                                ingredient: ing,
                                              ),
                                              onToggleActive: () => controller.toggleIngredientActive(ing),
                                              onArchive: () => _confirmArchive(context, ing),
                                              onRestore: () => controller.toggleArchiveIngredient(ing),
                                              onForceDelete: () => _confirmForceDelete(context, ing),
                                            );
                                          },
                                          childCount: displayList.length,
                                        ),
                                      )
                                    : SliverList.separated(
                                        itemCount: displayList.length,
                                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                                        itemBuilder: (context, i) {
                                          final ing = displayList[i];
                                          return IngredientCard(
                                            ingredient: ing,
                                            onRestock: () => AdminIngredientRestockDialog.show(
                                              context,
                                              ingredient: ing,
                                            ),
                                            onOpname: () => AdminIngredientOpnameDialog.show(
                                              context,
                                              ingredient: ing,
                                            ),
                                            onEdit: () => AdminIngredientFormDialog.show(
                                              context,
                                              ingredient: ing,
                                            ),
                                            onHistory: () => AdminIngredientMutationsDialog.show(
                                              context,
                                              ingredient: ing,
                                            ),
                                            onToggleActive: () => controller.toggleIngredientActive(ing),
                                            onArchive: () => _confirmArchive(context, ing),
                                            onRestore: () => controller.toggleArchiveIngredient(ing),
                                            onForceDelete: () => _confirmForceDelete(context, ing),
                                          );
                                        },
                                      ),
                              ),

                              // Bottom Load More Footer
                              SliverToBoxAdapter(
                                child: Obx(
                                  () => AdminLoadMoreFooter(
                                    isLoadingMore: controller.isLoadingMoreIngredients.value,
                                    hasMore: controller.hasMoreIngredients.value,
                                    itemCount: displayList.length,
                                    itemName: 'bahan baku',
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _confirmArchive(BuildContext context, AdminIngredientModel ingredient) {
    final linkedMenuCount = ingredient.productsCount;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.archive_outlined, color: Color(0xFFD97706), size: 22),
            SizedBox(width: 8),
            Text(
              'Arsipkan Bahan Baku?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Bahan baku '${ingredient.name}' akan dipindahkan ke Arsip dan disembunyikan dari daftar aktif.",
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFD97706)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      linkedMenuCount > 0
                          ? "Kaitan ke $linkedMenuCount menu resep akan otomatis diputuskan dan HPP menu dihitung ulang. Anda dapat memulihkannya kapan saja dari tab 'Terarsip'."
                          : "Bahan ini belum terikat ke menu resep mana pun. Anda dapat memulihkannya kapan saja dari tab 'Terarsip'.",
                      style: const TextStyle(fontSize: 12, color: Color(0xFF92400E), height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await controller.deleteIngredient(ingredient.id);
            },
            child: const Text('Arsipkan Bahan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmForceDelete(BuildContext context, AdminIngredientModel ingredient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.danger, size: 22),
            SizedBox(width: 8),
            Text(
              'Hapus Permanen?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Apakah Anda yakin ingin menghapus permanen '${ingredient.name}'?",
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              "PERINGATAN: Bahan baku ini beserta seluruh riwayat mutasinya akan dihapus selamanya dari database dan tidak dapat dipulihkan lagi.",
              style: TextStyle(fontSize: 12.5, color: AppColors.danger, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.of(context).pop();
              await controller.forceDeleteIngredient(ingredient.id);
            },
            child: const Text('Hapus Permanen', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
