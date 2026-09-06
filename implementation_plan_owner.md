# Implementasi Modul Admin & Owner di Flutter POS (noli_apps)

Dokumen ini merinci rencana teknis pembuatan modul **Admin / Owner Hub** pada aplikasi Flutter POS (`noli_apps`) untuk mengonsumsi 7 endpoint baru yang telah dibuat di backend Laravel (`pos-inventory`).

---

## 1. Analisis API Backend (`pos-inventory`)

Backend telah menyediakan controller `AdminApiController.php` yang diproteksi middleware `['auth:sanctum', 'admin']` dengan 7 endpoint:
1. `GET /api/admin/dashboard` - Ringkasan finansial harian, breakdown pembayaran (cash/qris/transfer), sumber pesanan (POS vs self-order), status shift kasir aktif, open bills, dan pembatalan.
2. `GET /api/admin/shifts/history` - Riwayat shift kasir dengan audit selisih kas (balanced, shortage, overage, in_progress).
3. `GET /api/admin/shifts/{id}` - Detail shift kasir beserta daftar seluruh transaksi dalam shift tersebut.
4. `GET /api/admin/transactions` - Daftar seluruh transaksi dengan filter tanggal, status, metode pembayaran, sumber pesanan, dan pencarian invoice/nama/meja.
5. `GET /api/admin/transactions/{id}` - Rincian lengkap transaksi beserta detail menu, addons, kasir, dan info pembatalan.
6. `POST /api/admin/transactions/{id}/void` - Otoritas eksklusif pembatalan (void) transaksi oleh Admin/Owner dengan input alasan pembatalan dan rekalkulasi otomatis total shift kasir.
7. `GET /api/admin/open-bills` - Pemantauan meja aktif dengan durasi elapsed minutes dan total tagihan gantung.

---

## 2. User Review Required & Design Decisions

> [!IMPORTANT]
> **Aksesibilitas Multi-Role (Owner & Kasir Bersamaan):**
> Seringkali di operasional kafe/restoran, kasir sedang menggunakan tablet POS. Jika Owner ingin memeriksa dashboard omset atau melakukan void transaksi, kita menyediakan dua alur akses:
> 1. **User Login Langsung Role Admin/Owner**: Langsung masuk ke Panel Owner tanpa hambatan.
> 2. **Kasir Sedang Login**: Ketika kasir/owner menekan "Panel Owner" di menu POS atau Settings, muncul dialog **PIN Keamanan Admin (6-digit)**. Jika PIN admin valid, sesi Admin aktif seketika tanpa perlu menutup (logout) shift kasir yang sedang berjalan.

---

## 3. Proposed Changes

### Layer Model Data (`lib/app/data/models/`)

#### [NEW] [admin_dashboard_model.dart](file:///d:/Antigravity/noli_apps/lib/app/data/models/admin_dashboard_model.dart)
- Model representasi `AdminDashboardModel`:
  - `date`, `summary` (`totalRevenue`, `totalTransactions`, `averagePerTransaction`)
  - `paymentBreakdown` (Cash, QRIS, Transfer)
  - `orderSourceBreakdown` (POS vs Online Order)
  - `orderTypeBreakdown` (Dine-in vs Takeaway)
  - `activeShift` (nama kasir, jam mulai, modal awal, penjualan tunai, estimasi laci)
  - `openBillsSummary` (jumlah meja & potensi omset)
  - `cancellationsSummary` (jumlah void & total nominal dibatalkan)

#### [NEW] [admin_shift_model.dart](file:///d:/Antigravity/noli_apps/lib/app/data/models/admin_shift_model.dart)
- Model `AdminShiftModel` & `AdminShiftDetailModel`:
  - Detail shift lengkap, kasir bertugas, waktu mulai & selesai.
  - Audit laci: `startingCash`, `cashSales`, `expectedCash`, `actualCash`, `difference`.
  - Discrepancy badge: `balanced` (sesuai/hijau), `shortage` (kurang/merah), `overage` (lebih/kuning), `in_progress` (berjalan/biru).
  - List transaksi per shift.

#### [NEW] [admin_transaction_model.dart](file:///d:/Antigravity/noli_apps/lib/app/data/models/admin_transaction_model.dart)
- Model transaksi admin dengan dukungan audit pembatalan:
  - Header data (invoice, meja, customer, order type, payment).
  - List detail item & addons.
  - `cancelledInfo` (`cancelledAt`, `cancelledReason`, `cancelledBy`).

#### [NEW] [admin_open_bill_model.dart](file:///d:/Antigravity/noli_apps/lib/app/data/models/admin_open_bill_model.dart)
- Model representasi meja gantung untuk owner:
  - `tableNumber`, `customerName`, `total`, `itemsCount`, `elapsedMinutes`, `cashierName`.

#### [MODIFY] [user_model.dart](file:///d:/Antigravity/noli_apps/lib/app/data/models/user_model.dart)
- Update getter role:
  - `isAdmin => role.toLowerCase() == 'admin' || role.toLowerCase() == 'owner'`
  - `isOwner => role.toLowerCase() == 'owner'`

---

### Layer Konstanta API (`lib/app/core/constants/`)

