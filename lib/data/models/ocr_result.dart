enum OcrConfidence { high, medium, low }

class OcrResult {
  final String? merchantName;
  final int? totalAmount;
  final DateTime? expenseDate;
  final String category;
  final int? subtotal;
  final int? taxAmount;
  final int? discountAmount;
  final String? receiptNumber;
  final String rawText;
  final OcrConfidence confidence;
  final List<String> warnings;

  // Additional Payment Screenshot fields if parsed from screenshot
  final String? bankName;
  final String? senderName;
  final String? senderAccount;
  final String? recipientName;
  final String? recipientAccount;
  final String? transactionReference;
  final String? transferDescription;

  const OcrResult({
    this.merchantName,
    this.totalAmount,
    this.expenseDate,
    this.category = 'other',
    this.subtotal,
    this.taxAmount,
    this.discountAmount,
    this.receiptNumber,
    required this.rawText,
    this.confidence = OcrConfidence.medium,
    this.warnings = const [],
    this.bankName,
    this.senderName,
    this.senderAccount,
    this.recipientName,
    this.recipientAccount,
    this.transactionReference,
    this.transferDescription,
  });

  String get confidenceString {
    switch (confidence) {
      case OcrConfidence.high:
        return 'Cao (Tin cậy)';
      case OcrConfidence.medium:
        return 'Trung bình';
      case OcrConfidence.low:
        return 'Thấp (Cần kiểm tra)';
    }
  }
}
