import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:noli_apps/app/core/theme/app_colors.dart';
import 'package:noli_apps/app/core/utils/app_snackbar.dart';
import 'package:noli_apps/app/data/models/expense_category_model.dart';
import 'package:noli_apps/app/modules/admin/controllers/admin_controller.dart';

class AdminManageCategoriesDialog {
  static Future<void> show(BuildContext context) async {
    final isTablet = MediaQuery.of(context).size.width >= 768;

    if (isTablet) {
      await showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          elevation: 12,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
            child: _ManageCategoriesContent(dialogContext: dialogContext),
          ),
        ),
      );
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.90,
          ),
          child: _ManageCategoriesContent(dialogContext: sheetContext),
        ),
      );
    }
  }
}

class _ManageCategoriesContent extends StatefulWidget {
  final BuildContext dialogContext;

  const _ManageCategoriesContent({required this.dialogContext});

  @override
  State<_ManageCategoriesContent> createState() => _ManageCategoriesContentState();
}

class _ManageCategoriesContentState extends State<_ManageCategoriesContent> {
  final AdminController controller = Get.find<AdminController>();

  bool _isCreating = false;
  ExpenseCategoryModel? _editingCategory;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedType = 'expense'; // 'expense', 'cash_in', 'both'
  bool _isActive = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    controller.fetchAdminExpenseCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _openCreateForm() {
    setState(() {
      _isCreating = true;
      _editingCategory = null;
      _nameController.clear();
      _descController.clear();
      _selectedType = 'expense';
      _isActive = true;
    });
  }

  void _openEditForm(ExpenseCategoryModel cat) {
    setState(() {
      _isCreating = false;
      _editingCategory = cat;
      _nameController.text = cat.name;
      _descController.text = cat.description ?? '';
      _selectedType = cat.type;
      _isActive = cat.isActive;
    });
  }

  void _cancelForm() {
    setState(() {
      _isCreating = false;
      _editingCategory = null;
      _nameController.clear();
      _descController.clear();
    });
  }

  Future<void> _saveForm() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      AppSnackbar.warning('Nama Diperlukan', 'Silakan masukkan nama kategori.');
      return;
    }

    setState(() => _isSaving = true);
    final success = await controller.saveExpenseCategory(
      id: _editingCategory?.id,
      name: name,
      type: _selectedType,
      description: _descController.text.trim(),
      isActive: _isActive,
    );
    setState(() => _isSaving = false);

    if (success) {
      _cancelForm();
    }
  }

  Future<void> _confirmDelete(ExpenseCategoryModel cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Kategori "${cat.name}"?'),
        content: Text(
          cat.cashMovementsCount > 0
              ? 'Kategori ini telah digunakan dalam ${cat.cashMovementsCount} catatan arus kas. Tetap ingin menghapusnya?'
              : 'Kategori ini akan dihapus dari daftar master kategori pengeluaran.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await controller.deleteExpenseCategory(cat.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Header (Pinned)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondarySoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.category_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Kelola Master Kategori Arus Kas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Atur pos kategori beban dan kas masuk untuk toko & kasir',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Tutup',
                icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                onPressed: () => Navigator.of(widget.dialogContext).pop(),
              ),
            ],
          ),
        ),

        // 2. Body Area
        Flexible(
          child: _isCreating || _editingCategory != null
              ? _buildCategoryForm()
              : _buildCategoryList(),
        ),

        // 3. Footer (Pinned)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (!_isCreating && _editingCategory == null) ...[
                TextButton.icon(
                  onPressed: () => controller.fetchAdminExpenseCategories(),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Segarkan', style: TextStyle(fontSize: 12.5)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: _openCreateForm,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Tambah Kategori', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                OutlinedButton(
                  onPressed: _cancelForm,
                  child: const Text('Kembali ke Daftar', style: TextStyle(fontSize: 12.5)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: _isSaving ? null : _saveForm,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Kategori', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryList() {
    return Obx(() {
      if (controller.isLoadingAdminCategories.value && controller.adminExpenseCategories.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final categories = controller.adminExpenseCategories;
      if (categories.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.category_outlined, size: 40, color: Color(0xFF94A3B8)),
              const SizedBox(height: 10),
              const Text('Belum ada master kategori', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _openCreateForm,
                child: const Text('Buat Kategori Pertama'),
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final cat = categories[i];
          final isExpense = cat.isExpense;
          final isCashIn = cat.isCashIn;

          String typeLabel = 'Beban Pengeluaran';
          Color typeColor = const Color(0xFFDC2626);
          Color typeBg = const Color(0xFFFEF2F2);

          if (isExpense && isCashIn) {
            typeLabel = 'Beban & Kas Masuk';
            typeColor = AppColors.secondary;
            typeBg = AppColors.secondarySoft;
          } else if (isCashIn) {
            typeLabel = 'Kas Masuk';
            typeColor = const Color(0xFF059669);
            typeBg = const Color(0xFFECFDF5);
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            cat.name,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          if (cat.isDefault) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Default Sistem',
                                style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: typeBg,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              typeLabel,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: typeColor),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${cat.cashMovementsCount} Transaksi',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit Kategori',
                  icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                  onPressed: () => _openEditForm(cat),
                ),
                if (!cat.isDefault) ...[
                  IconButton(
                    tooltip: 'Hapus Kategori',
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                    onPressed: () => _confirmDelete(cat),
                  ),
                ] else ...[
                  const Tooltip(
                    message: 'Kategori bawaan sistem tidak dapat dihapus',
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFFCBD5E1)),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildCategoryForm() {
    final isEditing = _editingCategory != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditing ? 'Edit Kategori "${_editingCategory!.name}"' : 'Tambah Kategori Baru',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 14),

          // Nama
          const Text('Nama Kategori', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Misal: Beban Logistik, Listrik & Air...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 14),

          // Tipe
          const Text('Tipe Transaksi Kategori', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildFormTypeRadio('Beban (Expense)', 'expense'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFormTypeRadio('Kas Masuk (In)', 'cash_in'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFormTypeRadio('Keduanya', 'both'),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Deskripsi
          const Text('Deskripsi (Opsional)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descController,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Keterangan pos pengeluaran...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 14),

          // Status Aktif Switch
          SwitchListTile(
            title: const Text('Status Aktif', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('Kategori yang aktif dapat dipilih saat mencatat arus kas', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            value: _isActive,
            activeThumbColor: AppColors.secondary,
            onChanged: (val) => setState(() => _isActive = val),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildFormTypeRadio(String label, String value) {
    final isSelected = _selectedType == value;
    return Material(
      color: isSelected ? AppColors.secondarySoft : const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _selectedType = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.secondary : const Color(0xFFE2E8F0),
              width: isSelected ? 1.4 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? AppColors.secondary : const Color(0xFF475569),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
