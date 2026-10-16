import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:noli_apps/app/core/constants/api_constants.dart';
import 'package:noli_apps/app/core/widgets/app_shimmer.dart';
import 'package:noli_apps/app/data/providers/api_provider.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/admin_settings_tab.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/admin_edit_store_dialog.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/admin_loyalty_settings_dialog.dart';
import 'package:noli_apps/app/modules/admin/views/widgets/admin_telegram_settings_dialog.dart';

class PendingSettingsApiProvider extends GetxService implements ApiProvider {
  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    // Return future that never completes during the test
    return Completer<Response>().future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSettingsApiProvider extends GetxService implements ApiProvider {
  @override
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final reqOptions = RequestOptions(path: path);

    if (path == ApiConstants.adminGeneralSettings) {
      return Response(
        requestOptions: reqOptions,
        data: {
          'success': true,
          'data': {
            'shop_name': 'Noli Coffe & Space',
            'address': 'Jl. Kh Wahid Hasyim, Slawi Kulon Kec. Slawi, Kab. Tegal Slawi',
            'phone': '08123456789',
            'wifi_name': 'Noli Coffee Free WiFi',
            'wifi_password': 'kopinoliindonesia',
            'receipt_footer': 'Terima Kasih Atas Kunjungannya!',
            'auto_print_receipt': false,
            'auto_print_kitchen': false,
            'show_logo_receipt': true,
            'point_enabled': true,
            'point_spend_per_point': 10000,
            'point_exchange_rate': 1000,
            'point_min_redeem': 5,
          },
        },
        statusCode: 200,
      );
    }
    if (path == ApiConstants.adminTelegramSettings) {
      return Response(
        requestOptions: reqOptions,
        data: {
          'success': true,
          'data': {
            'is_configured': true,
            'notify_trx': true,
            'notify_shift': true,
            'notify_void': true,
          },
        },
        statusCode: 200,
      );
    }
    if (path == ApiConstants.adminLoyaltySettings) {
      return Response(
        requestOptions: reqOptions,
        data: {
          'success': true,
          'data': {
            'point_enabled': true,
            'point_spend_per_point': 10000,
            'point_exchange_rate': 1000,
            'point_min_redeem': 5,
          },
        },
        statusCode: 200,
      );
    }
    return Response(requestOptions: reqOptions, data: {'success': false}, statusCode: 404);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.reset();
  });

  testWidgets('Pumps AdminSettingsTab on desktop (1400x900) and verifies layout & cards', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Get.put<ApiProvider>(MockSettingsApiProvider());

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminSettingsTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Hero Header
    expect(find.text('Noli Coffe & Space'), findsWidgets);
    expect(find.text('Pusat Kontrol Utama'), findsOneWidget);
    expect(find.text('Edit Profil Toko'), findsOneWidget);

    // Verify 4 Bento Cards
    expect(find.text('Akses WiFi Pengunjung'), findsWidgets);
    expect(find.text('Noli Coffee Free WiFi'), findsOneWidget);
    expect(find.text('Program Poin Member'), findsWidgets);
    expect(find.text('Loyalitas Aktif'), findsOneWidget);
    expect(find.text('Printer Struk Kasir'), findsOneWidget);
    expect(find.text('Bot Telegram Owner'), findsOneWidget);

    // Verify Section Cards in viewport
    expect(find.text('Profil & Identitas Outlet'), findsOneWidget);
    expect(find.text('Printer Thermal & Hardware Kasir'), findsOneWidget);

    // Scroll to reveal lower cards in ListView
    await tester.scrollUntilVisible(find.text('Notifikasi & Bot Telegram Owner'), 200);
    expect(find.text('Notifikasi & Bot Telegram Owner'), findsOneWidget);

    // Verify Sleek Minimalist System Version Footer Strip
    await tester.scrollUntilVisible(find.text('Noli POS v1.1.2 (Stabil)'), 200);
    expect(find.text('Noli POS v1.1.2 (Stabil)'), findsOneWidget);
    expect(find.text('Terhubung ke Cloud (Cloudflare)'), findsOneWidget);
    expect(find.text('Cek Update'), findsOneWidget);

    // Tap Cek Update button
    await tester.tap(find.text('Cek Update'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));

    // Verify static placeholder cards remain completely removed
    expect(find.text('Pajak (PB1), Service Charge & Diskon'), findsNothing);
    expect(find.text('Manajemen Staf Kasir & Hak Akses'), findsNothing);
    expect(find.text('Informasi Sistem, Database & Status Cloud'), findsNothing);
  });

  testWidgets('Pumps AdminSettingsTab on mobile (360x640) and verifies zero overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Get.put<ApiProvider>(MockSettingsApiProvider());

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminSettingsTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Noli Coffe & Space'), findsWidgets);
    expect(find.text('Pusat Kontrol Utama'), findsOneWidget);
    expect(find.text('Segarkan'), findsNothing);
    expect(find.text('Edit Profil Toko'), findsOneWidget);
  });

  testWidgets('Pumps AdminEditStoreDialog on mobile (360x640) and verifies zero overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Get.put<ApiProvider>(MockSettingsApiProvider());

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminEditStoreDialog(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Edit Profil Outlet & Struk'), findsOneWidget);
    expect(find.text('Nama Toko / Outlet'), findsOneWidget);
    expect(find.text('Alamat Cabang Lengkap'), findsOneWidget);
    expect(find.text('Nomor WhatsApp / Kontak Toko'), findsOneWidget);
    expect(find.text('Nama WiFi (SSID)'), findsOneWidget);
    expect(find.text('Sandi WiFi'), findsOneWidget);
    expect(find.text('Simpan Perubahan'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
  });

  testWidgets('Pumps AdminLoyaltySettingsDialog on mobile (360x640) and verifies zero overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Get.put<ApiProvider>(MockSettingsApiProvider());

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminLoyaltySettingsDialog(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pengaturan Loyalitas & Poin'), findsOneWidget);
    expect(find.text('Status Program Loyalitas'), findsOneWidget);
    expect(find.text('Nominal Belanja per 1 Poin (Rp)'), findsOneWidget);
    expect(find.text('Nilai 1 Poin (Rupiah)'), findsOneWidget);
    expect(find.text('Minimal Poin Tukar'), findsOneWidget);
    expect(find.text('Simpan Pengaturan'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
  });

  testWidgets('Pumps AdminTelegramSettingsDialog on mobile (360x640) and verifies zero overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Get.put<ApiProvider>(MockSettingsApiProvider());

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminTelegramSettingsDialog(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Integrasi Bot Telegram Owner'), findsOneWidget);
    expect(find.text('Kirim Uji Coba'), findsOneWidget);
    expect(find.text('Simpan Pengaturan'), findsOneWidget);
    expect(find.text('Batal'), findsOneWidget);
  });

  testWidgets('Pumps AdminSettingsTab on ultra-compact mobile (320x568) and verifies zero overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Get.put<ApiProvider>(MockSettingsApiProvider());

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminSettingsTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Noli Coffe & Space'), findsWidgets);
    expect(find.text('Pusat Kontrol Utama'), findsOneWidget);
  });

  testWidgets('Pumps AdminSettingsTab on tablet portrait (768x1024) and verifies zero overflow', (tester) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Get.put<ApiProvider>(MockSettingsApiProvider());

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminSettingsTab(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Noli Coffe & Space'), findsWidgets);
    expect(find.text('Pusat Kontrol Utama'), findsOneWidget);
    expect(find.text('Edit Profil Toko'), findsOneWidget);
  });

  testWidgets('Pumps AdminLoyaltySettingsDialog in loading state and renders AppShimmer skeleton', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Get.put<ApiProvider>(PendingSettingsApiProvider());

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminLoyaltySettingsDialog(),
        ),
      ),
    );

    expect(find.byType(AppShimmer), findsOneWidget);
  });

  testWidgets('Pumps AdminEditStoreDialog in loading state and renders AppShimmer skeleton', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Get.put<ApiProvider>(PendingSettingsApiProvider());

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminEditStoreDialog(),
        ),
      ),
    );

    expect(find.byType(AppShimmer), findsOneWidget);
  });

  testWidgets('Pumps AdminTelegramSettingsDialog in loading state and renders AppShimmer skeleton', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Get.put<ApiProvider>(PendingSettingsApiProvider());

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminTelegramSettingsDialog(),
        ),
      ),
    );

    expect(find.byType(AppShimmer), findsOneWidget);
  });

  testWidgets('Pumps AdminSettingsTab in loading state and renders AppShimmer skeleton', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    Get.put<ApiProvider>(PendingSettingsApiProvider());

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: AdminSettingsTab(),
        ),
      ),
    );

    expect(find.byType(AppShimmer), findsOneWidget);
  });
}
