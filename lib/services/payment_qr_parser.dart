import '../data/models/qr_result.dart';

class PaymentQrParser {
  /// Parse raw string payload into structured QrResult
  static QrResult parse(String rawPayload) {
    final cleanPayload = rawPayload.trim();
    if (cleanPayload.isEmpty) {
      return const QrResult(
        rawPayload: '',
        formatType: QrFormatType.unknown,
        parseWarnings: ['Mã QR rỗng.'],
      );
    }

    // Check if URL
    if (cleanPayload.startsWith('http://') ||
        cleanPayload.startsWith('https://')) {
      return QrResult(
        rawPayload: cleanPayload,
        formatType: QrFormatType.genericUrl,
        paymentDescription: 'Liên kết Web: $cleanPayload',
        parseWarnings: [
          'Đây là một liên kết Web. Vui lòng cẩn thận trước khi mở.',
        ],
      );
    }

    // Check if EMVCo / VietQR format (starts with "000201")
    if (cleanPayload.startsWith('000201') || cleanPayload.startsWith('0002')) {
      return _parseEmvCo(cleanPayload);
    }

    return QrResult(
      rawPayload: cleanPayload,
      formatType: QrFormatType.genericText,
      paymentDescription: cleanPayload,
      parseWarnings: ['Không phát hiện được định dạng chuẩn VietQR/EMVCo.'],
    );
  }

  static QrResult _parseEmvCo(String payload) {
    final tlvMap = _parseTlv(payload);
    final warnings = <String>[];

    // Check CRC if Tag 63 exists
    bool isCrcValid = true;
    if (tlvMap.containsKey('63')) {
      isCrcValid = _validateCrc(payload);
      if (!isCrcValid) {
        warnings.add('Cảnh báo: Mã CRC của QR không khớp hoặc bị thay đổi.');
      }
    }

    // Extract Merchant Account Information (Tag 38 or Tag 26..51)
    String? bankBin;
    String? bankName;
    String? beneficiaryAccount;
    String? beneficiaryName;

    // Check Tag 38 (VietQR format)
    if (tlvMap.containsKey('38')) {
      final tag38SubTlv = _parseTlv(tlvMap['38']!);
      if (tag38SubTlv.containsKey('00')) {
        // GUID A000000727 or similar
      }
      if (tag38SubTlv.containsKey('01')) {
        // Service code + Bank BIN + Account
        final serviceData = tag38SubTlv['01']!;
        final serviceSubTlv = _parseTlv(serviceData);
        bankBin = serviceSubTlv['00'];
        beneficiaryAccount = serviceSubTlv['01'];
      }
    }

    // Tag 59: Beneficiary Name
    beneficiaryName = tlvMap['59'];

    // Tag 54: Amount
    int? amount;
    if (tlvMap.containsKey('54')) {
      final amountStr = tlvMap['54']!;
      final parsedDouble = double.tryParse(amountStr);
      if (parsedDouble != null) {
        amount = parsedDouble.round();
      }
    }

    // Tag 53: Currency (704 = VND)
    String currency = 'VND';
    if (tlvMap.containsKey('53')) {
      if (tlvMap['53'] == '704') {
        currency = 'VND';
      } else if (tlvMap['53'] == '840') {
        currency = 'USD';
      }
    }

    // Tag 62: Additional Data Field
    String? paymentDescription;
    String? billReference;
    if (tlvMap.containsKey('62')) {
      final tag62SubTlv = _parseTlv(tlvMap['62']!);
      paymentDescription =
          tag62SubTlv['08'] ?? tag62SubTlv['05'] ?? tag62SubTlv['01'];
      billReference = tag62SubTlv['01'] ?? tag62SubTlv['05'];
    }

    // Bank BIN to Name mapping helper
    if (bankBin != null) {
      bankName = _getBankNameFromBin(bankBin);
    }

    final isVietQr =
        (tlvMap.containsKey('38') && tlvMap['38']!.contains('A000000727'));

    return QrResult(
      rawPayload: payload,
      formatType: isVietQr ? QrFormatType.vietQr : QrFormatType.emvCo,
      bankBin: bankBin,
      bankName: bankName,
      beneficiaryAccount: beneficiaryAccount,
      beneficiaryName: beneficiaryName,
      amount: amount,
      currency: currency,
      paymentDescription: paymentDescription ?? 'Thanh toán qua QR',
      billReference: billReference,
      isCrcValid: isCrcValid,
      isPaymentRequest:
          true, // QR payloads are payment requests, require user verification
      parseWarnings: warnings,
    );
  }

  /// Parses TLV string format (Tag 2 chars, Length 2 chars, Value L chars)
  static Map<String, String> _parseTlv(String input) {
    final result = <String, String>{};
    int index = 0;

    while (index + 4 <= input.length) {
      final tag = input.substring(index, index + 2);
      final lengthStr = input.substring(index + 2, index + 4);
      final length = int.tryParse(lengthStr);

      if (length == null) break;

      final actualLength = (index + 4 + length <= input.length)
          ? length
          : (input.length - index - 4);

      if (actualLength < 0) break;

      final value = input.substring(index + 4, index + 4 + actualLength);
      result[tag] = value;
      index += 4 + actualLength;
    }

    return result;
  }

  /// CRC16 CCITT-FALSE Checksum validation
  static bool _validateCrc(String payload) {
    if (!payload.contains('6304')) return false;

    final crcIndex = payload.lastIndexOf('6304');
    final dataToCrc = payload.substring(0, crcIndex + 4);
    final expectedCrc = payload.substring(crcIndex + 4).toUpperCase();

    final calculatedCrc = _calculateCrc16(dataToCrc);
    return calculatedCrc == expectedCrc;
  }

  static String _calculateCrc16(String str) {
    int crc = 0xFFFF;
    final bytes = str.codeUnits;

    for (final byte in bytes) {
      crc ^= (byte << 8);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).padLeft(4, '0').toUpperCase();
  }

  static String _getBankNameFromBin(String bin) {
    switch (bin) {
      case '970436':
        return 'Vietcombank';
      case '970415':
        return 'VietinBank';
      case '970418':
        return 'BIDV';
      case '970405':
        return 'Agribank';
      case '970422':
        return 'MBBank';
      case '970407':
        return 'Techcombank';
      case '970423':
        return 'TPBank';
      case '970432':
        return 'VPBank';
      case '970416':
        return 'ACB';
      case '970437':
        return 'HDBank';
      case '970441':
        return 'VIB';
      case '970443':
        return 'SHB';
      case '970431':
        return 'Eximbank';
      case '970426':
        return 'MSB';
      default:
        return 'Ngân hàng ($bin)';
    }
  }
}
