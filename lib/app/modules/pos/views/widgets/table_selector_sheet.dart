import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/pos_controller.dart';
import '../../controllers/cart_controller.dart';

class TableSelectorSheet extends StatefulWidget {
  const TableSelectorSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TableSelectorSheet(),
    );
  }

  @override
  State<TableSelectorSheet> createState() => _TableSelectorSheetState();
}

class _TableSelectorSheetState extends State<TableSelectorSheet> {
  late String _selectedOrderType;
  late String _selectedTable;
  late TextEditingController _customerController;
  late TextEditingController _customTableController;

  @override
  void initState() {
    super.initState();
    final cartController = Get.find<CartController>();
    _selectedOrderType = cartController.orderType.value;
    
    final rawTable = cartController.tableNumber.value.trim();
    if (int.tryParse(rawTable) != null) {
      _selectedTable = int.parse(rawTable).toString().padLeft(2, '0');
    } else {
      _selectedTable = rawTable;
    }

    _customerController = TextEditingController(text: cartController.customerName.value);
    _customTableController = TextEditingController(text: _isCustomTable(_selectedTable) ? _selectedTable : '');
  }

  bool _isCustomTable(String tbl) {
    if (tbl.isEmpty) return false;
    final intNum = int.tryParse(tbl);
    return intNum == null || intNum < 1 || intNum > 20;
  }

  bool _isSameTable(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    final cleanA = a.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanB = b.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanA.isNotEmpty && cleanB.isNotEmpty) {
      return int.tryParse(cleanA) == int.tryParse(cleanB);
    }
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  @override
  void dispose() {
    _customerController.dispose();
    _customTableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posController = Get.find<PosController>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
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
            const SizedBox(height: 16),

            const Text(
              'Tipe Pesanan & Meja',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),

            // Order Type Selector (Dine In / Take Away / Delivery)
            Row(
              children: [
                _buildOrderTypeButton('dine_in', 'Dine In (Meja)', Icons.table_restaurant_rounded),
                const SizedBox(width: 8),
                _buildOrderTypeButton('take_away', 'Take Away', Icons.shopping_bag_outlined),
                const SizedBox(width: 8),
                _buildOrderTypeButton('delivery', 'Delivery', Icons.delivery_dining_rounded),
              ],
            ),
            const SizedBox(height: 20),

            // Bagian Pemilihan Meja (Jika Dine In)
            if (_selectedOrderType == 'dine_in') ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Nomor Meja:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  // Legenda
                  Row(
                    children: [
                      _buildLegendDot(AppColors.tableAvailable, 'Kosong'),
                      const SizedBox(width: 8),
                      _buildLegendDot(AppColors.tableOccupied, 'Terisi'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Grid Meja 01 - 20
              Builder(
                builder: (context) {
                  final occupied = posController.occupiedTables.toList();
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: 20,
                    itemBuilder: (context, index) {
                      final tableNum = (index + 1).toString().padLeft(2, '0');
                      final isOccupied = occupied.contains(tableNum) || occupied.contains('${index + 1}');
                      final isSelected = _isSameTable(_selectedTable, tableNum);

                      Color bgColor = Colors.white;
                      Color borderColor = AppColors.tableAvailable;
                      Color textColor = AppColors.textPrimary;

                      if (isSelected) {
                        bgColor = AppColors.primary;
                        borderColor = AppColors.primary;
                        textColor = Colors.white;
                      } else if (isOccupied) {
                        bgColor = AppColors.dangerSoft;
                        borderColor = AppColors.tableOccupied;
                        textColor = AppColors.tableOccupied;
                      }

                      return Material(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              if (_isSameTable(_selectedTable, tableNum)) {
                                // Jika meja yang sama diklik -> BATALKAN / CANCEL
                                _selectedTable = '';
                                _customTableController.clear();
                              } else {
                                // Jika meja berbeda diklik -> PILIH
                                _selectedTable = tableNum;
                                _customTableController.clear();
                              }
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  tableNum,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                if (isOccupied && !isSelected)
                                  const Text(
                                    'Terisi',
                                    style: TextStyle(fontSize: 9, color: AppColors.tableOccupied, fontWeight: FontWeight.bold),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 12),

              // Custom Input Meja (misal Meja VIP / Bar / Outdoor 01)
              TextField(
                controller: _customTableController,
                decoration: const InputDecoration(
                  labelText: 'Nomor/Nama Meja Kustom (Opsional)',
                  hintText: 'Misal: VIP-1, Bar-2, Lt2-05',
                  prefixIcon: Icon(Icons.meeting_room_outlined),
                ),
                onChanged: (val) {
                  setState(() {
                    _selectedTable = val.trim();
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Input Nama Pelanggan
            TextField(
              controller: _customerController,
              decoration: const InputDecoration(
                labelText: 'Nama Pelanggan (Opsional)',
                hintText: 'Misal: Kak Rian',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Simpan & Terapkan
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final cartController = Get.find<CartController>();
                  cartController.setOrderDetails(
                    type: _selectedOrderType,
                    table: _selectedOrderType == 'dine_in' ? _selectedTable.trim() : '',
                    name: _customerController.text.trim(),
                  );
                  Get.back();
                },
                child: const Text('Terapkan Pengaturan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeButton(String type, String label, IconData icon) {
    final isSelected = _selectedOrderType == type;
    return Expanded(
      child: Material(
        color: isSelected ? AppColors.primarySoft : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedOrderType = type;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.lightBorder,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
