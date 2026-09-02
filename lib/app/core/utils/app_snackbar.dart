import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/sound_service.dart';
import '../theme/app_colors.dart';

class AppSnackbar {
  /// Tampilkan Snackbar Berhasil (Success)
  static void success(String title, String message) {
    _show(
      title: title,
      message: message,
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.success,
      accentColor: AppColors.success,
      bgColor: Colors.white,
    );
  }

  /// Tampilkan Snackbar Gagal / Error (Danger)
  static void danger(
    String title,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      title: title,
      message: message,
      icon: Icons.error_rounded,
      iconColor: AppColors.danger,
      accentColor: AppColors.danger,
      bgColor: Colors.white,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: const Duration(seconds: 5),
    );
  }

  /// Tampilkan Snackbar Peringatan (Warning)
  static void warning(
    String title,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      title: title,
      message: message,
      icon: Icons.warning_amber_rounded,
      iconColor: AppColors.warning,
      accentColor: AppColors.warning,
      bgColor: Colors.white,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: const Duration(seconds: 4),
    );
  }

  /// Tampilkan Pop-Up Notifikasi Pesanan Online Masuk (Simpel, Bersih, Bebas Overflow)
  static void showOnlineOrderAlert({
    String? totalFormatted,
    VoidCallback? onTap,
  }) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.rawSnackbar(
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.only(top: 12, left: 16, right: 16),
      padding: EdgeInsets.zero,
      duration: const Duration(seconds: 10),
      snackStyle: SnackStyle.FLOATING,
      messageText: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 8,
            shadowColor: Colors.black.withAlpha(40),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                SoundService.stopSound();
                Get.closeCurrentSnackbar();
                onTap?.call();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withAlpha(120), width: 1.5),
                ),
                child: Row(
                  children: [
                    // Icon Lonceng / Pesanan
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Info Bersih & Padat
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pesanan Online Masuk!',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (totalFormatted != null && totalFormatted.isNotEmpty)
                                ? 'Total: $totalFormatted • Ketuk untuk proses'
                                : 'Ketuk untuk melihat rincian pesanan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Tombol Buka / Lihat
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Lihat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Tampilkan Snackbar Informasi (Info)
  static void info(String title, String message) {
    _show(
      title: title,
      message: message,
      icon: Icons.info_outline_rounded,
      iconColor: AppColors.info,
      accentColor: AppColors.info,
      bgColor: Colors.white,
    );
  }

  static void _show({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color accentColor,
    required Color bgColor,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.rawSnackbar(
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.only(top: 14, left: 20, right: 20),
      padding: EdgeInsets.zero,
      duration: duration,
      snackStyle: SnackStyle.FLOATING,
      messageText: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accentColor.withAlpha(90), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: accentColor.withAlpha(20),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon Avatar
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 16),

                // Text Content
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),

                // Optional Action Button (e.g. "Lihat Bill")
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(width: 14),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(
                      actionLabel,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Get.closeCurrentSnackbar();
                      onAction();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
