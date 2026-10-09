import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../data/models/expense.dart';
import '../../data/models/ocr_result.dart';
import '../../data/models/qr_result.dart';
import '../../providers/expense_providers.dart';
import '../../services/image_storage_service.dart';
import '../../widgets/source_badge.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  final OcrResult? ocrResult;
  final QrResult? qrResult;
  final String? imagePath;
  final String sourceType;

  const ReviewScreen({
    super.key,
    this.ocrResult,
    this.qrResult,
    this.imagePath,
    required this.sourceType,
  });

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  final ImageStorageService _storageService = ImageStorageService();

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

    final ocr = widget.ocrResult;
    final qr = widget.qrResult;

    // Default merchant / recipient name
    String merchant = '';
    if (ocr != null) {
      merchant = ocr.merchantName ?? ocr.recipientName ?? '';
    } else if (qr != null) {
      merchant = qr.beneficiaryName ?? qr.bankName ?? 'Thanh toán QR';
    }
    if (merchant.isEmpty) merchant = 'Cửa hàng / Nhà cung cấp';

    // Default amount
    int amount = 0;
    if (ocr?.totalAmount != null) {
      amount = ocr!.totalAmount!;
    } else if (qr?.amount != null) {
      amount = qr!.amount!;
    }

    _merchantController = TextEditingController(text: merchant);
    _amountController = TextEditingController(
      text: amount > 0 ? amount.toString() : '',
    );
    _receiptNumberController = TextEditingController(
      text: ocr?.receiptNumber ?? qr?.billReference ?? '',
    );
    _subtotalController = TextEditingController(
      text: ocr?.subtotal != null ? ocr!.subtotal.toString() : '',
    );
    _taxController = TextEditingController(
      text: ocr?.taxAmount != null ? ocr!.taxAmount.toString() : '',
    );
    _discountController = TextEditingController(
      text: ocr?.discountAmount != null ? ocr!.discountAmount.toString() : '',
    );

    _bankNameController = TextEditingController(
      text: ocr?.bankName ?? qr?.bankName ?? '',
    );
    _recipientAccountController = TextEditingController(
      text: ocr?.recipientAccount ?? qr?.beneficiaryAccount ?? '',
    );
    _transactionRefController = TextEditingController(
      text: ocr?.transactionReference ?? qr?.billReference ?? '',
    );
    _transferDescController = TextEditingController(
      text: ocr?.transferDescription ?? qr?.paymentDescription ?? '',
    );

    _selectedDate = ocr?.expenseDate ?? DateTime.now();
    _selectedCategory = ocr?.category ?? 'other';

    // Status logic
    if (widget.sourceType == AppConstants.sourceQrCode &&
        qr?.isPaymentRequest == true) {
      _paymentStatus = AppConstants.statusPendingVerification;
    } else {
      _paymentStatus = AppConstants.statusUserConfirmed;
    }
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

  Future<void> _saveExpense() async {
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

      // Save image permanently to app documents directory if imagePath exists
      String? savedImagePath;
      if (widget.imagePath != null) {
        savedImagePath = await _storageService.saveImageLocally(
          widget.imagePath!,
        );
      }

      final expense = Expense(
        id: _uuid.v4(),
        merchantName: _merchantController.text.trim(),
        totalAmount: amount,
        expenseDate: _selectedDate,
        category: _selectedCategory,
        receiptImagePath: savedImagePath ?? widget.imagePath,
        rawOcrText: widget.ocrResult?.rawText,
        subtotal: subtotal,
        taxAmount: tax,
        discountAmount: discount,
        receiptNumber: _receiptNumberController.text.trim().isNotEmpty
            ? _receiptNumberController.text.trim()
            : null,
        sourceType: widget.sourceType,
        paymentStatus: _paymentStatus,
        verificationStatus: AppConstants.statusUserConfirmed,
        transactionReference: _transactionRefController.text.trim().isNotEmpty
            ? _transactionRefController.text.trim()
            : null,
        bankName: _bankNameController.text.trim().isNotEmpty
            ? _bankNameController.text.trim()
            : null,
        recipientName: _merchantController.text.trim(),
        recipientAccount: _recipientAccountController.text.trim().isNotEmpty
            ? _recipientAccountController.text.trim()
            : null,
        transferDescription: _transferDescController.text.trim().isNotEmpty
            ? _transferDescController.text.trim()
            : null,
        currency: widget.qrResult?.currency ?? 'VND',
        originalQrPayload: widget.qrResult?.rawPayload,
        ocrConfidence: widget.ocrResult?.confidence.name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await ref
          .read(expenseListNotifierProvider.notifier)
          .addExpense(expense);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu chi tiêu thành công!'),
            backgroundColor: AppColors.success,
          ),
        );
        // Navigate back to Dashboard/History root
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi không thể ghi vào cơ sở dữ liệu.'),
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
        SnackBar(
          content: Text('Lỗi khi lưu: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final warnings =
        widget.ocrResult?.warnings ?? widget.qrResult?.parseWarnings ?? [];
    final confidenceStr = widget.ocrResult?.confidenceString;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác Minh Chi Tiêu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Lưu giao dịch',
            onPressed: _isSaving ? null : _saveExpense,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Source Badge & Confidence Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SourceBadge(sourceType: widget.sourceType),
                  if (confidenceStr != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Độ tin cậy: $confidenceStr',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Warnings Container if any
              if (warnings.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.warning_amber,
                            size: 18,
                            color: AppColors.warning,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Lưu ý kiểm tra:',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ...warnings.map(
                        (w) => Text(
                          '• $w',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Image Preview Card (if available)
              if (widget.imagePath != null &&
                  File(widget.imagePath!).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    color: Colors.black12,
                    child: Image.file(
                      File(widget.imagePath!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Form Section Header
              const Text(
                'Thông tin chi tiết giao dịch',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              // 1. Merchant / Recipient Name Field
              TextFormField(
                controller: _merchantController,
                decoration: const InputDecoration(
                  labelText: 'Tên Cửa hàng / Người nhận *',
                  prefixIcon: Icon(Icons.store),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập tên cửa hàng hoặc người nhận';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // 2. Total Amount Field (VND)
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tổng số tiền (VNĐ) *',
                  prefixIcon: Icon(Icons.monetization_on),
                  suffixText: '₫',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Vui lòng nhập số tiền';
                  }
                  final parsed = CurrencyFormatter.parseVndAmount(val);
                  if (parsed == null || parsed <= 0) {
                    return 'Số tiền phải là số hợp lệ lớn hơn 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              // 3. Date & Category Row
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
                        child: Text(
                          DateFormatter.formatDate(_selectedDate),
                          style: const TextStyle(fontSize: 14),
                        ),
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
                            overflow: TextOverflow.ellipsis,
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

              // Bank Name & Account Number (if bank transfer / VietQR)
              if (widget.sourceType == AppConstants.sourceQrCode ||
                  widget.sourceType ==
                      AppConstants.sourcePaymentScreenshotOcr) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bankNameController,
                        decoration: const InputDecoration(
                          labelText: 'Ngân hàng',
                          prefixIcon: Icon(Icons.account_balance),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _recipientAccountController,
                        decoration: const InputDecoration(
                          labelText: 'Số tài khoản',
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Reference & Description
              TextFormField(
                controller: _transferDescController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung chuyển khoản / Ghi chú',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),

              const SizedBox(height: 12),

              // Expansion Tile for Optional Fields (Tax, Subtotal, Receipt No)
              ExpansionTile(
                title: const Text(
                  'Chi tiết bổ sung (Hóa đơn, thuế, chiết khấu)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                tilePadding: EdgeInsets.zero,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _receiptNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Số hóa đơn / Mã GD',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _subtotalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tạm tính (Subtotal)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _taxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Thuế VAT',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _discountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Giảm giá (Discount)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),

              const SizedBox(height: 12),

              // Expandable Raw Text Section
              if (widget.ocrResult?.rawText.isNotEmpty == true ||
                  widget.qrResult?.rawPayload.isNotEmpty == true)
                Card(
                  margin: EdgeInsets.zero,
                  child: ExpansionTile(
                    title: Text(
                      widget.qrResult != null
                          ? 'Mã QR Gốc (Raw Payload)'
                          : 'Văn bản OCR Gốc (Raw OCR Text)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SelectableText(
                          widget.qrResult?.rawPayload ??
                              widget.ocrResult?.rawText ??
                              '',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Primary Save Button
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveExpense,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  _isSaving ? 'Đang lưu...' : 'Xác Nhận & Lưu Chi Tiêu',
                ),
              ),

              const SizedBox(height: 12),

              // Cancel Button
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Hủy bỏ không lưu',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
