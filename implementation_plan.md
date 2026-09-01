# Rencana Implementasi Migrasi POS Kasir Mobile & Tablet (Flutter)

Implementasi aplikasi kasir Point of Sale (POS) berbasis Flutter (Android/iOS/Tablet/Desktop) yang terintegrasi penuh dengan backend Laravel (`pos-inventory`). Aplikasi dirancang dengan arsitektur GetX yang modular, responsif (Phone Portrait & Tablet Split Screen), memiliki dukungan offline-first (antrean transaksi offline & auto-sync), shift kasir, open bill / hold order meja, serta cetak struk thermal 58mm ESC/POS.

---

## Arsitektur & Struktur Direktori

Mengikuti struktur GetX Clean Architecture yang telah dispesifikasikan:

```
lib/
├── app/
│   ├── core/                           # Utility global, Tema, dan Konstanta
│   │   ├── constants/
│   │   │   └── api_constants.dart      # URL endpoint API & Base URL config
│   │   ├── theme/
│   │   │   ├── app_colors.dart         # Warna modern (Emerald, Slate, Amber, Rose)
│   │   │   └── app_theme.dart          # ThemeData Material3 & Google Fonts
│   │   └── utils/
│   │       ├── currency_formatter.dart # Format Rupiah (Rp xx.xxx)
│   │       └── date_formatter.dart     # Format Tanggal & Jam Indonesia
│   │
│   ├── data/                           # Data Layer (Model, Provider, Service)
│   │   ├── models/
│   │   │   ├── user_model.dart         # Data Kasir / Admin
│   │   │   ├── category_model.dart     # Kategori menu
│   │   │   ├── product_model.dart      # Menu produk, harga, image, dll
│   │   │   ├── cart_item_model.dart    # Item keranjang & custom gula/es/notes
│   │   │   ├── shift_model.dart        # Shift kasir, modal, selisih kas
│   │   │   ├── open_bill_model.dart    # Open bill meja / hold order
│   │   │   ├── transaction_model.dart  # Riwayat transaksi
│   │   │   └── cafe_settings_model.dart# Nama cafe, logo, wifi, paper width
│   │   ├── providers/
│   │   │   └── api_provider.dart       # Dio HTTP Client dengan Interceptor & Auth Token
│   │   └── services/
│   │       ├── storage_service.dart    # SharedPreferences untuk Token, Cache, Settings
│   │       ├── offline_sync_service.dart # Antrean & sinkronisasi transaksi offline
│   │       └── esc_pos_printer_service.dart # Generator struk 58mm ESC/POS & Bluetooth Print
│   │
│   ├── modules/                        # Presentation Layer per Fitur
│   │   ├── auth/                       # 1. Modul Login PIN 6-Digit
│   │   │   ├── bindings/auth_binding.dart
│   │   │   ├── controllers/auth_controller.dart
│   │   │   └── views/pin_login_view.dart
│   │   │
│   │   ├── pos/                        # 2. Modul Utama Kasir (POS)
│   │   │   ├── bindings/pos_binding.dart
│   │   │   ├── controllers/
│   │   │   │   ├── pos_controller.dart  # Katalog, kategori, cari menu, bootstrap data
│   │   │   │   └── cart_controller.dart # Keranjang, diskon, bayar, hold bill, quick cash
│   │   │   ├── views/
│   │   │   │   ├── pos_view.dart        # Responsive (HP Portrait / Tablet Split Panel)
│   │   │   │   └── widgets/
│   │   │   │       ├── category_selector.dart
│   │   │   │       ├── product_card.dart
│   │   │   │       ├── product_customization_sheet.dart # Custom Gula, Es, Catatan item
│   │   │   │       ├── table_selector_sheet.dart       # Pemilihan Meja (01-20 / Custom)
│   │   │   │       ├── cart_bottom_sheet.dart          # Keranjang HP (Bottom Sheet)
│   │   │   │       ├── tablet_cart_panel.dart          # Keranjang Tablet (Side Panel)
│   │   │   │       ├── payment_modal_view.dart         # Pop-up Pembayaran & Quick Cash
│   │   │   │       └── payment_success_dialog.dart     # Pop-up Sukses & Cetak Struk
│   │   │
│   │   ├── shift/                      # 3. Modul Shift Kasir
│   │   │   ├── bindings/shift_binding.dart
│   │   │   ├── controllers/shift_controller.dart
│   │   │   └── views/shift_dialogs.dart # Modal Buka Shift & Tutup Shift (Rekap Kas)
│   │   │
│   │   ├── open_bills/                 # 4. Modul Daftar Bill Aktif
│   │   │   ├── bindings/open_bills_binding.dart
│   │   │   ├── controllers/open_bills_controller.dart
│   │   │   └── views/open_bills_view.dart
│   │   │
│   │   ├── transactions/               # 5. Modul Riwayat Transaksi Hari Ini
│   │   │   ├── bindings/transactions_binding.dart
│   │   │   ├── controllers/transactions_controller.dart
│   │   │   └── views/
│   │   │       ├── transactions_view.dart
│   │   │       └── widgets/receipt_view_dialog.dart # Modal Preview & Cetak Ulang Struk
│   │   │
│   │   └── settings/                   # 6. Modul Pengaturan & Perangkat
│   │       ├── bindings/settings_binding.dart
│   │       ├── controllers/settings_controller.dart
│   │       └── views/settings_view.dart # Base URL, Bluetooth Printer 58mm, Sync, Info Kasir
│   │
│   └── routes/                         # Routing GetX
│       ├── app_pages.dart              # Daftar GetPage + Binding masing-masing
│       └── app_routes.dart             # Nama rute statis
│
└── main.dart                           # Inisialisasi Storage, Services & GetMaterialApp
```

