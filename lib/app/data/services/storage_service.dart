import 'dart:convert';
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

  Future<void> saveToken(String token) async {
    await _prefs.setString(_keyToken, token);
  }

  Future<void> clearAuth() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyUser);
    await _prefs.remove(_keyActiveShift);
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
}
