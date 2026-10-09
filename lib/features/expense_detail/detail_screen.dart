import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/expense_providers.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../widgets/source_badge.dart';
import 'edit_expense_screen.dart';

class DetailScreen extends ConsumerWidget {
  final String expenseId;

  const DetailScreen({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListNotifierProvider);

    return expensesAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(
        appBar: AppBar(title: const Text('Chi Tiết Chi Tiêu')),
        body: Center(child: Text('Lỗi: $err')),
      ),
      data: (expenses) {
        final expense = expenses.firstWhere(
          (e) => e.id == expenseId,
          orElse: () => throw Exception('Không tìm thấy giao dịch'),
        );

        final catInfo = AppConstants.getCategoryInfo(expense.category);
        final hasImage =
            expense.receiptImagePath != null &&
            File(expense.receiptImagePath!).existsSync();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi Tiết Giao Dịch'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Sửa giao dịch',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditExpenseScreen(expense: expense),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                tooltip: 'Xóa giao dịch',
                onPressed: () async {
                  final confirm = await ConfirmationDialog.show(
                    context,
                    title: 'Xóa giao dịch chi tiêu?',
                    message:
                        'Bạn có chắc chắn muốn xóa "${expense.merchantName}" (${CurrencyFormatter.formatVND(expense.totalAmount)}) khỏi hệ thống?',
                  );
                  if (confirm == true) {
                    await ref
                        .read(expenseListNotifierProvider.notifier)
                        .deleteExpense(expense.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã xóa giao dịch.')),
                      );
                      Navigator.of(context).pop();
                    }
                  }
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount Card Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceVariant),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: catInfo.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          catInfo.icon,
                          color: catInfo.color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        expense.merchantName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.formatVND(expense.totalAmount),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SourceBadge(sourceType: expense.sourceType),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(
                              AppConstants.getStatusLabel(
                                expense.paymentStatus,
                              ),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: expense.isConfirmed
                                ? AppColors.success
                                : AppColors.warning,
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Image Preview Card (if file exists)
                if (hasImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      width: double.infinity,
                      color: Colors.black12,
                      child: Image.file(
                        File(expense.receiptImagePath!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ] else if (expense.receiptImagePath != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.broken_image, color: AppColors.textMuted),
                        SizedBox(width: 8),
                        Text('Tệp ảnh hóa đơn không còn tồn tại trên máy'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Information Card List
                _buildInfoSection(
                  title: 'Chi tiết thông tin',
                  items: [
                    _InfoRow(
                      'Ngày giao dịch:',
                      DateFormatter.formatDate(expense.expenseDate),
                    ),
                    _InfoRow('Danh mục chi tiêu:', catInfo.label),
                    if (expense.bankName != null)
                      _InfoRow('Ngân hàng:', expense.bankName!),
                    if (expense.recipientAccount != null)
                      _InfoRow('Số tài khoản nhận:', expense.recipientAccount!),
                    if (expense.transactionReference != null)
                      _InfoRow(
                        'Mã giao dịch / Ref:',
                        expense.transactionReference!,
                      ),
                    if (expense.receiptNumber != null)
                      _InfoRow('Số hóa đơn:', expense.receiptNumber!),
                    if (expense.transferDescription != null)
                      _InfoRow('Nội dung:', expense.transferDescription!),
                  ],
                ),

                const SizedBox(height: 16),

                // Optional Financial Breakdowns
                if (expense.subtotal != null ||
                    expense.taxAmount != null ||
                    expense.discountAmount != null)
                  _buildInfoSection(
                    title: 'Phân rã tài chính',
                    items: [
                      if (expense.subtotal != null)
                        _InfoRow(
                          'Tạm tính:',
                          CurrencyFormatter.formatVND(expense.subtotal!),
                        ),
                      if (expense.taxAmount != null)
                        _InfoRow(
                          'Thuế VAT:',
                          CurrencyFormatter.formatVND(expense.taxAmount!),
                        ),
                      if (expense.discountAmount != null)
                        _InfoRow(
                          'Chiết khấu:',
                          CurrencyFormatter.formatVND(expense.discountAmount!),
                        ),
                    ],
                  ),

                const SizedBox(height: 16),

                // Raw Text section
                if (expense.rawOcrText != null ||
                    expense.originalQrPayload != null)
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                expense.originalQrPayload != null
                                    ? 'Mã QR Gốc'
                                    : 'Văn bản OCR Gốc',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18),
                                tooltip: 'Sao chép văn bản',
                                onPressed: () {
                                  final copyText =
                                      expense.originalQrPayload ??
                                      expense.rawOcrText ??
                                      '';
                                  Clipboard.setData(
                                    ClipboardData(text: copyText),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã sao chép văn bản.'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            expense.originalQrPayload ??
                                expense.rawOcrText ??
                                '',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<_InfoRow> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      item.value,
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  _InfoRow(this.label, this.value);
}
