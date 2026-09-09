import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noli_apps/app/data/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Offline Date Rollover Tests', () {
    late StorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
      await storageService.init();
    });

    test('getCachedTodayTransactions clears stale transactions from previous days', () async {
      final prefs = await SharedPreferences.getInstance();

      // Simulasikan cache tersimpan kemarin (misal 2026-09-05)
      await prefs.setString('cached_today_date', '2026-09-05');
      await prefs.setString('cached_today_transactions', jsonEncode([
        {'id': 101, 'invoice_number': 'INV-YESTERDAY', 'total': 50000}
      ]));
      await prefs.setString('cached_today_stats', jsonEncode({'all': 1, 'completed': 1}));

      // Panggil getCachedTodayTransactions pada hari ini (misal bukan 2026-09-05)
      final txs = storageService.getCachedTodayTransactions();
      final stats = storageService.getCachedTodayStats();

      // Cache kemarin harus otomatis dibersihkan dan dikembalikan kosong
      expect(txs, isEmpty);
      expect(stats, isNull);
      expect(prefs.getString('cached_today_transactions'), isNull);
      expect(prefs.getString('cached_today_stats'), isNull);
    });

    test('saveCachedTodayTransactions preserves transactions created today', () async {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);

      await storageService.saveCachedTodayTransactions([
        {'id': 201, 'invoice_number': 'INV-TODAY', 'total': 25000}
      ]);

      final txs = storageService.getCachedTodayTransactions();
      expect(txs.length, 1);
      expect(txs.first['invoice_number'], 'INV-TODAY');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cached_today_date'), todayStr);
    });
  });
}
