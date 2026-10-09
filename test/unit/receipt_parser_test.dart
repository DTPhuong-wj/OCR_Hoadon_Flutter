import 'package:flutter_test/flutter_test.dart';
import 'package:receipttracker/data/models/ocr_result.dart';
import 'package:receipttracker/services/receipt_parser.dart';

void main() {
  late ReceiptParser parser;

  setUp(() {
    parser = ReceiptParser();
  });

  group('ReceiptParser Unit Tests', () {
    test('Parses standard Vietnamese canteen receipt correctly', () {
      const sampleOcrText = '''
CĂN TIN TRƯỜNG ĐẠI HỌC VKU
Địa chỉ: KĐT Phong Nam, Đà Nẵng
HÓA ĐƠN BÁN HÀNG
Ngày: 10/10/2026
1. Cơm gà chiên mắm: 30.000
2. Trà đá: 5.000
TỔNG CỘNG: 35.000 VNĐ
Cảm ơn quý khách!
''';

      final result = parser.parse(sampleOcrText);

      expect(result.merchantName, equals('CĂN TIN TRƯỜNG ĐẠI HỌC VKU'));
      expect(result.totalAmount, equals(35000));
      expect(result.category, equals('food'));
      expect(result.expenseDate!.day, equals(10));
      expect(result.expenseDate!.month, equals(10));
      expect(result.expenseDate!.year, equals(2026));
      expect(result.confidence, equals(OcrConfidence.high));
    });

    test('Parses paper receipt with TỔNG THANH TOÁN and thousands dots', () {
      const sampleOcrText = '''
TIỆM IN ẤN GIÁO TRÌNH VKU
SĐT: 0905123456
Số HD: HD001928
Ngày: 05/10/2026
In giáo trình Flutter: 120.000 đ
TỔNG THANH TOÁN: 120.000 đ
''';

      final result = parser.parse(sampleOcrText);

      expect(result.merchantName, equals('TIỆM IN ẤN GIÁO TRÌNH VKU'));
      expect(result.totalAmount, equals(120000));
      expect(result.receiptNumber, equals('HD001928'));
    });

    test('Rejects phone numbers and tax IDs as total amount', () {
      const noisyText = '''
SIÊU THỊ WINMART
MST: 0401234567
Tel: 0905999888
Ngày: 01/10/2026
Mặt hàng A: 50.000
THÀNH TIỀN: 50.000
''';

      final result = parser.parse(noisyText);

      expect(result.totalAmount, equals(50000));
      expect(result.totalAmount, isNot(equals(401234567)));
      expect(result.totalAmount, isNot(equals(905999888)));
    });

    test('Handles empty or noisy text gracefully', () {
      const emptyText = '   \n  ';
      final result = parser.parse(emptyText);

      expect(result.totalAmount, isNull);
      expect(result.confidence, equals(OcrConfidence.low));
      expect(result.warnings, isNotEmpty);
    });
  });
}
