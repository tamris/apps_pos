# Rencana Implementasi: Offline Mode untuk Riwayat Transaksi & Open Bills

Dokumen ini merancang arsitektur dan alur logika agar kasir kafe dapat mengelola **Riwayat Transaksi** (melihat riwayat, cek total omset, pratinjau & cetak ulang struk) dan **Open Bills / Simpan Tagihan Meja** (buka bill meja, resume bill, tambah menu, bayar bill meja) secara penuh saat **Offline (Tanpa Internet)**.

---

## 🎯 Tujuan & Kebutuhan Pengguna
1. **Riwayat Transaksi Saat Offline:**
   - Kasir dapat membuka halaman Riwayat Transaksi (`/transactions`) saat internet mati.
   - Transaksi yang dilakukan saat offline langsung tampil di daftar riwayat lengkap dengan status `[OFFLINE / MENUNGGU SINKRONISASI]`.
   - Kartu statistik omset hari ini (total omset, jumlah transaksi, uang cash) menghitung total transaksi offline secara akurat.
   - Kasir dapat menekan transaksi offline untuk melihat **Pratinjau Struk Kertas** dan **Mencetak Ulang Struk via Printer Bluetooth** tanpa memerlukan koneksi server.
2. **Open Bill (Simpan Tagihan Meja) Saat Offline:**
   - Kasir dapat memilih meja (Dine-in) lalu menekan **"Simpan Bill"** saat internet mati.
   - Bill meja tersimpan aman di penyimpanan lokal HP kasir (`Offline Open Bills Storage`).
   - Meja otomatis ditandai sebagai *Terisi (Occupied)* di halaman POS dan badge jumlah bill aktif di header bertambah.
   - Kasir dapat membuka halaman **Daftar Bill Aktif** (`/open-bills`) saat offline, melihat daftar meja yang sedang aktif, dan membuka kembali bill ke keranjang (*Resume Bill*) untuk menambah pesanan atau melakukan pembayaran (*Checkout*).
   - Saat bill meja offline dibayar, meja otomatis bebas dan transaksi masuk ke antrean sinkronisasi.

---

## 🏗️ Alur & Logika Arsitektur

### 1. Penyimpanan Lokal Baru di `StorageService`
- `_keyOfflineOpenBills`: Menyimpan daftar bill meja yang sedang aktif saat offline.
- Method:
  - `saveOfflineOpenBill(Map<String, dynamic> bill)`: Menyimpan/mengupdate open bill offline.
  - `List<Map<String, dynamic>> getOfflineOpenBills()`: Mengambil daftar open bill offline.
  - `removeOfflineOpenBill(int id)`: Menghapus open bill offline (saat dibayar atau dibatalkan).
  - `clearOfflineOpenBills()`: Menghapus semua open bill offline.

### 2. Logika Open Bill di `CartController`
- **`saveOpenBill()`**:
  - Jika koneksi online tersedia: panggil API `POST /pos/open-bills` seperti biasa.
  - Jika offline / error jaringan:
    - Buat ID sintetis lokal (misal: `-DateTime.now().millisecondsSinceEpoch % 1000000`).
    - Format payload `OpenBillModel` lengkap dengan detail menu, addons, notes, subtotal, dan total.
    - Simpan ke `_storageService.saveOfflineOpenBill()`.
    - Tandai meja sebagai terisi di `PosController` dan update counter open bills.
    - Tampilkan snackbar sukses: *"Bill Tersimpan (Offline)"*.
- **`processCheckout()`**:
  - Jika checkout berasal dari Open Bill offline (`activeOpenBillId < 0`):
    - Hapus bill tersebut dari `_storageService.removeOfflineOpenBill(activeOpenBillId)`.
    - Bebaskan meja di `PosController`.

### 3. Logika Tampilan & Interaksi di `OpenBillsController`
- **`fetchOpenBills()`**:
  - Mengambil data server (jika online) dan menggabungkan (*merge*) dengan seluruh bill offline lokal.
  - Jika offline total: langsung memuat daftar bill offline dari penyimpanan lokal.
