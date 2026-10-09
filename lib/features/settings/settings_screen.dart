import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/expense.dart';
import '../../providers/expense_providers.dart';
import '../../widgets/confirmation_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _loadSampleData(BuildContext context, WidgetRef ref) async {
    final uuid = const Uuid();
    final now = DateTime.now();

    final samples = [
      Expense(
        id: uuid.v4(),
        merchantName: 'Căn tin VKU',
        totalAmount: 35000,
        expenseDate: now.subtract(const Duration(hours: 4)),
        category: 'food',
        sourceType: AppConstants.sourceReceiptOcr,
        transferDescription: 'Cơm trưa sinh viên',
        createdAt: now,
        updatedAt: now,
      ),
      Expense(
        id: uuid.v4(),
        merchantName: 'CLB IT VKU',
        totalAmount: 50000,
        expenseDate: now.subtract(const Duration(days: 1)),
        category: 'club',
        sourceType: AppConstants.sourceQrCode,
        bankName: 'TPBank',
        recipientName: 'Quỹ CLB IT VKU',
        transferDescription: 'Đóng quỹ CLB tháng 10',
        createdAt: now,
        updatedAt: now,
      ),
      Expense(
        id: uuid.v4(),
        merchantName: 'Tiệm In Ấn Giáo Trình',
        totalAmount: 120000,
        expenseDate: now.subtract(const Duration(days: 2)),
        category: 'education',
        sourceType: AppConstants.sourceReceiptOcr,
        transferDescription: 'In giáo trình Lập trình Flutter',
        createdAt: now,
        updatedAt: now,
      ),
      Expense(
        id: uuid.v4(),
        merchantName: 'WinMart+ Nam Kỳ Khởi Nghĩa',
        totalAmount: 85000,
        expenseDate: now.subtract(const Duration(days: 3)),
        category: 'shopping',
        sourceType: AppConstants.sourcePaymentScreenshotOcr,
        bankName: 'Vietcombank',
        transferDescription: 'Mua đồ dùng cá nhân',
        createdAt: now,
        updatedAt: now,
      ),
    ];

    final notifier = ref.read(expenseListNotifierProvider.notifier);
    for (final exp in samples) {
      await notifier.addExpense(exp);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã tạo 4 giao dịch mẫu để thử nghiệm!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cài Đặt & Thông Tin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Header Card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: const [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppColors.primaryContainer,
                    child: Icon(
                      Icons.receipt_long,
                      size: 36,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    AppConstants.appName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ứng dụng Quản lý Chi tiêu & ML Kit OCR dành cho Sinh viên và Ban Quản lý Câu lạc bộ VKU',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Phiên bản 1.0.0 (Offline First)',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Features Card
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.memory, color: AppColors.primary),
                  title: Text('Xử lý On-Device ML Kit OCR'),
                  subtitle: Text('Trích xuất hóa đơn không dùng Internet'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.qr_code, color: AppColors.qrSource),
                  title: Text('Hỗ trợ VietQR & Ảnh Chuyển Khoản'),
                  subtitle: Text('Giải mã chuẩn EMVCo & OCR ngân hàng'),
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.storage, color: AppColors.secondary),
                  title: Text('Lưu trữ SQLite nội địa'),
                  subtitle: Text('Bảo mật dữ liệu trên máy điện thoại'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Options
          const Text(
            'Quản lý dữ liệu',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: Colors.white,
            leading: const Icon(Icons.playlist_add, color: AppColors.primary),
            title: const Text('Thêm dữ liệu mẫu thử nghiệm'),
            subtitle: const Text('Nạp 4 giao dịch mẫu để trải nghiệm đồ thị'),
            onTap: () => _loadSampleData(context, ref),
          ),

          const SizedBox(height: 12),

          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: Colors.white,
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text(
              'Xóa toàn bộ dữ liệu ứng dụng',
              style: TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text('Xóa tất cả bản ghi SQLite và ảnh hóa đơn'),
            onTap: () async {
              final confirm = await ConfirmationDialog.show(
                context,
                title: 'Xóa toàn bộ dữ liệu?',
                message: 'Hành động này sẽ xóa vĩnh viễn tất cả các bản ghi chi tiêu và ảnh hóa đơn đã lưu. Bạn có chắc chắn không?',
                confirmLabel: 'Xóa Tất Cả',
              );
              if (confirm == true) {
                await ref
                    .read(expenseListNotifierProvider.notifier)
                    .deleteAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã xóa toàn bộ dữ liệu.'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
