import 'package:flutter/material.dart';

class ExpenseCategoryInfo {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const ExpenseCategoryInfo({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class AppConstants {
  static const String appName = 'Receipt OCR & Expense Tracker';
  static const String appId = 'com.vku.receipttracker';

  // Expense Categories with Vietnamese Labels & Material Icons
  static const List<ExpenseCategoryInfo> categories = [
    ExpenseCategoryInfo(
      id: 'food',
      label: 'Ăn uống',
      icon: Icons.restaurant,
      color: Color(0xFFEF4444),
    ),
    ExpenseCategoryInfo(
      id: 'transport',
      label: 'Di chuyển',
      icon: Icons.directions_bus,
      color: Color(0xFFF59E0B),
    ),
    ExpenseCategoryInfo(
      id: 'shopping',
      label: 'Mua sắm',
      icon: Icons.shopping_bag,
      color: Color(0xFFEC4899),
    ),
    ExpenseCategoryInfo(
      id: 'education',
      label: 'Học tập / VKU',
      icon: Icons.school,
      color: Color(0xFF3B82F6),
    ),
    ExpenseCategoryInfo(
      id: 'club',
      label: 'Hoạt động Câu lạc bộ',
      icon: Icons.groups,
      color: Color(0xFF8B5CF6),
    ),
    ExpenseCategoryInfo(
      id: 'office',
      label: 'Văn phòng phẩm',
      icon: Icons.article,
      color: Color(0xFF10B981),
    ),
    ExpenseCategoryInfo(
      id: 'health',
      label: 'Y tế & Sức khỏe',
      icon: Icons.medical_services,
      color: Color(0xFF06B6D4),
    ),
    ExpenseCategoryInfo(
      id: 'entertainment',
      label: 'Giải trí',
      icon: Icons.sports_esports,
      color: Color(0xFFF97316),
    ),
    ExpenseCategoryInfo(
      id: 'other',
      label: 'Khác',
      icon: Icons.more_horiz,
      color: Color(0xFF6B7280),
    ),
  ];

  static ExpenseCategoryInfo getCategoryInfo(String categoryId) {
    return categories.firstWhere(
      (cat) => cat.id.toLowerCase() == categoryId.toLowerCase(),
      orElse: () => categories.last, // 'other'
    );
  }

  // Source Types
  static const String sourceReceiptOcr = 'receipt_ocr';
  static const String sourceQrCode = 'qr_code';
  static const String sourcePaymentScreenshotOcr = 'payment_screenshot_ocr';
  static const String sourceManual = 'manual';

  static String getSourceLabel(String sourceType) {
    switch (sourceType) {
      case sourceReceiptOcr:
        return 'Quét Hóa Đơn';
      case sourceQrCode:
        return 'Mã QR Thanh Toán';
      case sourcePaymentScreenshotOcr:
        return 'Ảnh Chuyển Khoản';
      case sourceManual:
        return 'Thủ Công';
      default:
        return 'Khác';
    }
  }

  // Payment Statuses
  static const String statusUserConfirmed = 'user_confirmed';
  static const String statusPendingVerification = 'pending_verification';
  static const String statusBankVerified = 'bank_verified';
  static const String statusDraft = 'draft';
  static const String statusFailed = 'failed';
  static const String statusCancelled = 'cancelled';

  static String getStatusLabel(String status) {
    switch (status) {
      case statusUserConfirmed:
        return 'Đã xác nhận thủ công';
      case statusPendingVerification:
        return 'Chờ xác minh';
      case statusBankVerified:
        return 'Đã xác minh từ ngân hàng';
      case statusDraft:
        return 'Nháp';
      case statusFailed:
        return 'Thất bại';
      case statusCancelled:
        return 'Đã hủy';
      default:
        return 'Chưa xác nhận';
    }
  }
}
