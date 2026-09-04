import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/shift_model.dart';
import '../../core/constants/api_constants.dart';

class StorageService extends GetxService {
  late SharedPreferences _prefs;

  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keyBaseUrl = 'base_url';
  static const String _keyActiveShift = 'active_shift';
  static const String _keyOfflineQueue = 'offline_transactions_queue';
  static const String _keyPrinterMac = 'selected_printer_mac';
  static const String _keyPrinterName = 'selected_printer_name';
  static const String _keyCustomSoundPath = 'custom_order_sound_path';
  static const String _keyCustomSoundName = 'custom_order_sound_name';
  static const String _keySelectedSoundPreset = 'selected_sound_preset';

  // Offline-First Caches
  static const String _keyBootstrapCache = 'pos_bootstrap_cache';
  static const String _keyBootstrapTimestamp = 'pos_bootstrap_timestamp';
  static const String _keyCachedCashiers = 'cached_cashiers_list';
  static const String _keyCashierPinHashes = 'cashier_pin_hashes';
  static const String _keyOfflineOpenBills = 'offline_open_bills_queue';
  static const String _keyCachedServerOpenBills = 'cached_server_open_bills';
  static const String _keyOfflineCompletedServerBillIds = 'offline_completed_server_bill_ids';
  static const String _keyCachedTodayTransactions = 'cached_today_transactions';
  static const String _keyCachedTodayStats = 'cached_today_stats';

  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  // --- Notification Sound Settings (Presets & Custom) ---
  String get selectedSoundPreset => _prefs.getString(_keySelectedSoundPreset) ?? 'bell_classic';

  Future<void> saveSelectedSoundPreset(String preset) async {
    await _prefs.setString(_keySelectedSoundPreset, preset);
  }

  String? get customSoundPath => _prefs.getString(_keyCustomSoundPath);
  String? get customSoundName => _prefs.getString(_keyCustomSoundName);

  Future<void> saveCustomSound(String path, String name) async {
    await _prefs.setString(_keyCustomSoundPath, path);
    await _prefs.setString(_keyCustomSoundName, name);
    await saveSelectedSoundPreset('custom');
  }

  Future<void> clearCustomSound() async {
    await _prefs.remove(_keyCustomSoundPath);
    await _prefs.remove(_keyCustomSoundName);
    await saveSelectedSoundPreset('bell_classic');
  }

  // --- Base URL ---
  String get baseUrl => _prefs.getString(_keyBaseUrl) ?? ApiConstants.defaultBaseUrl;
  Future<void> setBaseUrl(String url) async {
    await _prefs.setString(_keyBaseUrl, url.trim());
  }

  // --- Auth Token ---
  String? get token => _prefs.getString(_keyToken);
  bool get hasToken => token != null && token!.isNotEmpty;
  bool get isOfflineToken => token != null && token!.startsWith('offline_token_');

  Future<void> saveToken(String token) async {
    await _prefs.setString(_keyToken, token);
  }

  // --- Active Cashier PIN for Auto Re-Auth ---
  static const String _keyActivePin = 'active_cashier_pin';
  String? get activePin => _prefs.getString(_keyActivePin);

  Future<void> saveActivePin(String pin) async {
    await _prefs.setString(_keyActivePin, pin);
  }

