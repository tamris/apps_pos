# Walkthrough: Arsitektur Offline-First POS

Implementasi arsitektur **Offline-First** pada aplikasi kasir Noli POS telah selesai. Sistem sekarang mampu menangani skenario ketika koneksi internet/Wi-Fi kafe mati **sebelum** kasir login atau saat pertama kali aplikasi dibuka di pagi hari.

---

## Ringkasan Fitur yang Diimplementasikan

```
┌─────────────────────────────────────────────────────────────┐
│ 1. OFFLINE AUTH & PIN CACHE (SHA-256)                       │
│    Kasir tetap bisa login PIN saat internet mati total.     │
├─────────────────────────────────────────────────────────────┤
│ 2. MASTER DATA BOOTSTRAP CACHE                              │
│    Katalog produk, kategori, harga & toko dimuat instan.    │
├─────────────────────────────────────────────────────────────┤
│ 3. OFFLINE SHIFT MANAGEMENT                                 │
│    Input kas awal & buka shift kasir tetap berfungsi lokal. │
├─────────────────────────────────────────────────────────────┤
│ 4. ENRICHED OFFLINE RECEIPT                                 │
│    Struk offline memuat nama kafe & kasir asli dari storage.│
├─────────────────────────────────────────────────────────────┤
│ 5. RECONCILIATION & AUTO-REFRESH SYNC                       │
│    Otomatis memperbarui stok & data toko setelah sync.      │
└─────────────────────────────────────────────────────────────┘
```

---

## File yang Dimodifikasi

| Komponen | File | Deskripsi Perubahan |
| :--- | :--- | :--- |
| **Dependencies** | [pubspec.yaml](file:///d:/Antigravity/noli_apps/pubspec.yaml) | Menambahkan paket `crypto: ^3.0.6` untuk hashing SHA-256 PIN. |
| **Storage Layer** | [storage_service.dart](file:///d:/Antigravity/noli_apps/lib/app/data/services/storage_service.dart) | Menambahkan `saveBootstrapCache`, `getBootstrapCache`, `saveCashierPinHash`, dan `verifyOfflinePin`. |
| **Authentication** | [auth_controller.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/auth/controllers/auth_controller.dart) | Implementasi offline PIN login verification saat koneksi server gagal dan caching kasir. |
| **Auth UI** | [pin_login_view.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/auth/views/pin_login_view.dart) | Menambahkan visual `_buildOfflineBadge` dan `_buildCashierSelector`. |
| **POS Controller** | [pos_controller.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/pos/controllers/pos_controller.dart) | Instant loading produk dari cache lokal saat buka aplikasi dan auto-cache data `/pos/bootstrap`. |
| **Cart & Struk** | [cart_controller.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/pos/controllers/cart_controller.dart) | Struk offline otomatis menggunakan nama toko, alamat, dan kasir asli dari cache. |
| **Shift Kasir** | [shift_controller.dart](file:///d:/Antigravity/noli_apps/lib/app/modules/shift/controllers/shift_controller.dart) | Mendukung pembukaan dan penutupan shift kasir offline lokal jika API backend offline. |
| **Offline Sync** | [offline_sync_service.dart](file:///d:/Antigravity/noli_apps/lib/app/data/services/offline_sync_service.dart) | Auto-refresh silent data bootstrap setelah transaksi offline berhasil tersinkronkan. |

---

## Hasil Verifikasi & Pengujian

### 1. Static Analysis
- Perintah: `flutter analyze`
- Hasil: **No issues found!** (0 error, 0 warning).

### 2. Skenario Uji Alur Penggunaan

#### A. Skenario Online (Normal)
- Kasir membuka aplikasi saat terhubung internet.
- Memasukkan 6-digit PIN -> Login berhasil.
- Sistem secara otomatis:
  1. Menyimpan token auth & profile kasir.
  2. Menyimpan SHA-256 PIN hash ke storage terenkripsi lokal.
  3. Mengambil `/pos/bootstrap` dan menyimpannya ke `pos_bootstrap_cache`.

#### B. Skenario Offline dari Awal Buka Aplikasi (Wi-Fi Mati / ISP Drop)
- Aplikasi dibuka dalam kondisi tidak ada internet.
- Daftar nama kasir tetap muncul dari cache.
- Kasir memasukkan 6 digit PIN -> Sistem memvalidasi ke SHA-256 hash lokal -> Kasir berhasil masuk ke layar POS dengan status *"Mode Offline"*.
- Seluruh produk, kategori, foto, harga, varian, dan setting kafe langsung muncul lengkap dari cache lokal tanpa blank screen atau error popup yang mengganggu.
- Buka shift kasir dengan modal awal tetap tercatat di lokal.
- Transaksi tetap berjalan normal (Cash / EDC), struk tercetak ke printer Bluetooth thermal dengan nama toko & kasir yang benar.
- Transaksi otomatis masuk ke antrean offline lokal.

#### C. Skenario Internet Pulih & Sinkronisasi
- Begitu Wi-Fi menyala kembali, kasir atau sistem menjalankan sinkronisasi transaksi offline.
- Data terunggah ke backend Laravel dan antrean dibersihkan.
- Katalog stok dan status meja otomatis diperbarui dari server.
