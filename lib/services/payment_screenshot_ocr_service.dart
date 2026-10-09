import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../data/models/ocr_result.dart';
import 'ocr_service.dart';

class PaymentScreenshotOcrService {
  final OcrService _ocrService;

  PaymentScreenshotOcrService({OcrService? ocrService})
    : _ocrService = ocrService ?? OcrService();

  Future<OcrResult> processScreenshot(String imagePath) async {
    final rawText = await _ocrService.recognizeTextFromImagePath(imagePath);
    return parseScreenshotText(rawText);
  }

  OcrResult parseScreenshotText(String rawText) {
    final lines = rawText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return const OcrResult(
        rawText: '',
        confidence: OcrConfidence.low,
        warnings: ['Không tìm thấy chữ trong ảnh chuyển khoản.'],
      );
    }

    final warnings = <String>[
      'Thông tin được trích xuất từ ảnh. Vui lòng kiểm tra với ứng dụng ngân hàng trước khi xác nhận.',
    ];

    int? totalAmount;
    DateTime? expenseDate;
    String? recipientName;
    String? recipientAccount;
    String? senderName;
    String? senderAccount;
    String? bankName;
    String? transactionReference;
    String? transferDescription;

    // Check for success status keywords
    final hasSuccessKeyword = lines.any((line) {
      final lower = line.toLowerCase();
      return lower.contains('thành công') ||
          lower.contains('giao dịch thành công') ||
          lower.contains('successful') ||
          lower.contains('completed');
    });

    if (!hasSuccessKeyword) {
      warnings.add(
        'Không tìm thấy trạng thái "Giao dịch thành công" rõ ràng trên ảnh.',
      );
    }

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();

      // Amount extraction (Số tiền / Số tiền giao dịch / Transfer amount)
      if (totalAmount == null &&
          (lower.contains('số tiền') ||
              lower.contains('so tien') ||
              lower.contains('giá trị') ||
              lower.contains('transfer amount'))) {
        var numStr = _extractNumber(line);
        if (numStr == null && i + 1 < lines.length) {
          numStr = _extractNumber(lines[i + 1]);
        }
        if (numStr != null) {
          totalAmount = CurrencyFormatter.parseVndAmount(numStr);
        }
      }

      // Recipient / Beneficiary (Người nhận / Tài khoản thụ hưởng)
      if (recipientName == null &&
          (lower.contains('người nhận') ||
              lower.contains('nguoi nhan') ||
              lower.contains('tên người nhận') ||
              lower.contains('beneficiary'))) {
        var val = _extractValueAfterColon(line);
        if (val == null && i + 1 < lines.length) {
          val = lines[i + 1];
        }
        if (val != null && val.length >= 2) {
          recipientName = val;
        }
      }

      // Bank Name (Ngân hàng thụ hưởng / Ngân hàng nhận)
      if (bankName == null &&
          (lower.contains('ngân hàng') ||
              lower.contains('ngan hang') ||
              lower.contains('bank'))) {
        var val = _extractValueAfterColon(line);
        if (val == null && i + 1 < lines.length) {
          val = lines[i + 1];
        }
        if (val != null) bankName = val;
      }

      // Recipient Account (Số tài khoản / Tài khoản nhận)
      if (recipientAccount == null &&
          (lower.contains('tài khoản') || lower.contains('stk'))) {
        var val = _extractNumber(line);
        if (val == null && i + 1 < lines.length) {
          val = _extractNumber(lines[i + 1]);
        }
        if (val != null && val.length >= 6) {
          recipientAccount = val;
        }
      }

      // Sender (Người chuyển / Tài khoản chuyển)
      if (senderName == null &&
          (lower.contains('người chuyển') || lower.contains('nguoi chuyen'))) {
        var val = _extractValueAfterColon(line);
        if (val == null && i + 1 < lines.length) {
          val = lines[i + 1];
        }
        if (val != null) senderName = val;
      }

      // Transaction ID / Reference (Mã giao dịch / Reference number)
      if (transactionReference == null &&
          (lower.contains('mã giao dịch') ||
              lower.contains('ma gd') ||
              lower.contains('ref') ||
              lower.contains('mã gd') ||
              lower.contains('transaction id'))) {
        var val = _extractValueAfterColon(line);
        if (val == null && i + 1 < lines.length) {
          val = lines[i + 1];
        }
        if (val != null) transactionReference = val;
      }

      // Transfer Description (Nội dung chuyển khoản / Nội dung)
      if (transferDescription == null &&
          (lower.contains('nội dung') || lower.contains('noi dung'))) {
        var val = _extractValueAfterColon(line);
        if (val == null && i + 1 < lines.length) {
          val = lines[i + 1];
        }
        if (val != null) transferDescription = val;
      }

      // Date / Timestamp
      if (expenseDate == null &&
          (lower.contains('thời gian') ||
              lower.contains('ngày') ||
              lower.contains('date') ||
              lower.contains('năm'))) {
        expenseDate = DateFormatter.parseReceiptDate(line);
      }
    }

    // Fallback amount search if label was missing
    if (totalAmount == null) {
      for (final line in lines) {
        if (line.contains('đ') || line.contains('VND') || line.contains('₫')) {
          final numStr = _extractNumber(line);
          if (numStr != null) {
            final parsed = CurrencyFormatter.parseVndAmount(numStr);
            if (parsed != null && parsed >= 1000) {
              totalAmount = parsed;
              break;
            }
          }
        }
      }
    }

    final confidence = (totalAmount != null && hasSuccessKeyword)
        ? OcrConfidence.high
        : OcrConfidence.medium;

    return OcrResult(
      merchantName: recipientName ?? bankName ?? 'Chuyển khoản Ngân hàng',
      totalAmount: totalAmount,
      expenseDate: expenseDate ?? DateTime.now(),
      category: 'other',
      rawText: rawText,
      confidence: confidence,
      warnings: warnings,
      bankName: bankName,
      senderName: senderName,
      senderAccount: senderAccount,
      recipientName: recipientName,
      recipientAccount: recipientAccount,
      transactionReference: transactionReference,
      transferDescription: transferDescription,
    );
  }

  String? _extractNumber(String line) {
    final pattern = RegExp(
      r'\b\d{1,3}(?:[\.,]\d{3})*(?:[\.,]\d{1,2})?\b|\b\d{4,12}\b',
    );
    final matches = pattern.allMatches(line);
    if (matches.isNotEmpty) {
      return matches.last.group(0);
    }
    return null;
  }

  String? _extractValueAfterColon(String line) {
    if (line.contains(':')) {
      final parts = line.split(':');
      if (parts.length > 1 && parts[1].trim().isNotEmpty) {
        return parts[1].trim();
      }
    }
    return null;
  }
}
