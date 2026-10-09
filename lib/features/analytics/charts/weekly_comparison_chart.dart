import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class WeeklyBarData {
  final String dayName;
  final int amount;

  WeeklyBarData({required this.dayName, required this.amount});
}

class WeeklyComparisonChart extends StatelessWidget {
  final List<WeeklyBarData> data;

  const WeeklyComparisonChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.every((d) => d.amount == 0)) {
      return Container(
        height: 180,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Chưa có chi tiêu tuần này',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _WeeklyBarPainter(data: data),
      ),
    );
  }
}

class _WeeklyBarPainter extends CustomPainter {
  final List<WeeklyBarData> data;

  _WeeklyBarPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxAmount = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final safeMax = maxAmount == 0 ? 100000 : maxAmount;

    final paddingBottom = 24.0;
    final paddingTop = 20.0;
    final chartHeight = size.height - paddingTop - paddingBottom;

    final totalBars = data.length;
    final barWidth = (size.width / totalBars) * 0.45;
    final space = size.width / totalBars;

    final barPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final bgBarPaint = Paint()
      ..color = AppColors.surfaceVariant.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < totalBars; i++) {
      final item = data[i];
      final centerX = (i * space) + (space / 2);
      final left = centerX - (barWidth / 2);
      final right = centerX + (barWidth / 2);

      // Background Track
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTRB(left, paddingTop, right, paddingTop + chartHeight),
        const Radius.circular(6),
      );
      canvas.drawRRect(bgRect, bgBarPaint);

      // Value Bar
      final normHeight = (item.amount / safeMax) * chartHeight;
      final barTop = paddingTop + chartHeight - normHeight;

      if (normHeight > 0) {
        final barRect = RRect.fromRectAndRadius(
          Rect.fromLTRB(left, barTop, right, paddingTop + chartHeight),
          const Radius.circular(6),
        );
        canvas.drawRRect(barRect, barPaint);

        // Top value label
        final textSpan = TextSpan(
          text: _shortAmount(item.amount),
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(centerX - tp.width / 2, barTop - 14));
      }

      // Day Label
      final daySpan = TextSpan(
        text: item.dayName,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );
      final dayTp = TextPainter(
        text: daySpan,
        textDirection: TextDirection.ltr,
      );
      dayTp.layout();
      dayTp.paint(
        canvas,
        Offset(centerX - dayTp.width / 2, size.height - paddingBottom + 6),
      );
    }
  }

  String _shortAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).round()}k';
    }
    return '$amount';
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
