import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  /// Format an integer VND amount into clean Vietnamese format e.g. "125.000 ₫"
  static String formatVND(int amount) {
    return _vndFormat.format(amount);
  }

  /// Format amount without symbol e.g. "125.000"
  static String formatCompact(int amount) {
    final format = NumberFormat('#,###', 'vi_VN');
    return format.format(amount);
  }

  /// Parse string into VND integer amount safely.
  /// Handles formats like "125000", "125,000", "125.000", "125.000,00", "125,000.00", "125k"
  static int? parseVndAmount(String input) {
    if (input.trim().isEmpty) return null;

    String clean = input.trim().toLowerCase();

    // Check shorthand 'k' e.g. 125k or 50k
    bool hasK = false;
    if (clean.endsWith('k')) {
      hasK = true;
      clean = clean.substring(0, clean.length - 1).trim();
    }

    // Remove currency symbols, trailing text like đ, vnd, đồng
    clean = clean
        .replaceAll('vnđ', '')
        .replaceAll('vnd', '')
        .replaceAll('đồng', '')
        .replaceAll('dong', '')
        .replaceAll('₫', '')
        .replaceAll('đ', '')
        .replaceAll(' ', '');

    if (clean.isEmpty) return null;

    // Handle ambiguous dot vs comma punctuation
    // Examples:
    // "125.000" -> dot is thousands separator -> 125000
    // "125,000" -> comma is thousands separator -> 125000
    // "125.000,50" -> dot is thousands, comma is decimal -> 125000
    // "125,000.50" -> comma is thousands, dot is decimal -> 125000

    if (clean.contains('.') && clean.contains(',')) {
      final dotIndex = clean.indexOf('.');
      final commaIndex = clean.indexOf(',');
      if (dotIndex < commaIndex) {
        // "125.000,50"
        clean = clean.replaceAll('.', '').split(',')[0];
      } else {
        // "125,000.50"
        clean = clean.replaceAll(',', '').split('.')[0];
      }
    } else if (clean.contains('.')) {
      final parts = clean.split('.');
      if (parts.length > 2) {
        // "1.250.000" -> multiple dots mean thousands separators
        clean = clean.replaceAll('.', '');
      } else if (parts.length == 2) {
        // Single dot e.g. "125.000" vs "125.5"
        // In Vietnamese receipts, 3 digits after dot (e.g. .000 or .500) indicate thousands separator
        if (parts[1].length == 3) {
          clean = clean.replaceAll('.', '');
        } else if (parts[1].length == 1 || parts[1].length == 2) {
          // Could be decimal 125.50 -> round to integer
          final val = double.tryParse(clean);
          if (val != null) return (val * (hasK ? 1000 : 1)).round();
          clean = parts[0];
        } else {
          clean = clean.replaceAll('.', '');
        }
      }
    } else if (clean.contains(',')) {
      final parts = clean.split(',');
      if (parts.length > 2) {
        // "1,250,000"
        clean = clean.replaceAll(',', '');
      } else if (parts.length == 2) {
        if (parts[1].length == 3) {
          clean = clean.replaceAll(',', '');
        } else {
          clean = parts[0];
        }
      }
    }

    final parsedInt = int.tryParse(clean);
    if (parsedInt != null && parsedInt >= 0) {
      return hasK ? parsedInt * 1000 : parsedInt;
    }
    return null;
  }
}
