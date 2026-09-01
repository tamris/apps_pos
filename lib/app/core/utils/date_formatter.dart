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
}
