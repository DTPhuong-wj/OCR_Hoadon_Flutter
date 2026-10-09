import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/ocr_result.dart';

class ReceiptParser {
  /// Parse raw OCR text into a structured OcrResult
  OcrResult parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const OcrResult(
        rawText: '',
        confidence: OcrConfidence.low,
        warnings: ['Không tìm thấy văn bản trong hình ảnh.'],
      );
    }

    final warnings = <String>[];

    // 1. Merchant Name Extraction
    final merchantName = _extractMerchantName(lines);

    // 2. Receipt Date Extraction
    final receiptDate = _extractDate(lines, rawText);

    // 3. Category Categorization
    final category = _inferCategory(merchantName, rawText);

    // 4. Receipt Number Extraction
    final receiptNumber = _extractReceiptNumber(lines);

    // 5. Total Amount Extraction with Candidates & Scoring
    final totalCandidate = _extractTotalAmount(lines);
    final totalAmount = totalCandidate?.amount;

    // 6. Subtotal, Tax, Discount
    final subtotal = _extractSubtotal(lines);
    final taxAmount = _extractTax(lines);
    final discountAmount = _extractDiscount(lines);

    // 7. Calculate Confidence
    OcrConfidence confidence = OcrConfidence.medium;
    if (totalCandidate != null &&
        totalCandidate.score >= 80 &&
        merchantName != null) {
      confidence = OcrConfidence.high;
    } else if (totalCandidate == null || totalCandidate.score < 40) {
      confidence = OcrConfidence.low;
      warnings.add('Không chắc chắn về tổng số tiền. Vui lòng kiểm tra lại.');
    }

    if (merchantName == null || merchantName.isEmpty) {
      warnings.add('Không tìm thấy tên cửa hàng.');
    }

    if (receiptDate == null) {
      warnings.add('Không tìm thấy ngày trên hóa đơn.');
    }

    return OcrResult(
      merchantName: merchantName ?? 'Cửa Hàng / Nhà Cung Cấp',
      totalAmount: totalAmount,
      expenseDate: receiptDate ?? DateTime.now(),
      category: category,
      subtotal: subtotal,
      taxAmount: taxAmount,
      discountAmount: discountAmount,
      receiptNumber: receiptNumber,
      rawText: rawText,
      confidence: confidence,
      warnings: warnings,
    );
  }

  String? _extractMerchantName(List<String> lines) {
    // Top 3 non-header lines usually contain merchant name
    final ignoredKeywords = [
      'hóa đơn',
      'hoa don',
      'receipt',
      'bien nhan',
      'biên nhận',
      'ngày',
      'date',
      'tel',
      'phone',
      'mst',
      'stt',
    ];

    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (ignoredKeywords.any((keyword) => lower.contains(keyword))) {
        continue;
      }
      if (line.length >= 3 && !RegExp(r'^\d+$').hasMatch(line)) {
        return line;
      }
    }
    return lines.first;
  }

  DateTime? _extractDate(List<String> lines, String rawText) {
    // Look for lines containing "ngày", "date"
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('ngày') ||
          lower.contains('date') ||
          lower.contains('ngay')) {
        final parsed = DateFormatter.parseReceiptDate(line);
        if (parsed != null) return parsed;
      }
    }
    // Fallback: search anywhere in rawText
    return DateFormatter.parseReceiptDate(rawText);
  }

  String _inferCategory(String? merchant, String rawText) {
    final text = '${merchant ?? ""} $rawText'.toLowerCase();

    if (text.contains('căn tin') ||
        text.contains('cơm') ||
        text.contains('café') ||
        text.contains('coffee') ||
        text.contains('highlands') ||
        text.contains('phúc long') ||
        text.contains('trà sữa') ||
        text.contains('quán ăn') ||
        text.contains('nhà hàng') ||
        text.contains('bún') ||
        text.contains('phở')) {
      return 'food';
    } else if (text.contains('vku') ||
        text.contains('học phí') ||
        text.contains('giáo trình') ||
        text.contains('trường') ||
        text.contains('sách')) {
      return 'education';
    } else if (text.contains('clb') ||
        text.contains('câu lạc bộ') ||
        text.contains('quỹ clb') ||
        text.contains('sự kiện')) {
      return 'club';
    } else if (text.contains('winmart') ||
        text.contains('co.op') ||
        text.contains('bách hóa') ||
        text.contains('siêu thị') ||
        text.contains('circle k') ||
        text.contains('7-eleven')) {
      return 'shopping';
    } else if (text.contains('in') ||
        text.contains('photocopy') ||
        text.contains('văn phòng phẩm') ||
        text.contains('giấy')) {
      return 'office';
    } else if (text.contains('xe') ||
        text.contains('gửi xe') ||
        text.contains('xăng') ||
        text.contains('grab') ||
        text.contains('be') ||
        text.contains('taxi')) {
      return 'transport';
    }

    return 'other';
  }

  String? _extractReceiptNumber(List<String> lines) {
    final pattern = RegExp(
      r'(?:số hd|hd số|số|receipt no|inv no|no\.)\s*[:\.\-]?\s*([a-zA-Z0-9\-]+)',
      caseSensitive: false,
    );
    for (final line in lines) {
      final match = pattern.firstMatch(line);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  _TotalCandidate? _extractTotalAmount(List<String> lines) {
    final candidates = <_TotalCandidate>[];

    final totalKeywords = [
      'tổng cộng',
      'tong cong',
      'tổng thanh toán',
      'tong thanh toan',
      'thành tiền',
      'thanh tien',
      'total payment',
      'grand total',
      'amount due',
      'total',
    ];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      for (final keyword in totalKeywords) {
        if (lower.contains(keyword)) {
          int score = 70;
          if (keyword == 'tổng cộng' ||
              keyword == 'tong cong' ||
              keyword == 'tổng thanh toán') {
            score = 90;
          }

          // Search amount on current line or next line
          var amountStr = _extractNumberSubstring(line);
          if (amountStr == null && i + 1 < lines.length) {
            amountStr = _extractNumberSubstring(lines[i + 1]);
          }

          if (amountStr != null) {
            final parsed = CurrencyFormatter.parseVndAmount(amountStr);
            if (parsed != null && _isValidTotalAmount(parsed, line)) {
              candidates.add(_TotalCandidate(amount: parsed, score: score));
            }
          }
        }
      }
    }

    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => b.score.compareTo(a.score));
      return candidates.first;
    }

    // Fallback: search for numbers with VND currency markers
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('đ') || lower.contains('vnd') || lower.contains('₫')) {
        final amountStr = _extractNumberSubstring(line);
        if (amountStr != null) {
          final parsed = CurrencyFormatter.parseVndAmount(amountStr);
          if (parsed != null && _isValidTotalAmount(parsed, line)) {
            candidates.add(_TotalCandidate(amount: parsed, score: 50));
          }
        }
      }
    }

    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => b.amount.compareTo(a.amount));
      return candidates.first;
    }

    return null;
  }

  int? _extractSubtotal(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('cộng tiền hàng') ||
          lower.contains('subtotal') ||
          lower.contains('tiền hàng')) {
        final numStr = _extractNumberSubstring(line);
        if (numStr != null) return CurrencyFormatter.parseVndAmount(numStr);
      }
    }
    return null;
  }

  int? _extractTax(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('vat') ||
          lower.contains('thuế') ||
          lower.contains('tax')) {
        final numStr = _extractNumberSubstring(line);
        if (numStr != null) return CurrencyFormatter.parseVndAmount(numStr);
      }
    }
    return null;
  }

  int? _extractDiscount(List<String> lines) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('chiết khấu') ||
          lower.contains('giảm giá') ||
          lower.contains('discount')) {
        final numStr = _extractNumberSubstring(line);
        if (numStr != null) return CurrencyFormatter.parseVndAmount(numStr);
      }
    }
    return null;
  }

  String? _extractNumberSubstring(String line) {
    final pattern = RegExp(
      r'\b\d{1,3}(?:[\.,]\d{3})*(?:[\.,]\d{1,2})?\b|\b\d{4,9}\b',
    );
    final matches = pattern.allMatches(line);
    if (matches.isNotEmpty) {
      return matches.last.group(0);
    }
    return null;
  }

  bool _isValidTotalAmount(int amount, String line) {
    // Reject amounts that look like phone numbers (e.g., 0905..., 038...)
    if (amount >= 300000000 && amount <= 999999999) return false;
    // Reject amounts that look like years or tax codes (e.g. 2024, 2026)
    if (amount >= 2000 && amount <= 2030) return false;
    // Minimum plausible VND expense amount (e.g., 500 VND)
    if (amount < 500) return false;
    return true;
  }
}

class _TotalCandidate {
  final int amount;
  final int score;

  _TotalCandidate({required this.amount, required this.score});
}