  Future<void> clearAuth() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUser);
    await _prefs.remove(_keyActiveShift);
    await _prefs.remove(_keyActivePin);
  }

  // --- User Profile ---
  UserModel? get user {
    final raw = _prefs.getString(_keyUser);
    if (raw == null) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUser(UserModel user) async {
    await _prefs.setString(_keyUser, jsonEncode(user.toJson()));
  }

  // --- Active Shift ---
  ShiftModel? get activeShift {
    final raw = _prefs.getString(_keyActiveShift);
    if (raw == null) return null;
    try {
      return ShiftModel.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveActiveShift(ShiftModel? shift) async {
    if (shift == null) {
      await _prefs.remove(_keyActiveShift);
    } else {
      await _prefs.setString(_keyActiveShift, jsonEncode(shift.toJson()));
    }
  }

  // --- Printer Setting ---
  String? get printerMac => _prefs.getString(_keyPrinterMac);
  String? get printerName => _prefs.getString(_keyPrinterName);

  Future<void> savePrinter(String mac, String name) async {
    await _prefs.setString(_keyPrinterMac, mac);
    await _prefs.setString(_keyPrinterName, name);
  }

  Future<void> clearPrinter() async {
    await _prefs.remove(_keyPrinterMac);
    await _prefs.remove(_keyPrinterName);
  }

  // --- Offline Transaction Queue ---
  List<Map<String, dynamic>> getOfflineQueue() {
    final raw = _prefs.getString(_keyOfflineQueue);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveOfflineQueue(List<Map<String, dynamic>> queue) async {
    await _prefs.setString(_keyOfflineQueue, jsonEncode(queue));
  }

  Future<void> addOfflineTransaction(Map<String, dynamic> tx) async {
    final current = getOfflineQueue();
    current.add(tx);
    await saveOfflineQueue(current);
  }

  Future<void> clearOfflineQueue() async {
    await _prefs.remove(_keyOfflineQueue);
  }

  // --- Offline Open Bills Storage ---
  List<Map<String, dynamic>> getOfflineOpenBills() {
    final raw = _prefs.getString(_keyOfflineOpenBills);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      final completedIds = getOfflineCompletedServerBillIds();
      return decoded
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) {
            final id = int.tryParse(e['id']?.toString() ?? '0') ?? 0;
            return !completedIds.contains(id);
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveOfflineOpenBills(List<Map<String, dynamic>> bills) async {
    await _prefs.setString(_keyOfflineOpenBills, jsonEncode(bills));
  }

  Future<void> saveOfflineOpenBill(Map<String, dynamic> bill) async {
    final current = getOfflineOpenBills();
    final billId = int.tryParse(bill['id']?.toString() ?? '0') ?? 0;
    final existingIndex = current.indexWhere((b) {
      final bId = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
      return bId == billId;
    });
    if (existingIndex >= 0) {
      current[existingIndex] = bill;
    } else {
      current.add(bill);
    }
    await saveOfflineOpenBills(current);
  }

  Future<void> removeOfflineOpenBill(int id) async {
    final current = getOfflineOpenBills();
    current.removeWhere((b) {
      final bId = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
      return bId == id;
    });
    await saveOfflineOpenBills(current);
  }

  /// Hapus open bill secara menyeluruh saat checkout selesai (baik offline maupun server snapshot)
  Future<void> removeOpenBillOnCheckout({int? billId, String? tableNumber}) async {
    final cleanTable = tableNumber?.trim().toLowerCase();

    // 1. Hapus dari Offline Open Bills (berdasarkan ID atau nomor meja)
    final offlineBills = getOfflineOpenBills();
    offlineBills.removeWhere((b) {
      final bId = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
      if (billId != null && billId != 0 && bId == billId) return true;
      if (cleanTable != null && cleanTable.isNotEmpty) {
        final bTable = (b['table_number'] ?? b['table'])?.toString().trim().toLowerCase();
        if (bTable == cleanTable) return true;
      }
      return false;
    });
    await saveOfflineOpenBills(offlineBills);

    // 2. Hapus dari Cached Server Open Bills (berdasarkan ID atau nomor meja)
    final cachedBills = getCachedServerOpenBills();
    cachedBills.removeWhere((b) {
      final bId = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
      if (billId != null && billId != 0 && bId == billId) return true;
      if (cleanTable != null && cleanTable.isNotEmpty) {
        final bTable = (b['table_number'] ?? b['table'])?.toString().trim().toLowerCase();
        if (bTable == cleanTable) return true;
      }
      return false;
    });
    await saveCachedServerOpenBills(cachedBills);

    // 3. Jika billId > 0 (ID dari server), tambahkan ke completed list agar tidak muncul kembali
    if (billId != null && billId > 0) {
      await addOfflineCompletedServerBillId(billId);
    }
  }

  Future<void> clearOfflineOpenBills() async {
    await _prefs.remove(_keyOfflineOpenBills);
  }

  // --- Cached Server Open Bills (Snapshot saat online) ---
  List<Map<String, dynamic>> getCachedServerOpenBills() {
    final raw = _prefs.getString(_keyCachedServerOpenBills);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      final completedIds = getOfflineCompletedServerBillIds();
      return decoded
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) {
            final id = int.tryParse(e['id']?.toString() ?? '0') ?? 0;
            return !completedIds.contains(id);
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCachedServerOpenBills(List<Map<String, dynamic>> bills) async {
    await _prefs.setString(_keyCachedServerOpenBills, jsonEncode(bills));
  }

  Future<void> removeCachedServerOpenBill(int id) async {
    final current = getCachedServerOpenBills();
    current.removeWhere((b) {
      final bId = int.tryParse(b['id']?.toString() ?? '0') ?? 0;
      return bId == id;
    });
    await saveCachedServerOpenBills(current);
  }

  // --- Offline Completed / Cancelled Server Bill IDs Tracker ---
  List<int> getOfflineCompletedServerBillIds() {
    final raw = _prefs.getStringList(_keyOfflineCompletedServerBillIds);
    if (raw == null) return [];
    return raw.map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toList();
  }

  Future<void> addOfflineCompletedServerBillId(int id) async {
    if (id <= 0) return;
    final list = getOfflineCompletedServerBillIds();
    if (!list.contains(id)) {
      list.add(id);
      await _prefs.setStringList(
        _keyOfflineCompletedServerBillIds,
        list.map((e) => e.toString()).toList(),
      );
    }
  }

  Future<void> removeOfflineCompletedServerBillId(int id) async {
    final list = getOfflineCompletedServerBillIds();
    if (list.remove(id)) {
      await _prefs.setStringList(
        _keyOfflineCompletedServerBillIds,
        list.map((e) => e.toString()).toList(),
      );
    }
  }

  Future<void> clearOfflineCompletedServerBillIds() async {
    await _prefs.remove(_keyOfflineCompletedServerBillIds);
  }

  // --- Cached Today's Transactions (Snapshot saat online) ---
  List<Map<String, dynamic>> getCachedTodayTransactions() {
    final raw = _prefs.getString(_keyCachedTodayTransactions);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCachedTodayTransactions(List<Map<String, dynamic>> txs) async {
    await _prefs.setString(_keyCachedTodayTransactions, jsonEncode(txs));
  }

  Map<String, dynamic>? getCachedTodayStats() {
    final raw = _prefs.getString(_keyCachedTodayStats);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> saveCachedTodayStats(Map<String, dynamic> stats) async {
    await _prefs.setString(_keyCachedTodayStats, jsonEncode(stats));
  }

  Future<void> clearCachedTodayTransactions() async {
    await _prefs.remove(_keyCachedTodayTransactions);
    await _prefs.remove(_keyCachedTodayStats);
  }

  // --- SHA-256 Helper ---
  String hashPin(String pin) {
    final bytes = utf8.encode('noli_pos_salt_$pin');
    return sha256.convert(bytes).toString();
  }

  // --- Master Data (Bootstrap) Cache ---
  bool get hasBootstrapCache => _prefs.containsKey(_keyBootstrapCache);

  Map<String, dynamic>? getBootstrapCache() {
    final raw = _prefs.getString(_keyBootstrapCache);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveBootstrapCache(Map<String, dynamic> data) async {
    await _prefs.setString(_keyBootstrapCache, jsonEncode(data));
    await _prefs.setString(_keyBootstrapTimestamp, DateTime.now().toIso8601String());
  }

  DateTime? get bootstrapCacheTime {
    final raw = _prefs.getString(_keyBootstrapTimestamp);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  // --- Cashier List & Offline PIN Hashes ---
  Future<void> saveCachedCashiers(List<UserModel> cashiers) async {
    final list = cashiers.map((c) => c.toJson()).toList();
    await _prefs.setString(_keyCachedCashiers, jsonEncode(list));
  }

  List<UserModel> getCachedCashiers() {
    final raw = _prefs.getString(_keyCachedCashiers);
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.map((e) => UserModel.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCashierPinHash(int userId, String pin) async {
    final hash = hashPin(pin);
    final raw = _prefs.getString(_keyCashierPinHashes);
    Map<String, dynamic> map = {};
    if (raw != null) {
      try {
        map = jsonDecode(raw);
      } catch (_) {}
    }
    map[userId.toString()] = hash;
    await _prefs.setString(_keyCashierPinHashes, jsonEncode(map));
  }

  UserModel? verifyOfflinePin(String pin, int? selectedUserId) {
    final inputHash = hashPin(pin);
    final raw = _prefs.getString(_keyCashierPinHashes);
    if (raw == null) return null;

    try {
      final Map<String, dynamic> map = jsonDecode(raw);
      final cachedCashiers = getCachedCashiers();

      // 1. Jika kasir memilih avatar spesifik
      if (selectedUserId != null && selectedUserId > 0) {
        final expectedHash = map[selectedUserId.toString()];
        if (expectedHash == inputHash) {
          return cachedCashiers.firstWhereOrNull((c) => c.id == selectedUserId) ?? user;
        }
        return null;
      }

      // 2. Jika kasir langsung mengetik PIN tanpa pilih avatar
      for (final entry in map.entries) {
        if (entry.value == inputHash) {
          final userId = int.tryParse(entry.key) ?? 0;
          final matchedCashier = cachedCashiers.firstWhereOrNull((c) => c.id == userId);
          if (matchedCashier != null) return matchedCashier;
        }
      }

      // 3. Cek user yang sedang tersimpan di session
      if (user != null) {
        final expectedHash = map[user!.id.toString()];
        if (expectedHash == inputHash) {
          return user;
        }
      }
    } catch (_) {}

    return null;
  }
}
