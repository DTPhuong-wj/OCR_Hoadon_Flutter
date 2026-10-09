import '../models/expense.dart';
import 'expense_repository.dart';

class MockExpenseRepository implements ExpenseRepository {
  final List<Expense> _expenses = [];

  @override
  Future<List<Expense>> getAllExpenses() async {
    return List.from(_expenses);
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> insertExpense(Expense expense) async {
    _expenses.removeWhere((e) => e.id == expense.id);
    _expenses.add(expense);
    return 1;
  }

  @override
  Future<int> updateExpense(Expense expense) async {
    final idx = _expenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) {
      _expenses[idx] = expense;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> deleteExpense(String id) async {
    _expenses.removeWhere((e) => e.id == id);
    return 1;
  }

  @override
  Future<void> deleteAllExpenses() async {
    _expenses.clear();
  }

  @override
  Future<List<Expense>> searchExpenses({
    String? query,
    String? category,
    String? sourceType,
    DateTime? startDate,
    DateTime? endDate,
    String sortBy = 'newest',
  }) async {
    return List.from(_expenses);
  }
}
