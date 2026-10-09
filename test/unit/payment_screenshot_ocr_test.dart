import 'package:flutter_test/flutter_test.dart';
import 'package:receipttracker/services/payment_screenshot_ocr_service.dart';

void main() {
  late PaymentScreenshotOcrService service;

  setUp(() {
    service = PaymentScreenshotOcrService();
  });

  group('PaymentScreenshotOcrService Unit Tests', () {
    test('Parses bank transfer screenshot text successfully', () {
      const screenshotText = '''
Chuyển tiền thành công
Số tiền: 50.000 VND
Người nhận: NGUYEN VAN A
Tài khoản: 97042300009999
Ngân hàng: TPBank
Mã giao dịch: FT262839102
Thời gian: 10/10/2026 14:30
Nội dung: Dong quy CLB IT VKU
''';

      final result = service.parseScreenshotText(screenshotText);

      expect(result.totalAmount, equals(50000));
      expect(result.recipientName, equals('NGUYEN VAN A'));
      expect(result.bankName, equals('TPBank'));
      expect(result.transactionReference, equals('FT262839102'));
      expect(result.transferDescription, equals('Dong quy CLB IT VKU'));
      expect(result.warnings, isNotEmpty); // Disclaimer warning included
    });
  });
}
