import 'package:flutter_test/flutter_test.dart';
import 'package:receipttracker/core/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Unit Tests', () {
    test('Parses various Vietnamese currency string formats', () {
      expect(CurrencyFormatter.parseVndAmount('125000'), equals(125000));
      expect(CurrencyFormatter.parseVndAmount('125,000'), equals(125000));
      expect(CurrencyFormatter.parseVndAmount('125.000'), equals(125000));
      expect(CurrencyFormatter.parseVndAmount('125.000 đ'), equals(125000));
      expect(CurrencyFormatter.parseVndAmount('125,000 VNĐ'), equals(125000));
      expect(CurrencyFormatter.parseVndAmount('125k'), equals(125000));
      expect(CurrencyFormatter.parseVndAmount('35k'), equals(35000));
    });

    test('Formats VND currency properly', () {
      final formatted = CurrencyFormatter.formatVND(125000);
      expect(formatted.contains('125'), isTrue);
      expect(formatted.contains('₫'), isTrue);
    });
  });
}
