import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/expense.dart';
import '../data/repositories/expense_repository.dart';

// Repository Provider
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return SqfliteExpenseRepository();
});

// Search, Filter & Sort State Class
class ExpenseFilterState {
  final String query;
  final String category;
  final String sourceType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String sortBy;

  const ExpenseFilterState({
    this.query = '',
    this.category = 'all',
    this.sourceType = 'all',
    this.startDate,
    this.endDate,
    this.sortBy = 'newest',
  });

  ExpenseFilterState copyWith({
    String? query,
    String? category,
    String? sourceType,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
  }) {
    return ExpenseFilterState(
      query: query ?? this.query,
      category: category ?? this.category,
      sourceType: sourceType ?? this.sourceType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

final expenseFilterProvider = StateProvider<ExpenseFilterState>(
  (ref) => const ExpenseFilterState(),
);

// Expense List Notifier
class ExpenseListNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  final ExpenseRepository _repository;

  ExpenseListNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    state = const AsyncValue.loading();
    try {
      final expenses = await _repository.getAllExpenses();
      state = AsyncValue.data(expenses);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> addExpense(Expense expense) async {
    try {
      await _repository.insertExpense(expense);
      await loadExpenses();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateExpense(Expense expense) async {
    try {
      await _repository.updateExpense(expense);
      await loadExpenses();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      await _repository.deleteExpense(id);
      await loadExpenses();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAll() async {
    try {
      await _repository.deleteAllExpenses();
      await loadExpenses();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final expenseListNotifierProvider =
    StateNotifierProvider<ExpenseListNotifier, AsyncValue<List<Expense>>>((
      ref,
    ) {
      final repo = ref.watch(expenseRepositoryProvider);
      return ExpenseListNotifier(repo);
    });

// Filtered Expenses Provider
final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final expensesAsync = ref.watch(expenseListNotifierProvider);
  final filters = ref.watch(expenseFilterProvider);

  return expensesAsync.maybeWhen(
    data: (expenses) {
      var result = expenses.where((e) {
        // Exclude unconfirmed pending drafts from confirmed lists if needed
        // Search query
        if (filters.query.isNotEmpty) {
          final q = filters.query.toLowerCase();
          final matchesMerchant = e.merchantName.toLowerCase().contains(q);
          final matchesDesc =
              e.transferDescription?.toLowerCase().contains(q) ?? false;
          final matchesRef =
              e.transactionReference?.toLowerCase().contains(q) ?? false;
          if (!matchesMerchant && !matchesDesc && !matchesRef) return false;
        }

        // Category filter
        if (filters.category != 'all' && e.category != filters.category) {
          return false;
        }

        // Source type filter
        if (filters.sourceType != 'all' && e.sourceType != filters.sourceType) {
          return false;
        }

        // Date range
        if (filters.startDate != null) {
          if (e.expenseDate.isBefore(filters.startDate!)) return false;
        }
        if (filters.endDate != null) {
          final endOfDay = DateTime(
            filters.endDate!.year,
            filters.endDate!.month,
            filters.endDate!.day,
            23,
            59,
            59,
          );
          if (e.expenseDate.isAfter(endOfDay)) return false;
        }

        return true;
      }).toList();

      // Sorting
      switch (filters.sortBy) {
        case 'oldest':
          result.sort((a, b) => a.expenseDate.compareTo(b.expenseDate));
          break;
        case 'amount_high':
          result.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
          break;
        case 'amount_low':
          result.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
          break;
        case 'newest':
        default:
          result.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
          break;
      }

      return result;
    },
    orElse: () => [],
  );
});

// Dashboard Stats Data Model
class DashboardStats {
  final int currentMonthTotal;
  final int currentWeekTotal;
  final int receiptCount;
  final List<Expense> recentExpenses;
  final Map<String, int> categoryTotals;

  const DashboardStats({
    required this.currentMonthTotal,
    required this.currentWeekTotal,
    required this.receiptCount,
    required this.recentExpenses,
    required this.categoryTotals,
  });
}

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final expensesAsync = ref.watch(expenseListNotifierProvider);

  return expensesAsync.maybeWhen(
    data: (expenses) {
      final now = DateTime.now();

      int monthTotal = 0;
      int weekTotal = 0;

      // Start of current week (Monday)
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final weekBegin = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );

      final categoryTotals = <String, int>{};

      for (final exp in expenses) {
        // Exclude unconfirmed pending requests from total spent
        if (!exp.isConfirmed) continue;

        if (exp.expenseDate.year == now.year &&
            exp.expenseDate.month == now.month) {
          monthTotal += exp.totalAmount;
          categoryTotals[exp.category] =
              (categoryTotals[exp.category] ?? 0) + exp.totalAmount;
        }

        if (exp.expenseDate.isAfter(
          weekBegin.subtract(const Duration(seconds: 1)),
        )) {
          weekTotal += exp.totalAmount;
        }
      }

      final recent = expenses.take(5).toList();

      return DashboardStats(
        currentMonthTotal: monthTotal,
        currentWeekTotal: weekTotal,
        receiptCount: expenses.length,
        recentExpenses: recent,
        categoryTotals: categoryTotals,
      );
    },
    orElse: () => const DashboardStats(
      currentMonthTotal: 0,
      currentWeekTotal: 0,
      receiptCount: 0,
      recentExpenses: [],
      categoryTotals: {},
    ),
  );
});
