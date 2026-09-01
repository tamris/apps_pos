import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    Duration duration = const Duration(seconds: 3),
  }) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.rawSnackbar(
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: EdgeInsets.zero,
      duration: duration,
      snackStyle: SnackStyle.FLOATING,
      messageText: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withAlpha(80), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: accentColor.withAlpha(20),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Get.closeCurrentSnackbar();
                      onAction();
                    },
                    child: Text(
                      actionLabel,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
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
