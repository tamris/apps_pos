import 'dart:io';
import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cash_movement_model.dart';
import '../../../data/models/expense_category_model.dart';
import '../../../data/providers/api_provider.dart';
import '../../../data/services/esc_pos_printer_service.dart';
import 'shift_controller.dart';

class CashFlowController extends GetxController {
  final ApiProvider _apiProvider = Get.find<ApiProvider>();
  final ShiftController _shiftController = Get.find<ShiftController>();

  // State
  final RxString selectedType = 'out'.obs; // 'out' (Kas Keluar) or 'in' (Kas Masuk)
  final RxList<ExpenseCategoryModel> categories = <ExpenseCategoryModel>[].obs;
  final Rx<ExpenseCategoryModel?> selectedCategory = Rx<ExpenseCategoryModel?>(null);
  final RxBool isLoadingCategories = false.obs;
  final RxBool isSubmitting = false.obs;
  final RxBool autoPrintReceipt = true.obs;

  // Form Fields
  final TextEditingController amountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxString selectedImageName = ''.obs;

  // Shift Movements List (History)
  final RxList<CashMovementModel> currentMovements = <CashMovementModel>[].obs;
  final RxBool isLoadingMovements = false.obs;
  final RxDouble currentTotalIn = 0.0.obs;
  final RxDouble currentTotalOut = 0.0.obs;
  final RxDouble currentExpectedCash = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    // Inisialisasi status auto-print jika printer bluetooth terhubung
    if (Get.isRegistered<EscPosPrinterService>()) {
      autoPrintReceipt.value = Get.find<EscPosPrinterService>().isConnected.value;
    }
    fetchCategories();
  }

  /// Ganti tipe Kas Keluar (out) vs Kas Masuk (in)
  void setType(String type) {
    if (selectedType.value == type) {
      if (categories.isEmpty && !isLoadingCategories.value) {
        fetchCategories();
      }
      return;
    }
    selectedType.value = type;
    selectedCategory.value = null;
    fetchCategories();
  }

  /// Pilih kategori (bisa switch atau toggle unselect jika ditekan ulang)
  void selectCategory(ExpenseCategoryModel cat) {
    if (selectedCategory.value?.id == cat.id) {
      selectedCategory.value = null;
    } else {
      selectedCategory.value = cat;
    }
  }

  /// Ambil daftar kategori dari server sesuai tipe aktif
  Future<void> fetchCategories() async {
    isLoadingCategories.value = true;
    try {
      final response = await _apiProvider.get(
        ApiConstants.posCashFlowCategories,
        queryParameters: {'type': selectedType.value == 'out' ? 'expense' : 'cash_in'},
      );

      if (response.data != null && response.data['success'] == true) {
        final List raw = (response.data['data'] as List?) ?? [];
        final parsed = raw.map((e) => ExpenseCategoryModel.fromJson(e)).where((cat) {
          final s = cat.slug.toLowerCase();
          final n = cat.name.toLowerCase();
          if (s.contains('gaji') || n.contains('gaji') || n.contains('bonus')) return false;
          if (s.contains('sewa') || n.contains('sewa')) return false;
          if (s.contains('supplier') || n.contains('supplier') || s.contains('besar')) return false;
          return true;
        }).toList();

        categories.value = parsed;
        if (categories.isNotEmpty) {
          selectedCategory.value = categories.first;
        }
      }
    } catch (e) {
      // Non-blocking fallback jika koneksi offline
      categories.clear();
    } finally {
      isLoadingCategories.value = false;
    }
  }

  /// Tambah nominal cepat (+10k, +20k, +50k, +100k)
  void addQuickAmount(int additional) {
    final currentClean = amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final int current = int.tryParse(currentClean) ?? 0;
    final int total = current + additional;
    amountController.text = CurrencyFormatter.formatWithoutSymbol(total);
  }

  /// Set nominal langsung
  void setAmount(int value) {
    amountController.text = CurrencyFormatter.formatWithoutSymbol(value);
  }

  /// Buka FilePicker untuk memilih bukti nota / struk fisik (Kamera / Galeri Gambar)
  Future<void> pickReceiptImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        final file = File(path);

        // Validasi ukuran file maks 5MB
        final sizeInBytes = await file.length();
        if (sizeInBytes > 5 * 1024 * 1024) {
          AppSnackbar.warning('File Terlalu Besar', 'Maksimal ukuran foto bukti struk adalah 5MB.');
          return;
        }

        selectedImage.value = file;
        selectedImageName.value = result.files.single.name;
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Memilih Gambar', 'Terjadi kesalahan saat membuka galeri.');
    }
  }

  /// Hapus foto bukti yang sudah dipilih
  void removeSelectedImage() {
    selectedImage.value = null;
    selectedImageName.value = '';
  }

  /// Reset form input pencatatan kas
  void resetForm() {
    amountController.clear();
    notesController.clear();
    removeSelectedImage();
    if (categories.isNotEmpty) {
      selectedCategory.value = categories.first;
    }
  }

  /// Submit pencatatan kas keluar / masuk ke server
  Future<bool> submitCashMovement() async {
    // 1. Cek shift aktif
    if (!_shiftController.hasActiveShift.value || _shiftController.currentShift.value == null) {
      AppSnackbar.danger('Shift Belum Dibuka', 'Buka shift kasir terlebih dahulu sebelum mencatat arus kas.');
      return false;
    }

    // 2. Validasi nominal
    final cleanText = amountController.text.replaceAll('.', '').replaceAll(',', '').trim();
    final double? amount = double.tryParse(cleanText);
    if (amount == null || amount <= 0) {
      AppSnackbar.warning('Nominal Tidak Valid', 'Silakan masukkan jumlah uang yang valid.');
      return false;
    }
    if (amount < 100) {
      AppSnackbar.warning('Nominal Kurang', 'Nominal minimal pencatatan adalah Rp 100.');
      return false;
    }

    // 3. Validasi batas saldo laci jika kas keluar
    final activeShift = _shiftController.currentShift.value!;
    final isOut = selectedType.value == 'out';
    if (isOut && amount > activeShift.expectedCash) {
      final diff = amount - activeShift.expectedCash;
      final formatDiff = CurrencyFormatter.format(diff);
      final formatExpected = CurrencyFormatter.format(activeShift.expectedCash);

      final bool? proceed = await Get.dialog<bool>(
        AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('Peringatan Saldo Laci', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'Nominal pengeluaran (${CurrencyFormatter.format(amount)}) melebihi estimasi uang fisik di laci saat ini ($formatExpected).\n\nLaci kasir akan mengalami selisih minus $formatDiff. Tetap lanjutkan pencatatan?',
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Get.back(result: true),
              child: const Text('Tetap Lanjutkan'),
            ),
          ],
        ),
      );

      if (proceed != true) {
        return false;
      }
    }

    // 4. Validasi catatan/keterangan
    final notes = notesController.text.trim();
    if (notes.isEmpty) {
      AppSnackbar.warning('Keterangan Wajib', 'Mohon isi alasan / peruntukan pengeluaran atau kas masuk.');
      return false;
    }

    isSubmitting.value = true;
    try {
      final category = selectedCategory.value;

      // Siapkan payload FormData jika ada upload gambar
      final Map<String, dynamic> dataMap = {
        'type': selectedType.value,
        'amount': amount,
        'notes': notes,
        if (category != null) 'category_id': category.id,
        if (category != null) 'category_name': category.name,
      };

      dynamic payload;
      if (selectedImage.value != null) {
        final multipartFile = await dio.MultipartFile.fromFile(
          selectedImage.value!.path,
          filename: selectedImageName.value.isNotEmpty ? selectedImageName.value : 'receipt.jpg',
        );
        dataMap['receipt_image'] = multipartFile;
        payload = dio.FormData.fromMap(dataMap);
      } else {
        payload = dataMap;
      }

      final response = await _apiProvider.post(
        ApiConstants.posCashFlowStore,
        data: payload,
      );

      if (response.data != null && response.data['success'] == true) {
        final receiptPayload = response.data['receipt_payload'];

        // Update saldo laci secara lokal seketika
        _shiftController.currentShift.value = _shiftController.currentShift.value?.recordCashMovement(
          amount: amount,
          type: selectedType.value,
        );

        // Fetch shift terbaru di background
        _shiftController.fetchCurrentShift();

        // Cetak struk otomatis jika opsi aktif & printer bluetooth terhubung
        if (autoPrintReceipt.value && receiptPayload != null && Get.isRegistered<EscPosPrinterService>()) {
          final printer = Get.find<EscPosPrinterService>();
          if (printer.isConnected.value) {
            printer.printCashMovementSlip(receiptPayload);
          }
        }

        final label = isOut ? 'Kas Keluar' : 'Kas Masuk';
        AppSnackbar.success(
          '$label Berhasil Dicatat',
          '${CurrencyFormatter.format(amount)} telah dicatat ke pembukuan laci kasir.',
        );

        resetForm();
        return true;
      } else {
        final msg = response.data?['message'] ?? 'Gagal menyimpan arus kas.';
        AppSnackbar.danger('Gagal', msg.toString());
        return false;
      }
    } catch (e) {
      final err = ApiProvider.getErrorMessage(e);
      AppSnackbar.danger('Error Sistem', err);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Ambil riwayat mutasi kas pada shift aktif saat ini
  Future<void> fetchCurrentShiftMovements() async {
    isLoadingMovements.value = true;
    try {
      final response = await _apiProvider.get(ApiConstants.posCashFlowCurrent);

      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'] ?? {};
        currentTotalIn.value = (data['total_cash_in'] as num?)?.toDouble() ?? 0.0;
        currentTotalOut.value = (data['total_cash_out'] as num?)?.toDouble() ?? 0.0;
        currentExpectedCash.value = (data['expected_cash'] as num?)?.toDouble() ?? 0.0;

        final List raw = (data['movements'] as List?) ?? [];
        currentMovements.value = raw.map((e) => CashMovementModel.fromJson(e)).toList();
      }
    } catch (e) {
      currentMovements.clear();
    } finally {
      isLoadingMovements.value = false;
    }
  }

  /// Cetak ulang slip bukti kas keluar / masuk berdasarkan movement id
  Future<void> reprintMovementSlip(int movementId) async {
    if (!Get.isRegistered<EscPosPrinterService>()) return;
    final printer = Get.find<EscPosPrinterService>();
    if (!printer.isConnected.value) {
      AppSnackbar.warning('Printer Belum Terhubung', 'Hubungkan printer Bluetooth di Pengaturan.');
      return;
    }

    try {
      final response = await _apiProvider.get(ApiConstants.posCashFlowReceipt(movementId));
      if (response.data != null && response.data['success'] == true) {
        final payload = response.data['receipt_payload'];
        if (payload != null) {
          await printer.printCashMovementSlip(payload);
        }
      }
    } catch (e) {
      AppSnackbar.danger('Gagal Cetak Ulang', ApiProvider.getErrorMessage(e));
    }
  }
}