---

## Rencana Dependensi (`pubspec.yaml`)

- `get: ^4.6.6` : State management, dependency injection, and navigation.
- `dio: ^5.8.0+1` : HTTP networking, interceptors, timeout & error handling.
- `shared_preferences: ^2.5.2` : Local key-value storage (Token, Shift info, Cached Catalog, Offline queues).
- `intl: ^0.20.2` : Format mata uang Rupiah & datetime.
- `google_fonts: ^6.3.2` : Modern UI typography (`Plus Jakarta Sans`).
- `print_bluetooth_thermal: ^1.1.2` : Koneksi Bluetooth Thermal Printer 58mm & direct printing.
- `esc_pos_utils_plus: ^2.0.4` : Byte generator ESC/POS untuk receipt 58mm (header cafe, tabel pesanan, separator, summary kasir, QR code / Wifi info).
- `uuid: ^4.5.1` : Unique offline transaction IDs.

---

## Rincian Per Modul & Fitur

### 1. Data Layer & Core
- **`ApiConstants`**: Menyimpan endpoint URL backend Laravel (`/api/auth/*`, `/api/pos/*`) dengan dukungan konfigurasi dinamis Base URL (Default: `http://10.0.2.2:8000/api` untuk Emulator / `http://localhost:8000/api` / IP LAN Toko yang dapat diubah di Setting).
- **`AppColors` & `AppTheme`**: Tema modern POS dengan warna Emerald Green (`0xFF059669`), Slate Dark Backgrounds, Glassmorphism cards, kontras tinggi yang nyaman untuk kasir.
- **`ApiProvider` (Dio)**: Dilengkapi Auth Token Interceptor (Bearer Sanctum token otomatis), error toast handler, dan retry fallback offline.
- **`OfflineSyncService`**: Menyimpan transaksi secara offline di local storage saat koneksi terputus dan melakukan sinkronisasi otomatis ke endpoint `/api/pos/sync-offline` ketika online.
- **`EscPosPrinterService`**: Generator byte ESC/POS untuk struk thermal 58mm (Struk Belanja Pelanggan & Laporan Tutup Shift Kasir) serta pengiriman ke printer Bluetooth / Preview Struk.

### 2. Modul Auth (`/auth`)
- Tampilan 6-Digit PIN keypad interaktif dengan animasi haptic feedback.
- Pilihan kasir cepat (Quick Cashier Switch) dari daftar kasir aktif backend (`/api/auth/cashiers`).
- Validasi PIN, penyimpanan token ke SharedPreferences, dan verifikasi status shift kasir aktif.

