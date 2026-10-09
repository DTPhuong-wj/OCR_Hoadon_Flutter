enum QrFormatType { vietQr, emvCo, genericUrl, genericText, unknown }

class QrResult {
  final String rawPayload;
  final QrFormatType formatType;
  final String? bankBin;
  final String? bankName;
  final String? beneficiaryAccount;
  final String? beneficiaryName;
  final int? amount;
  final String currency;
  final String? paymentDescription;
  final String? billReference;
  final bool isCrcValid;
  final bool isPaymentRequest;
  final List<String> parseWarnings;

  const QrResult({
    required this.rawPayload,
    required this.formatType,
    this.bankBin,
    this.bankName,
    this.beneficiaryAccount,
    this.beneficiaryName,
    this.amount,
    this.currency = 'VND',
    this.paymentDescription,
    this.billReference,
    this.isCrcValid = true,
    this.isPaymentRequest = true,
    this.parseWarnings = const [],
  });
}
