import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

class SourceBadge extends StatelessWidget {
  final String sourceType;
  final bool compact;

  const SourceBadge({
    super.key,
    required this.sourceType,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg = Colors.white;
    IconData icon;

    switch (sourceType) {
      case AppConstants.sourceReceiptOcr:
        bg = AppColors.receiptSource;
        icon = Icons.receipt_long;
        break;
      case AppConstants.sourceQrCode:
        bg = AppColors.qrSource;
        icon = Icons.qr_code_scanner;
        break;
      case AppConstants.sourcePaymentScreenshotOcr:
        bg = AppColors.screenshotSource;
        icon = Icons.fit_screen;
        break;
      case AppConstants.sourceManual:
      default:
        bg = AppColors.manualSource;
        icon = Icons.edit_note;
        break;
    }

    final label = AppConstants.getSourceLabel(sourceType);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bg.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: bg.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: bg),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: bg,
              ),
            ),
          ],
        ),
      );
    }

    return Chip(
      avatar: Icon(icon, size: 14, color: fg),
      label: Text(
        label,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600),
      ),
      backgroundColor: bg,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