### 3. Modul POS Kasir Utama (`/pos`)
- **Responsive Layout**:
  - **Smartphone Portrait**: Tampilan menu grid 2 kolom dengan filter kategori horizontal, search bar, dan floating bottom cart summary bar.
  - **Tablet / Large Screen**: Split-screen (kiri: katalog produk & kategori, kanan: cart panel permanen dengan kalkulasi realtime subtotal, diskon %, pajak %, total, dan tombol aksi).
- **Katalog & Kategori**: Filter kategori all/makanan/minuman, pencarian cepat, indikator menu terlaris.
- **Kustomisasi Menu (Sheet)**: Opsi varian gula (Normal, Less Sugar, No Sugar), Es (Normal Ice, Less Ice, No Ice), dan catatan khusus pesanan (misal: "Pedas sedang, tanpa seledri").
- **Pemilihan Tipe Pesanan & Meja**: Dine In (Pilih Meja 01-20 dengan indikator meja terisi / occupied dari API), Take Away, atau Delivery.
- **Hold Order / Open Bill**: Simpan pesanan aktif ke meja/nama pelanggan untuk dibayar nanti.
- **Modal Pembayaran**:
  - Pilihan metode bayar: Tunai (Cash), QRIS, Transfer Bank, Debit EDC.
  - Preset uang pas / quick cash (Rp 10.000, 20.000, 50.000, 100.000, 200.000) dan hitung otomatis kembalian.
  - Opsi Diskon (%) dan Pajak (%).
- **Dialog Transaksi Sukses**: Tampilan visual sukses dengan animasi, detail kembalian, cetak struk via bluetooth thermal atau preview digital.

### 4. Modul Shift Kasir (`/shift`)
- Buka Shift: Input modal awal laci kasir (Starting Cash).
- Informasi Realtime Shift: Total penjualan kas, QRIS, transfer, total transaksi, estimasi kas yang harus ada di laci (Expected Cash).
- Tutup Shift: Input kas riil di laci (Actual Cash), kalkulasi selisih (Selisih Lebih / Selisih Kurang / Pas), catatan kasir, guard cek Open Bill yang belum selesai, dan cetak Laporan Tutup Shift 58mm.

### 5. Modul Open Bills (`/open-bills`)
- Menampilkan daftar tagihan aktif / meja yang sedang makan (Pending status).
- Pencarian berdasarkan nomor meja atau nama pelanggan.
- Aksi: Buka kembali ke keranjang kasir (Resume Bill) untuk checkout/tambah menu, atau Batalkan Bill (Void).

### 6. Modul Riwayat Transaksi (`/transactions`)
- Riwayat transaksi hari ini kasir yang bersangkutan.
- Filter pencarian nomor invoice, metode pembayaran, dan status transaksi.
- Cetak ulang struk (Reprint Receipt) via Bluetooth printer atau dialog preview.

### 7. Modul Pengaturan (`/settings`)
- Konfigurasi Base URL Backend (mempermudah pengujian di berbagai jaringan Wi-Fi toko).
- Scan & Hubungkan Printer Bluetooth Thermal 58mm.
- Uji cetak struk tester.
- Status sinkronisasi data offline & tombol "Sync Sekarang".
- Informasi profil kasir yang login & tombol Logout.

---

## Verification Plan

### 1. Build & Dependency Verification
- Menjalankan `flutter pub get` untuk memastikan seluruh library kompatibel tanpa konflik.
- Menjalankan static analysis `dart analyze` untuk memverifikasi tidak ada compiler/type warning atau syntax error.

### 2. Manual UI & Business Logic Verification
- Verifikasi alur login PIN kasir & auto-detect shift.
- Verifikasi input modal awal buka shift & proteksi kasir saat shift belum dibuka.
- Verifikasi pemilihan menu, varian es/gula/notes, perubahan kuantitas keranjang, diskon, dan kalkulasi total.
- Verifikasi checkout transaksi tunai & non-tunai beserta kembalian.
- Verifikasi simpan Open Bill meja & resume open bill.
- Verifikasi tutup shift & generator rekap kasir.
- Verifikasi konfigurasi IP backend & format struk 58mm.
