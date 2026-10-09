import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

class CategoryPieChartItem {
  final String categoryId;
  final String label;
  final int amount;
  final Color color;

  CategoryPieChartItem({
    required this.categoryId,
    required this.label,
    required this.amount,
    required this.color,
  });
}

class CategoryPieChart extends StatelessWidget {
  final List<CategoryPieChartItem> items;

  const CategoryPieChart({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty || items.every((i) => i.amount == 0)) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Chưa có dữ liệu phân loại chi tiêu',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }

    final totalAmount = items.fold<int>(0, (sum, item) => sum + item.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.infinite,
                  painter: _CategoryPiePainter(
                    items: items,
                    totalAmount: totalAmount,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Tổng chi',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.formatCompact(totalAmount),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Legend grid
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: items.map((item) {
              final pct = totalAmount > 0
                  ? (item.amount / totalAmount * 100).toStringAsFixed(1)
                  : '0';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item.label} ($pct%)',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CategoryPiePainter extends CustomPainter {
  final List<CategoryPieChartItem> items;
  final int totalAmount;

  _CategoryPiePainter({required this.items, required this.totalAmount});

  @override
  void paint(Canvas canvas, Size size) {
    if (totalAmount <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    final strokeWidth = 28.0;

    double startAngle = -math.pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    for (final item in items) {
      if (item.amount <= 0) continue;
      final sweepAngle = (item.amount / totalAmount) * 2 * math.pi;

      paint.color = item.color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.03, // Small gap between slices
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryPiePainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.totalAmount != totalAmount;
  }
}
