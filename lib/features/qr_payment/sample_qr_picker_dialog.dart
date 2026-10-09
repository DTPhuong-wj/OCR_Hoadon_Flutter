import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/sample_qrs.dart';
import '../../core/utils/currency_formatter.dart';
import '../../services/payment_qr_parser.dart';
import '../receipt_review/review_screen.dart';

class SampleQrPickerDialog extends StatelessWidget {
  const SampleQrPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.qr_code, color: AppColors.qrSource),
          SizedBox(width: 8),
          Text(
            'Chọn mã QR Mẫu (Test)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Danh sách dữ liệu VietQR tổng hợp để kiểm thử giao dịch không cần quét thực tế:',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: SampleQrs.samples.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = SampleQrs.samples[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: Text(
                      CurrencyFormatter.formatVND(item.defaultAmount),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      final qrResult = PaymentQrParser.parse(item.payload);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReviewScreen(
                            qrResult: qrResult,
                            sourceType: AppConstants.sourceQrCode,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