#### [MODIFY] [api_constants.dart](file:///d:/Antigravity/noli_apps/lib/app/core/constants/api_constants.dart)
- Tambahkan rute endpoint admin:
  - `adminDashboard({String? date})`
  - `adminShiftHistory({String? status, String? date, int? limit})`
  - `adminShiftDetail(int id)`
  - `adminTransactions({String? status, String? date, String? paymentMethod, String? orderSource, String? search, int? perPage})`
  - `adminTransactionDetail(int id)`
  - `adminVoidTransaction(int id)`
  - `adminOpenBills`

---

### Layer Modul Admin (`lib/app/modules/admin/`)

#### [NEW] [admin_controller.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/admin/controllers/admin_controller.dart)
- Controller utama GetX mengelola 4 tab utama:
  1. **Tab Dashboard Finansial**:
     - Pilihan tanggal (Hari Ini, Kemarin, Pilih Kalender kustom).
     - Fetch data dashboard via `_apiProvider.get(ApiConstants.adminDashboard)`.
     - Loading, pull-to-refresh, error handling.
  2. **Tab Transaksi & Otoritas Void**:
     - Fetch transaksi dengan filter status (`completed`, `pending`, `cancelled`, `all`).
     - Filter sumber order (POS / Online) dan pencarian text.
     - Detail dialog dengan rincian item & addons.
     - **Void Action**: Menampilkan dialog input alasan pembatalan (min 3 huruf), memanggil `POST /api/admin/transactions/{id}/void`. Berhasil void langsung otomatis me-refresh data transaksi dan dashboard.
  3. **Tab Audit Shift & Z-Report**:
     - Fetch riwayat shift kasir.
     - Filter status (Semua, Selesai, Berjalan) dan tanggal.
     - Tampilan visual selisih kas (discrepancy badge & card selisih).
     - Dialog detail transaksi yang terjadi pada shift tersebut.
  4. **Tab Monitoring Open Bills**:
     - Fetch tagihan meja aktif & elapsed time (berapa lama meja nongkrong).
     - Ringkasan total meja terisi & total piutang berjalan.

#### [NEW] [admin_binding.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/admin/bindings/admin_binding.dart)
- Inisialisasi dependency injection `AdminController`.

#### [NEW] [admin_view.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/admin/views/admin_view.dart)
- View Scaffold modern dengan AppBar bertema Admin, status koneksi, tombol refresh, dan BottomNavigationBar / NavigationRail (responsif tablet & mobile).
- 4 Tab views terstruktur:
  - `AdminDashboardTabView`
  - `AdminTransactionsTabView`
  - `AdminShiftsTabView`
  - `AdminOpenBillsTabView`

#### [NEW] Dialog & Widget Pendukung:
- `admin_pin_dialog.dart`: Dialog input PIN 6-digit untuk verifikasi otoritas Admin/Owner saat diakses dari akun kasir.
- `admin_void_dialog.dart`: Dialog konfirmasi void dengan input alasan pembatalan.
- `admin_shift_detail_dialog.dart`: Dialog rincian audit shift & daftar transaksi shift.

---

### Layer Navigasi & Integrasi Menu

#### [MODIFY] [app_routes.dart](file:///d:/Antigravity/noli_apps/lib/app/routes/app_routes.dart)
- Daftarkan konstanta route: `static const admin = '/admin';`

#### [MODIFY] [app_pages.dart](file:///d:/Antigravity/noli_apps/lib/app/routes/app_pages.dart)
- Daftarkan `GetPage(name: AppRoutes.admin, page: () => const AdminView(), binding: AdminBinding())`.

#### [MODIFY] [pos_view.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/pos/views/pos_view.dart)
- Di AppBar POS: Tambahkan tombol ikon/badge "Panel Owner / Admin" (dengan proteksi PIN jika role kasir).
- Di Popup Menu POS: Tambahkan menu "Panel Owner & Admin" dengan ikon dashboard/shield bernuansa emas/emerald.

#### [MODIFY] [settings_view.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/settings/views/settings_view.dart)
- Di bagian profil pengguna: Tambahkan banner / tombol "Buka Panel Owner & Admin" untuk navigasi cepat.

---

## 4. Verification Plan

### Automated Tests & Static Analysis
1. `flutter analyze`
   - Memastikan tidak ada compile error, lint warning, atau import rusak di seluruh proyek `noli_apps`.
2. Syntax check backend `pos-inventory`:
   - `php -l app/Http/Controllers/Api/AdminApiController.php`
   - `php artisan route:list --path=api/admin`

### Manual Verification
1. **Verifikasi Dashboard Tab**:
   - Membuka Panel Admin, memastikan kartu omset, transaksi, breakdown cash/qris/transfer, dan shift kasir aktif muncul dengan angka yang akurat.
2. **Verifikasi Otoritas Void Transaksi**:
   - Buka tab Transaksi, pilih salah satu transaksi selesai.
   - Klik "Batalkan Transaksi (Void)", masukkan alasan "Pelanggan salah pesan", klik Konfirmasi.
   - Verifikasi status transaksi berubah menjadi `cancelled`, badge merah muncul, dan shift kasir menghitung ulang total secara otomatis.
3. **Verifikasi Audit Shift & Z-Report**:
   - Buka tab Audit Shift, periksa list riwayat shift kasir dengan indikator status seimbang / selisih minus / lebih.
   - Klik salah satu shift untuk melihat dialog rincian transaksi per shift.
4. **Verifikasi Monitoring Open Bills**:
   - Buka tab Meja Aktif, pastikan daftar open bills tampil dengan elapsed time (menit) dan nominal tagihan.
