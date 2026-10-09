import '../../core/constants/app_constants.dart';

class Expense {
  final String id;
  final String merchantName;
  final int totalAmount;
  final DateTime expenseDate;
  final String category;
  final String? receiptImagePath;
  final String? rawOcrText;
  final int? subtotal;
  final int? taxAmount;
  final int? discountAmount;
  final String? receiptNumber;

  // New QR & Payment Module Fields
  final String sourceType;
  final String paymentStatus;
  final String verificationStatus;
  final String? transactionReference;
  final String? bankName;
  final String? senderName;
  final String? senderAccount;
  final String? recipientName;
  final String? recipientAccount;
  final String? transferDescription;
  final DateTime? transactionDatetime;
  final String currency;
  final String? originalQrPayload;
  final String? ocrConfidence;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Expense({
    required this.id,
    required this.merchantName,
    required this.totalAmount,
    required this.expenseDate,
    required this.category,
    this.receiptImagePath,
    this.rawOcrText,
    this.subtotal,
    this.taxAmount,
    this.discountAmount,
    this.receiptNumber,
    this.sourceType = AppConstants.sourceReceiptOcr,
    this.paymentStatus = AppConstants.statusUserConfirmed,
    this.verificationStatus = AppConstants.statusUserConfirmed,
    this.transactionReference,
    this.bankName,
    this.senderName,
    this.senderAccount,
    this.recipientName,
    this.recipientAccount,
    this.transferDescription,
    this.transactionDatetime,
    this.currency = 'VND',
    this.originalQrPayload,
    this.ocrConfidence,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isConfirmed =>
      paymentStatus == AppConstants.statusUserConfirmed ||
      paymentStatus == AppConstants.statusBankVerified;

  Expense copyWith({
    String? id,
    String? merchantName,
    int? totalAmount,
    DateTime? expenseDate,
    String? category,
    String? receiptImagePath,
    String? rawOcrText,
    int? subtotal,
    int? taxAmount,
    int? discountAmount,
    String? receiptNumber,
    String? sourceType,
    String? paymentStatus,
    String? verificationStatus,
    String? transactionReference,
    String? bankName,
    String? senderName,
    String? senderAccount,
    String? recipientName,
    String? recipientAccount,
    String? transferDescription,
    DateTime? transactionDatetime,
    String? currency,
    String? originalQrPayload,
    String? ocrConfidence,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      totalAmount: totalAmount ?? this.totalAmount,
      expenseDate: expenseDate ?? this.expenseDate,
      category: category ?? this.category,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      sourceType: sourceType ?? this.sourceType,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      transactionReference: transactionReference ?? this.transactionReference,
      bankName: bankName ?? this.bankName,
      senderName: senderName ?? this.senderName,
      senderAccount: senderAccount ?? this.senderAccount,
      recipientName: recipientName ?? this.recipientName,
      recipientAccount: recipientAccount ?? this.recipientAccount,
      transferDescription: transferDescription ?? this.transferDescription,
      transactionDatetime: transactionDatetime ?? this.transactionDatetime,
      currency: currency ?? this.currency,
      originalQrPayload: originalQrPayload ?? this.originalQrPayload,
      ocrConfidence: ocrConfidence ?? this.ocrConfidence,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant_name': merchantName,
      'total_amount': totalAmount,
      'expense_date': expenseDate.toIso8601String(),
      'category': category,
      'receipt_image_path': receiptImagePath,
      'raw_ocr_text': rawOcrText,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'receipt_number': receiptNumber,
      'source_type': sourceType,
      'payment_status': paymentStatus,
      'verification_status': verificationStatus,
      'transaction_reference': transactionReference,
      'bank_name': bankName,
      'sender_name': senderName,
      'sender_account': senderAccount,
      'recipient_name': recipientName,
      'recipient_account': recipientAccount,
      'transfer_description': transferDescription,
      'transaction_datetime': transactionDatetime?.toIso8601String(),
      'currency': currency,
      'original_qr_payload': originalQrPayload,
      'ocr_confidence': ocrConfidence,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      merchantName: map['merchant_name'] as String,
      totalAmount: (map['total_amount'] as num).toInt(),
      expenseDate: DateTime.parse(map['expense_date'] as String),
      category: map['category'] as String,
      receiptImagePath: map['receipt_image_path'] as String?,
      rawOcrText: map['raw_ocr_text'] as String?,
      subtotal: (map['subtotal'] as num?)?.toInt(),
      taxAmount: (map['tax_amount'] as num?)?.toInt(),
      discountAmount: (map['discount_amount'] as num?)?.toInt(),
      receiptNumber: map['receipt_number'] as String?,
      sourceType:
          (map['source_type'] as String?) ?? AppConstants.sourceReceiptOcr,
      paymentStatus:
          (map['payment_status'] as String?) ??
          AppConstants.statusUserConfirmed,
      verificationStatus:
          (map['verification_status'] as String?) ??
          AppConstants.statusUserConfirmed,
      transactionReference: map['transaction_reference'] as String?,
      bankName: map['bank_name'] as String?,
      senderName: map['sender_name'] as String?,
      senderAccount: map['sender_account'] as String?,
      recipientName: map['recipient_name'] as String?,
      recipientAccount: map['recipient_account'] as String?,
      transferDescription: map['transfer_description'] as String?,
      transactionDatetime: map['transaction_datetime'] != null
          ? DateTime.parse(map['transaction_datetime'] as String)
          : null,
      currency: (map['currency'] as String?) ?? 'VND',
      originalQrPayload: map['original_qr_payload'] as String?,
      ocrConfidence: map['ocr_confidence'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
