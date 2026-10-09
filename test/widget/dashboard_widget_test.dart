import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipttracker/app.dart';
import 'package:receipttracker/data/repositories/mock_expense_repository.dart';
import 'package:receipttracker/providers/expense_providers.dart';

void main() {
  testWidgets('Dashboard renders greeting and quick action buttons',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider.overrideWithValue(MockExpenseRepository()),
        ],
        child: const ReceiptTrackerApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('Xin chào'), findsOneWidget);
    expect(find.text('Quét Hóa Đơn'), findsOneWidget);
    expect(find.text('Scan QR / Bank'), findsOneWidget);
  });
}
