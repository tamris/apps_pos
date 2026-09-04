import 'package:intl/intl.dart';

class DateFormatter {
  /// Format tanggal & jam: `01 Sep 2026, 13:30`
  static String formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '-';
    DateTime dt;
    if (dateTime is String) {
      dt = DateTime.tryParse(dateTime) ?? DateTime.now();
    } else if (dateTime is DateTime) {
      dt = dateTime;
    } else {
      return '-';
    }
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      try {
        return DateFormat('dd MMM yyyy, HH:mm').format(dt);
      } catch (_) {
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    }
  }

  /// Format hanya tanggal: `01 September 2026`
  static String formatDate(dynamic dateTime) {
    if (dateTime == null) return '-';
    DateTime dt;
    if (dateTime is String) {
      dt = DateTime.tryParse(dateTime) ?? DateTime.now();
    } else if (dateTime is DateTime) {
      dt = dateTime;
    } else {
      return '-';
    }
    try {
      return DateFormat('dd MMMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      try {
        return DateFormat('dd MMMM yyyy').format(dt);
      } catch (_) {
        return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      }
    }
  }

  /// Format hanya jam: `13:30:45`
  static String formatTime(dynamic dateTime) {
    if (dateTime == null) return '-';
    DateTime dt;
    if (dateTime is String) {
      dt = DateTime.tryParse(dateTime) ?? DateTime.now();
    } else if (dateTime is DateTime) {
      dt = dateTime;
    } else {
      return '-';
    }
    try {
      return DateFormat('HH:mm:ss').format(dt);
    } catch (_) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    }
  }

  /// Format pendek untuk struk: `01/09/2026 13:30`
  static String formatReceiptDate(dynamic dateTime) {
    if (dateTime == null) return '-';
    DateTime dt;
    if (dateTime is String) {
      dt = DateTime.tryParse(dateTime) ?? DateTime.now();
    } else if (dateTime is DateTime) {
      dt = dateTime;
    } else {
      return '-';
    }
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  }

  /// Format hanya jam & menit: `13:30`
  /// Aman mem-parse string ISO, pola jam di dalam string, atau objek DateTime.
  static String formatHourMinute(dynamic dateTime) {
    if (dateTime == null) return '-';
    if (dateTime is DateTime) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
    if (dateTime is String) {
      final trimmed = dateTime.trim();
      if (trimmed.isEmpty) return '-';

      // 1. Coba parse sebagai DateTime terlebih dahulu (ISO 8601, string tanggal lengkap)
      final dt = DateTime.tryParse(trimmed);
      if (dt != null) {
        final local = dt.toLocal();
        return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      }

      // 2. Regex fallback jika string murni berupa jam:menit (misal '13:30' atau '13:30:45')
      final timeRegex = RegExp(r'(?:^|\D)([01]?\d|2[0-3]):([0-5]\d)(?:\D|$)');
      final match = timeRegex.firstMatch(trimmed);
      if (match != null) {
        final h = match.group(1)!.padLeft(2, '0');
        final m = match.group(2)!;
        return '$h:$m';
      }

      return trimmed;
    }
    return '-';
  }

  /// Format waktu relatif: `Baru saja`, `5 mnt lalu`, `1 jam lalu`, dll.
  static String timeAgo(dynamic dateTime) {
    if (dateTime == null) return '';
    DateTime? dt;
    if (dateTime is DateTime) {
      dt = dateTime;
    } else if (dateTime is String) {
      dt = DateTime.tryParse(dateTime);
      if (dt == null) {
        // Coba bersihkan jika ada format dd/MM/yyyy atau spasi
        try {
          final trimmed = dateTime.trim();
          final parts = trimmed.split(RegExp(r'[T ]'));
          if (parts.length >= 2) {
            dt = DateTime.tryParse('${parts[0]}T${parts[1]}');
          }
        } catch (_) {}
      }
    }
    if (dt == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dt.toLocal());

    if (difference.isNegative || difference.inSeconds < 45) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mnt lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hr lalu';
    } else {
      return formatDate(dt);
    }
  }
}

