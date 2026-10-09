import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class MonthlyTrendChartData {
  final String dayLabel;
  final int amount;

  MonthlyTrendChartData({required this.dayLabel, required this.amount});
}

class MonthlyTrendChart extends StatelessWidget {
  final List<MonthlyTrendChartData> data;

  const MonthlyTrendChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.every((d) => d.amount == 0)) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Chưa có dữ liệu chi tiêu trong tháng',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      );
    }

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceVariant),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _MonthlyTrendPainter(data: data),
      ),
    );
  }
}

class _MonthlyTrendPainter extends CustomPainter {
  final List<MonthlyTrendChartData> data;

  _MonthlyTrendPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxAmount = data.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    final safeMax = maxAmount == 0 ? 100000 : maxAmount;

    final paddingLeft = 45.0;
    final paddingBottom = 25.0;
    final paddingTop = 15.0;
    final paddingRight = 15.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // Draw horizontal grid lines (3 lines)
    final gridPaint = Paint()
      ..color = AppColors.surfaceVariant
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= 3; i++) {
      final y = paddingTop + chartHeight - (chartHeight * i / 3);
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width - paddingRight, y),
        gridPaint,
      );

      // Y-Axis label
      final labelAmount = (safeMax * i / 3).round();
      final textSpan = TextSpan(
        text: _formatShortVnd(labelAmount),
        style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(paddingLeft - textPainter.width - 4, y - textPainter.height / 2),
      );
    }

    // Points & Path calculation
    final points = <Offset>[];
    final stepX = data.length > 1
        ? chartWidth / (data.length - 1)
        : chartWidth / 2;

    for (int i = 0; i < data.length; i++) {
      final x = paddingLeft + (i * stepX);
      final normY = data[i].amount / safeMax;
      final y = paddingTop + chartHeight - (chartHeight * normY);
      points.add(Offset(x, y));
    }

    // Draw Area Gradient Fill
    if (points.length > 1) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, paddingTop + chartHeight);
      for (final pt in points) {
        fillPath.lineTo(pt.dx, pt.dy);
      }
      fillPath.lineTo(points.last.dx, paddingTop + chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, paddingTop),
          Offset(0, paddingTop + chartHeight),
          [
            AppColors.primary.withValues(alpha: 0.3),
            AppColors.primary.withValues(alpha: 0.0),
          ],
        );
      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw Smooth Line
    final linePath = Path();
    if (points.isNotEmpty) {
      linePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlX = (p0.dx + p1.dx) / 2;
        linePath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      }
    }

    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(linePath, linePaint);

    // Draw Dots and X-axis Labels
    final dotPaint = Paint()..color = AppColors.primary;
    final dotInnerPaint = Paint()..color = Colors.white;

    final stepLabelRatio = (data.length / 5).ceil();

    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      canvas.drawCircle(pt, 4, dotPaint);
      canvas.drawCircle(pt, 2, dotInnerPaint);

      // X-Axis Labels (show a subset if many days)
      if (i % stepLabelRatio == 0 || i == points.length - 1) {
        final textSpan = TextSpan(
          text: data[i].dayLabel,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            pt.dx - textPainter.width / 2,
            size.height - paddingBottom + 6,
          ),
        );
      }
    }
  }

  String _formatShortVnd(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).round()}k';
    }
    return '$amount';
  }

  @override
  bool shouldRepaint(covariant _MonthlyTrendPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
