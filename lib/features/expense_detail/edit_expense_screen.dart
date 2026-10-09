import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/expense.dart';
import '../../providers/expense_providers.dart';

class EditExpenseScreen extends ConsumerStatefulWidget {
  final Expense expense;

  const EditExpenseScreen({super.key, required this.expense});

  @override
  ConsumerState<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends ConsumerState<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _receiptNumberController;
  late TextEditingController _subtotalController;
  late TextEditingController _taxController;
  late TextEditingController _discountController;

  late TextEditingController _bankNameController;
  late TextEditingController _recipientAccountController;
  late TextEditingController _transactionRefController;
  late TextEditingController _transferDescController;

  late DateTime _selectedDate;
  late String _selectedCategory;
  late String _paymentStatus;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _merchantController = TextEditingController(text: e.merchantName);
    _amountController = TextEditingController(text: e.totalAmount.toString());
    _receiptNumberController = TextEditingController(
      text: e.receiptNumber ?? '',
    );
    _subtotalController = TextEditingController(
      text: e.subtotal != null ? e.subtotal.toString() : '',
    );
    _taxController = TextEditingController(
      text: e.taxAmount != null ? e.taxAmount.toString() : '',
    );
    _discountController = TextEditingController(
      text: e.discountAmount != null ? e.discountAmount.toString() : '',
    );

    _bankNameController = TextEditingController(text: e.bankName ?? '');
    _recipientAccountController = TextEditingController(
      text: e.recipientAccount ?? '',
    );
    _transactionRefController = TextEditingController(
      text: e.transactionReference ?? '',
    );
    _transferDescController = TextEditingController(
      text: e.transferDescription ?? '',
    );

    _selectedDate = e.expenseDate;
    _selectedCategory = e.category;
    _paymentStatus = e.paymentStatus;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _receiptNumberController.dispose();
    _subtotalController.dispose();
    _taxController.dispose();
    _discountController.dispose();
    _bankNameController.dispose();
    _recipientAccountController.dispose();
    _transactionRefController.dispose();
    _transferDescController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final amount =
          CurrencyFormatter.parseVndAmount(_amountController.text) ?? 0;
      final subtotal = int.tryParse(_subtotalController.text);
      final tax = int.tryParse(_taxController.text);
      final discount = int.tryParse(_discountController.text);

      final updated = widget.expense.copyWith(
        merchantName: _merchantController.text.trim(),
        totalAmount: amount,
        expenseDate: _selectedDate,
        category: _selectedCategory,
        paymentStatus: _paymentStatus,
        subtotal: subtotal,
        taxAmount: tax,
        discountAmount: discount,
        receiptNumber: _receiptNumberController.text.trim().isNotEmpty
            ? _receiptNumberController.text.trim()
            : null,
        bankName: _bankNameController.text.trim().isNotEmpty
            ? _bankNameController.text.trim()
            : null,
        recipientAccount: _recipientAccountController.text.trim().isNotEmpty
            ? _recipientAccountController.text.trim()
            : null,
        transactionReference: _transactionRefController.text.trim().isNotEmpty
            ? _transactionRefController.text.trim()
            : null,
        transferDescription: _transferDescController.text.trim().isNotEmpty
            ? _transferDescController.text.trim()
            : null,
        updatedAt: DateTime.now(),
      );

      final success = await ref
          .read(expenseListNotifierProvider.notifier)
          .updateExpense(updated);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật giao dịch!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể cập nhật giao dịch.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh Sửa Giao Dịch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveChanges,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  labelText: 'Tên Cửa hàng / Người nhận *',
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền (VNĐ) *',
                  prefixIcon: Icon(Icons.monetization_on),
                  suffixText: '₫',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  final parsed = CurrencyFormatter.parseVndAmount(val);
                  if (parsed == null || parsed <= 0) {
                    return 'Số tiền không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Ngày giao dịch',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(DateFormatter.formatDate(_selectedDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Danh mục',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: AppConstants.categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat.id,
                          child: Text(
                            cat.label,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _paymentStatus,
                decoration: const InputDecoration(
                  labelText: 'Trạng thái xác minh',
                  prefixIcon: Icon(Icons.verified),
                ),
                items: const [
                  DropdownMenuItem(
                    value: AppConstants.statusUserConfirmed,
                    child: Text('Đã xác nhận thủ công'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.statusPendingVerification,
                    child: Text('Chờ xác minh'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _paymentStatus = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _transferDescController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung / Ghi chú',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: const Icon(Icons.save),
                label: Text(_isSaving ? 'Đang lưu...' : 'Lưu Thay Đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
