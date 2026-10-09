import 'package:flutter_test/flutter_test.dart';
import 'package:receipttracker/core/constants/sample_qrs.dart';
import 'package:receipttracker/data/models/qr_result.dart';
import 'package:receipttracker/services/payment_qr_parser.dart';

void main() {
  group('PaymentQrParser Unit Tests', () {
    test('Parses synthetic VietQR payload correctly', () {
      final sample = SampleQrs.samples.first; // vku_canteen
      final result = PaymentQrParser.parse(sample.payload);

      expect(result.formatType, equals(QrFormatType.vietQr));
      expect(result.amount, equals(35000));
      expect(result.currency, equals('VND'));
      expect(result.bankName, equals('Techcombank'));
      expect(result.isCrcValid, isTrue);
    });

    test('Parses generic URL payload safely', () {
      const urlPayload = 'https://vku.udn.vn';
      final result = PaymentQrParser.parse(urlPayload);

      expect(result.formatType, equals(QrFormatType.genericUrl));
      expect(result.parseWarnings, isNotEmpty);
    });

    test('Handles malformed or invalid QR payloads without crashing', () {
      const invalidPayload = '123456';
      final result = PaymentQrParser.parse(invalidPayload);

      expect(result.formatType, equals(QrFormatType.genericText));
      expect(result.amount, isNull);
    });
  });
}
