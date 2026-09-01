# Rencana Implementasi: Fitur Terima Pesanan Online (Online Orders / Self-Order)

Setelah memeriksa endpoint API di backend Laravel (`pos-inventory/routes/api.php` dan `PosApiController.php`), backend telah menyediakan API lengkap untuk manajemen pesanan online:
1. `GET /api/pos/online-orders` (Daftar pesanan dengan filter status `active`, `pending`, `processing`, `ready`, `completed`, `cancelled`).
2. `GET /api/pos/online-orders/check-new` (Polling real-time pesanan baru masuk & notifikasi).
3. `GET /api/pos/online-orders/stats` (Statistik live pesanan aktif & omset online).
4. `POST /api/pos/online-orders/{id}/status` (Update status: Terima & Masak `processing`, Siap `ready`, Selesai `completed`, Tolak `cancelled`).
5. `POST /api/pos/online-orders/toggle-active` (Buka / Jeda penerimaan pesanan online toko).
6. `GET /api/pos/online-orders/{id}/receipt` & `.../kitchen` (Cetak struk kasir & tiket dapur).

---

## Proposed Changes

### 1. Data Layer & API Constants
#### [MODIFY] [api_constants.dart](file:///d:/Antigravity/noli_apps/lib/app/core/constants/api_constants.dart)
- Daftarkan endpoint API Pesanan Online:
  - `onlineOrders`, `onlineOrdersCheckNew`, `onlineOrdersStats`, `onlineOrdersToggleActive`
  - `updateOnlineOrderStatus(id)`, `onlineOrderReceipt(id)`, `onlineOrderKitchen(id)`

#### [NEW] [online_order_model.dart](file:///d:/Antigravity/noli_apps/lib/app/data/models/online_order_model.dart)
- Buat model `OnlineOrderModel`, `OnlineOrderItemModel`, dan `OnlineOrderStatsModel` dengan parsing type-safe JSON, status styling, dan format Rupiah.

#### [NEW] [online_order_polling_service.dart](file:///d:/Antigravity/noli_apps/lib/app/data/services/online_order_polling_service.dart)
- Service polling berkala di latar belakang (setiap 10-15 detik) untuk mendeteksi pesanan baru masuk.
- Memunculkan snackbar notifikasi *"Pesanan Online Baru Masuk! Meja X - Nama (Total Rp ...)"* dan mengupdate counter badge.

---

### 2. Module Online Orders
#### [NEW] [online_orders_controller.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/online_orders/controllers/online_orders_controller.dart)
- Fetch daftar pesanan dengan filter tab: **Aktif (Semua)**, **Menunggu (Pending)**, **Dimasak (Processing)**, **Siap (Ready)**, **Selesai (Completed)**, **Dibatalkan (Cancelled)**.
- Aksi 1-Sentuh:
  - **Terima & Masak (`processing`)**: Otomatis update status ke dapur & opsi cetak tiket dapur.
  - **Siap Diambil / Diantar (`ready`)**: Memberi tahu bahwa pesanan sudah matang.
  - **Selesaikan Pesanan (`completed`)**: Menyelesaikan pesanan.
  - **Tolak / Batalkan (`cancelled`)**: Dialog input alasan pembatalan.
  - **Toggle Penerimaan Pesanan Online Toko**: Switch Buka/Tutup pesanan online.
  - **Cetak Struk & Tiket Dapur**: Integrasi langsung dengan `EscPosPrinterService`.

#### [NEW] [online_orders_view.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/online_orders/views/online_orders_view.dart)
- Tampilan kartu pesanan modern dengan badge meja/take-away, status pesanan, rincian menu + catatan khusus, total bayar, dan tombol aksi cepat.
- Statistik ringkas di bagian atas (Pesanan Aktif, Menunggu, Selesai Hari Ini, Omset Online).

#### [NEW] [online_order_detail_dialog.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/online_orders/views/widgets/online_order_detail_dialog.dart)
- Dialog rincian lengkap pesanan (detail menu, harga, nomor invoice, waktu order, status pembayaran QRIS/Online).

---

### 3. Integrasi Navigasi & AppBar POS
#### [MODIFY] [app_routes.dart](file:///d:/Antigravity/noli_apps/lib/routes/app_routes.dart) & [app_pages.dart](file:///d:/Antigravity/noli_apps/lib/routes/app_pages.dart)
- Daftarkan route `/online-orders` dengan binding `OnlineOrdersBinding`.

#### [MODIFY] [pos_view.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/pos/views/pos_view.dart)
- Tambahkan tombol pintas **Pesanan Online** `[ 🛎️ ]` di AppBar (lengkap dengan badge angka merah jika ada pesanan baru yang menunggu diproses).
- Tambahkan menu "Pesanan Online" ke dalam popup menu `⋮`.

---

## Verification Plan

### Automated Tests
- Menjalankan `flutter analyze` untuk memastikan 0 error / warning.

### Manual Verification
- Cek pemanggilan API `GET /api/pos/online-orders` dan periksa render daftar kartu pesanan online.
- Uji alur perubahan status: Pending $\rightarrow$ Processing $\rightarrow$ Ready $\rightarrow$ Completed.
- Uji fitur toggle Buka / Tutup pesanan online toko.
- Uji cetak tiket dapur thermal untuk pesanan online.
