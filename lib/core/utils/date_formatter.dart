import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateFormatVi = DateFormat('dd/MM/yyyy');
  static final DateFormat _dateTimeFormatVi = DateFormat('dd/MM/yyyy HH:mm');

  static String formatDate(DateTime date) {
    return _dateFormatVi.format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormatVi.format(dateTime);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MM/yyyy').format(date);
  }

  /// Parse receipt date string from OCR into DateTime.
  /// Supports: dd/MM/yyyy, dd-MM-yyyy, yyyy-MM-dd, dd/MM/yy, etc.
  static DateTime? parseReceiptDate(String text) {
    if (text.trim().isEmpty) return null;

    final clean = text.trim();

    // Regex patterns for dates
    final patterns = [
      RegExp(r'(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{4})'), // dd/MM/yyyy
      RegExp(r'(\d{4})[\/\.\-](\d{1,2})[\/\.\-](\d{1,2})'), // yyyy-MM-dd
      RegExp(r'(\d{1,2})[\/\.\-](\d{1,2})[\/\.\-](\d{2})'), // dd/MM/yy
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(clean);
      if (match != null) {
        try {
          if (pattern == patterns[0]) {
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            if (_isValidDate(year, month, day)) {
              return DateTime(year, month, day);
            }
          } else if (pattern == patterns[1]) {
            final year = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final day = int.parse(match.group(3)!);
            if (_isValidDate(year, month, day)) {
              return DateTime(year, month, day);
            }
          } else if (pattern == patterns[2]) {
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            var year = int.parse(match.group(3)!);
            year += (year < 50) ? 2000 : 1900;
            if (_isValidDate(year, month, day)) {
              return DateTime(year, month, day);
            }
          }
        } catch (_) {}
      }
    }
    return null;
  }

  static bool _isValidDate(int year, int month, int day) {
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (year < 2000 || year > 2100) return false;
    return true;
  }
}
