import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/expense_providers.dart';
import 'charts/category_pie_chart.dart';
import 'charts/monthly_trend_chart.dart';
import 'charts/weekly_comparison_chart.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseListNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Phân Tích Chi Tiêu')),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi: $err')),
        data: (expenses) {
          final confirmed = expenses.where((e) => e.isConfirmed).toList();
          final now = DateTime.now();

          // 1. Monthly Trend Data (Days 1 to DaysInMonth)
          final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
          final monthlyTrendData = <MonthlyTrendChartData>[];
          for (int i = 1; i <= daysInMonth; i++) {
            final dayTotal = confirmed
                .where(
                  (e) =>
                      e.expenseDate.year == now.year &&
                      e.expenseDate.month == now.month &&
                      e.expenseDate.day == i,
                )
                .fold<int>(0, (sum, e) => sum + e.totalAmount);
            monthlyTrendData.add(
              MonthlyTrendChartData(dayLabel: '$i', amount: dayTotal),
            );
          }

          // 2. Category Pie Chart Data
          final categoryTotals = <String, int>{};
          for (final exp in confirmed) {
            if (exp.expenseDate.year == now.year &&
                exp.expenseDate.month == now.month) {
              categoryTotals[exp.category] =
                  (categoryTotals[exp.category] ?? 0) + exp.totalAmount;
            }
          }

          final pieItems = categoryTotals.entries.map((entry) {
            final catInfo = AppConstants.getCategoryInfo(entry.key);
            return CategoryPieChartItem(
              categoryId: entry.key,
              label: catInfo.label,
              amount: entry.value,
              color: catInfo.color,
            );
          }).toList();

          // Sort pie items descending by amount
          pieItems.sort((a, b) => b.amount.compareTo(a.amount));

          // 3. Weekly Bar Chart Data (Mon to Sun)
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final weeklyBarData = <WeeklyBarData>[];
          final dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

          for (int i = 0; i < 7; i++) {
            final dayDate = DateTime(
              startOfWeek.year,
              startOfWeek.month,
              startOfWeek.day + i,
            );
            final dayTotal = confirmed
                .where(
                  (e) =>
                      e.expenseDate.year == dayDate.year &&
                      e.expenseDate.month == dayDate.month &&
                      e.expenseDate.day == dayDate.day,
                )
                .fold<int>(0, (sum, e) => sum + e.totalAmount);
            weeklyBarData.add(
              WeeklyBarData(dayName: dayNames[i], amount: dayTotal),
            );
          }

          final monthTotal = monthlyTrendData.fold<int>(
            0,
            (sum, item) => sum + item.amount,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Total Summary Card
                Card(
                  margin: EdgeInsets.zero,
                  color: AppColors.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tổng chi tiêu tháng này',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              CurrencyFormatter.formatVND(monthTotal),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const Icon(
                          Icons.analytics,
                          size: 36,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Chart 1: Monthly Trend (CustomPainter)
                const Text(
                  '1. Xu hướng chi tiêu trong tháng (Line Chart Canvas)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                MonthlyTrendChart(data: monthlyTrendData),

                const SizedBox(height: 24),

                // Chart 2: Category Breakdown Donut (CustomPainter)
                const Text(
                  '2. Cơ cấu chi tiêu theo danh mục (Donut Canvas)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                CategoryPieChart(items: pieItems),

                const SizedBox(height: 24),

                // Chart 3: Weekly Comparison (CustomPainter)
                const Text(
                  '3. So sánh chi tiêu các ngày trong tuần (Bar Canvas)',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                WeeklyComparisonChart(data: weeklyBarData),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