- **`resumeBill(OpenBillModel bill)`**:
  - Jika `bill.id < 0` (bill offline): langsung panggil `CartController.loadFromOpenBill(bill, products)` tanpa memanggil API detail server.
- **`cancelBill(OpenBillModel bill)`**:
  - Jika `bill.id < 0`: langsung hapus dari `_storageService.removeOfflineOpenBill(bill.id)`, bebaskan meja, dan refresh list.

### 4. Logika Riwayat Transaksi di `TransactionsController`
- **`fetchTodayTransactions()`**:
  - Ambil antrean transaksi offline dari `_storageService.getOfflineQueue()`.
  - Konversi tiap item offline queue menjadi objek `TransactionModel` dengan detail item, nominal, tanggal, dan waktu.
  - Jika online: gabungkan transaksi server + transaksi offline di urutan teratas.
  - Jika offline: tampilkan transaksi offline dan hitung `TransactionStatsModel` lokal (omset, cash, transaksi count).
- **`printOrPreviewReceipt(int transactionId)` & `previewReceipt(int transactionId)`**:
  - Jika `transactionId < 0` (transaksi offline):
    - Susun `receiptPayload` lokal menggunakan data toko (`cafeSettings`), kasir, dan detail menu transaksi offline.
    - Tampilkan `ReceiptViewDialog.show(payload)` atau langsung cetak ke printer bluetooth jika printer terhubung.

---

## 📁 File yang Akan Diubah

### Data & Services
- [storage_service.dart](file:///d:/Antigravity/noli_apps/lib/app/data/services/storage_service.dart): Tambahkan fungsi manajemen storage untuk Open Bills Offline.
- [offline_sync_service.dart](file:///d:/Antigravity/noli_apps/lib/app/data/services/offline_sync_service.dart): Sinkronisasi open bill offline yang belum dibayar saat internet kembali aktif.

### POS & Cart
- [cart_controller.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/pos/controllers/cart_controller.dart): Dukungan simpan Open Bill offline dan pembersihan bill offline saat checkout.
- [pos_controller.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/pos/controllers/pos_controller.dart): Menghitung gabungan open bill online + offline untuk badge counter.

### Open Bills Module
- [open_bills_controller.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/open_bills/controllers/open_bills_controller.dart): Fetch, resume, dan cancel open bills secara offline.
- [open_bills_view.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/open_bills/views/open_bills_view.dart): Tampilkan badge visual `[OFFLINE]` pada kartu bill yang tersimpan secara offline.

### Transactions Module
- [transactions_controller.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/transactions/controllers/transactions_controller.dart): Dukungan memuat transaksi offline, kalkulasi stats offline, dan preview/reprint struk offline.
- [transactions_view.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/transactions/views/transactions_view.dart): Tampilkan badge `[OFFLINE]` pada transaksi yang belum tersinkronisasi.

---

## 🔍 Rencana Verifikasi
1. **Uji Transaksi Offline & Riwayat:**
   - Masuk mode offline -> lakukan 2 transaksi checkout tunai.
   - Buka menu Riwayat Transaksi (`/transactions`) -> pastikan 2 transaksi muncul, total omset terhitung, dan tap transaksi untuk pratinjau struk / cetak Bluetooth.
2. **Uji Open Bill Offline:**
   - Dalam mode offline -> pilih Meja 5 -> tambah menu -> klik **"Simpan Bill"**.
   - Periksa status Meja 5 (berubah merah/terisi).
   - Buka menu **Daftar Bill Aktif** (`/open-bills`) -> pastikan Meja 5 muncul.
   - Tap Meja 5 -> menu kembali masuk ke keranjang -> lakukan pembayaran -> Meja 5 kembali bebas.
3. **Uji Validasi Kode:**
   - Jalankan `flutter analyze` untuk memastikan 0 error dan 0 warning.
