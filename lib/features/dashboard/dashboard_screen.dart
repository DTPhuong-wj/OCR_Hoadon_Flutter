import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../providers/expense_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/expense_card.dart';
import '../analytics/charts/monthly_trend_chart.dart';
import '../expense_detail/detail_screen.dart';
import '../qr_payment/qr_home_screen.dart';
import '../receipt_capture/capture_screen.dart';

class DashboardScreen extends ConsumerWidget {
  final ValueChanged<int>? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Xin chào, Sinh viên VKU! 👋',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            Text(
              DateFormatter.formatDate(now),
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Quét QR Thanh Toán',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const QrHomeScreen()));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(expenseListNotifierProvider.notifier).loadExpenses();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Monthly & Weekly Summary Card
              _buildSummaryHeader(context, stats),

              const SizedBox(height: 16),

              // Quick Actions Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thao tác nhanh',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            context: context,
                            icon: Icons.document_scanner,
                            label: 'Quét Hóa Đơn',
                            subtitle: 'ML Kit OCR',
                            color: AppColors.primary,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CaptureScreen(
                                    initialSource: ImageSource.camera,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildQuickActionButton(
                            context: context,
                            icon: Icons.qr_code_scanner,
                            label: 'Scan QR / Bank',
                            subtitle: 'VietQR & Ảnh CK',
                            color: AppColors.qrSource,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const QrHomeScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildGalleryImportButton(context),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Mini Monthly Chart Summary
              if (stats.receiptCount > 0) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Xu hướng chi tiêu',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            onNavigateTab?.call(2), // Analytics tab
                        child: const Text('Chi tiết >'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildMiniChart(ref),
                ),
                const SizedBox(height: 20),
              ],

              // Recent Expenses Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chi tiêu gần đây (${stats.recentExpenses.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (stats.recentExpenses.isNotEmpty)
                      TextButton(
                        onPressed: () => onNavigateTab?.call(1), // History tab
                        child: const Text('Xem tất cả >'),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              if (stats.recentExpenses.isEmpty)
                EmptyStateWidget(
                  title: 'Chưa có hóa đơn nào',
                  description: 'Hãy quét hóa đơn giấy hoặc tải mã QR thanh toán để bắt đầu quản lý chi tiêu sinh viên VKU!',
                  actionLabel: 'Quét Hóa Đơn Ngay',
                  onActionPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CaptureScreen(
                          initialSource: ImageSource.camera,
                        ),
                      ),
                    );
                  },
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stats.recentExpenses.length,
                  itemBuilder: (context, index) {
                    final item = stats.recentExpenses[index];
                    return ExpenseCard(
                      expense: item,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(expenseId: item.id),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, DashboardStats stats) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tổng chi tiêu tháng này',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.formatVND(stats.currentMonthTotal),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Tuần này:',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      CurrencyFormatter.formatVND(stats.currentWeekTotal),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      size: 16,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${stats.receiptCount} HĐ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceVariant),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryImportButton(BuildContext context) {
    return Material(
      color: AppColors.surfaceVariant.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  const CaptureScreen(initialSource: ImageSource.gallery),
            ),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.photo_library, size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Tải ảnh hóa đơn từ Thư viện ảnh',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChart(WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListNotifierProvider);

    return expensesAsync.maybeWhen(
      data: (expenses) {
        final now = DateTime.now();
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final chartData = <MonthlyTrendChartData>[];

        for (int i = 1; i <= daysInMonth; i++) {
          final dayExpenses = expenses.where(
            (e) =>
                e.expenseDate.year == now.year &&
                e.expenseDate.month == now.month &&
                e.expenseDate.day == i,
          );
          final dayTotal = dayExpenses.fold<int>(
            0,
            (sum, e) => sum + e.totalAmount,
          );
          chartData.add(
            MonthlyTrendChartData(dayLabel: '$i', amount: dayTotal),
          );
        }

        return MonthlyTrendChart(data: chartData);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
