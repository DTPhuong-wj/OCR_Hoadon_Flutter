import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getAllExpenses();
  Future<Expense?> getExpenseById(String id);
  Future<int> insertExpense(Expense expense);
  Future<int> updateExpense(Expense expense);
  Future<int> deleteExpense(String id);
  Future<void> deleteAllExpenses();
  Future<List<Expense>> searchExpenses({
    String? query,
    String? category,
    String? sourceType,
    DateTime? startDate,
    DateTime? endDate,
    String sortBy = 'newest', // 'newest', 'oldest', 'amount_high', 'amount_low'
  });
}

class SqfliteExpenseRepository implements ExpenseRepository {
  final AppDatabase _dbHelper;

  SqfliteExpenseRepository({AppDatabase? dbHelper})
    : _dbHelper = dbHelper ?? AppDatabase.instance;

  @override
  Future<List<Expense>> getAllExpenses() async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'expenses',
      orderBy: 'expense_date DESC, created_at DESC',
    );
    return maps.map((map) => Expense.fromMap(map)).toList();
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<int> insertExpense(Expense expense) async {
    final db = await _dbHelper.database;
    return await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<int> updateExpense(Expense expense) async {
    final db = await _dbHelper.database;
    final updated = expense.copyWith(updatedAt: DateTime.now());
    return await db.update(
      'expenses',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  @override
  Future<int> deleteExpense(String id) async {
    final db = await _dbHelper.database;
    final expense = await getExpenseById(id);

    if (expense?.receiptImagePath != null) {
      try {
        final imageFile = File(expense!.receiptImagePath!);
        if (await imageFile.exists()) {
          // Verify no other expense points to the exact same image before deleting
          final db = await _dbHelper.database;
          final duplicates = await db.query(
            'expenses',
            where: 'receipt_image_path = ? AND id != ?',
            whereArgs: [expense.receiptImagePath, id],
          );
          if (duplicates.isEmpty) {
            await imageFile.delete();
          }
        }
      } catch (_) {}
    }

    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> deleteAllExpenses() async {
    final db = await _dbHelper.database;
    final expenses = await getAllExpenses();
    for (final exp in expenses) {
      if (exp.receiptImagePath != null) {
        try {
          final file = File(exp.receiptImagePath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
    }
    await db.delete('expenses');
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
    final db = await _dbHelper.database;
    final whereClauses = <String>[];
    final whereArgs = <dynamic>[];

    if (query != null && query.trim().isNotEmpty) {
      final sanitizedQuery = '%${query.trim()}%';
      whereClauses.add(
        '(merchant_name LIKE ? OR transfer_description LIKE ? OR recipient_name LIKE ? OR transaction_reference LIKE ?)',
      );
      whereArgs.addAll([
        sanitizedQuery,
        sanitizedQuery,
        sanitizedQuery,
        sanitizedQuery,
      ]);
    }

    if (category != null && category.isNotEmpty && category != 'all') {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    if (sourceType != null && sourceType.isNotEmpty && sourceType != 'all') {
      whereClauses.add('source_type = ?');
      whereArgs.add(sourceType);
    }

    if (startDate != null) {
      whereClauses.add('expense_date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('expense_date <= ?');
      // Include full end date till 23:59:59
      final fullEnd = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );
      whereArgs.add(fullEnd.toIso8601String());
    }

    String orderBySQL;
    switch (sortBy) {
      case 'oldest':
        orderBySQL = 'expense_date ASC, created_at ASC';
        break;
      case 'amount_high':
        orderBySQL = 'total_amount DESC';
        break;
      case 'amount_low':
        orderBySQL = 'total_amount ASC';
        break;
      case 'newest':
      default:
        orderBySQL = 'expense_date DESC, created_at DESC';
        break;
    }

    final whereString = whereClauses.isNotEmpty
        ? whereClauses.join(' AND ')
        : null;

    final maps = await db.query(
      'expenses',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBySQL,
    );

    return maps.map((map) => Expense.fromMap(map)).toList();
  }
}
