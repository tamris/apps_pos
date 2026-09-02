import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../data/services/storage_service.dart';

class SoundPresetItem {
  final String id;
  final String title;
  final String subtitle;
  final String? assetPath;
  final String icon;

  const SoundPresetItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.assetPath,
    required this.icon,
  });
}

class SoundService {
  static AudioPlayer? _audioPlayer;
  static Timer? _autoStopTimer;

  static StorageService get _storageService => Get.find<StorageService>();

  static const List<SoundPresetItem> presets = [
    SoundPresetItem(
      id: 'bell_classic',
      title: 'Lonceng Kasir Klasik',
      subtitle: 'Ding-Dong lembut khas kasir (Default)',
      assetPath: 'sounds/order_bell.wav',
      icon: '🛎️',
    ),
    SoundPresetItem(
      id: 'chime_modern',
      title: 'Melodi Chime Halus',
      subtitle: 'Kombinasi melodi modern yang elegan',
      assetPath: 'sounds/chime_modern.wav',
      icon: '🎵',
    ),
    SoundPresetItem(
      id: 'cash_register',
      title: 'Kasir Modern (Cha-Ching!)',
      subtitle: 'Efek suara register koin uang masuk',
      assetPath: 'sounds/cash_register.wav',
      icon: '💵',
    ),
    SoundPresetItem(
      id: 'bell_single',
      title: 'Lonceng Meja (Ting!)',
      subtitle: 'Denting lonceng meja tunggal yang jernih',
      assetPath: 'sounds/bell_single.wav',
      icon: '🔔',
    ),
  ];

  /// Hentikan suara seketika
  static Future<void> stopSound() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    try {
      await _audioPlayer?.stop();
    } catch (_) {}
  }

  /// Putar suara notifikasi saat pesanan online baru masuk (Maksimal 10 detik auto-stop)
  static Future<void> playOrderNotificationSound() async {
    // 1. Getar Haptic Alert
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}

    final selectedPreset = _storageService.selectedSoundPreset;

    // 2. Putar Audio (Custom File HP atau Preset Asset)
    try {
      _audioPlayer ??= AudioPlayer();
      await stopSound();
      await _audioPlayer?.setVolume(1.0);

      if (selectedPreset == 'custom') {
        final customPath = _storageService.customSoundPath;
        if (customPath != null && customPath.isNotEmpty && File(customPath).existsSync()) {
          await _audioPlayer?.play(
            DeviceFileSource(customPath),
            mode: PlayerMode.lowLatency,
          );
        } else {
          // Fallback ke default jika file kustom tidak ditemukan
          await _audioPlayer?.play(
            AssetSource('sounds/order_bell.wav'),
            mode: PlayerMode.lowLatency,
          );
        }
      } else {
        // Cari preset berdasarkan ID
        final preset = presets.firstWhere(
          (p) => p.id == selectedPreset,
          orElse: () => presets.first,
        );

        if (preset.assetPath != null) {
          await _audioPlayer?.play(
            AssetSource(preset.assetPath!),
            mode: PlayerMode.lowLatency,
          );
        }
      }

      // Auto-stop otomatis setelah 10 detik jika tidak dimatikan manual
      _autoStopTimer = Timer(const Duration(seconds: 10), () {
        stopSound();
      });
    } catch (e) {
      debugPrint('[SoundService] Audio playback error: $e');
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  /// Putar pratinjau tes audio langsung (bisa berdasarkan ID preset atau path custom)
  static Future<void> testPlaySound({String? presetId, String? customPath}) async {
    try {
      await HapticFeedback.selectionClick();
      _audioPlayer ??= AudioPlayer();
      await stopSound();

      final targetPreset = presetId ?? _storageService.selectedSoundPreset;
      await _audioPlayer?.setVolume(1.0);

      if (targetPreset == 'custom' || customPath != null) {
        final path = customPath ?? _storageService.customSoundPath;
        if (path != null && path.isNotEmpty && File(path).existsSync()) {
          await _audioPlayer?.play(
            DeviceFileSource(path),
            mode: PlayerMode.lowLatency,
          );
        } else {
          await _audioPlayer?.play(
            AssetSource('sounds/order_bell.wav'),
            mode: PlayerMode.lowLatency,
          );
        }
      } else {
        final preset = presets.firstWhere(
          (p) => p.id == targetPreset,
          orElse: () => presets.first,
        );

        if (preset.assetPath != null) {
          await _audioPlayer?.play(
            AssetSource(preset.assetPath!),
            mode: PlayerMode.lowLatency,
          );
        }
      }

      // Auto-stop otomatis setelah 10 detik
      _autoStopTimer = Timer(const Duration(seconds: 10), () {
        stopSound();
      });
    } catch (e) {
      debugPrint('[SoundService] Test audio playback error: $e');
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (_) {}
    }
  }

  static void dispose() {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _audioPlayer?.dispose();
    _audioPlayer = null;
  }
}
