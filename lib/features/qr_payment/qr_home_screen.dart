import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/payment_screenshot_ocr_service.dart';
import '../../services/qr_scanner_service.dart';
import '../receipt_review/review_screen.dart';
import 'live_qr_scanner_screen.dart';
import 'sample_qr_picker_dialog.dart';

class QrHomeScreen extends StatefulWidget {
  const QrHomeScreen({super.key});

  @override
  State<QrHomeScreen> createState() => _QrHomeScreenState();
}

class _QrHomeScreenState extends State<QrHomeScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final QrScannerService _qrScannerService = QrScannerService();
  final PaymentScreenshotOcrService _screenshotOcrService =
      PaymentScreenshotOcrService();

  bool _isLoading = false;

  @override
  void dispose() {
    _qrScannerService.dispose();
    super.dispose();
  }

  Future<void> _importQrImage() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (file == null) return;

      setState(() {
        _isLoading = true;
      });

      final qrResult = await _qrScannerService.scanQrFromImagePath(file.path);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (qrResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không tìm thấy mã QR trong hình ảnh đã chọn.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReviewScreen(
            qrResult: qrResult,
            imagePath: file.path,
            sourceType: AppConstants.sourceQrCode,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xử lý ảnh QR: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _scanPaymentScreenshot() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (file == null) return;

      setState(() {
        _isLoading = true;
      });

      final ocrResult = await _screenshotOcrService.processScreenshot(
        file.path,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ReviewScreen(
            ocrResult: ocrResult,
            imagePath: file.path,
            sourceType: AppConstants.sourcePaymentScreenshotOcr,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đọc ảnh chuyển khoản: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR & Thanh Toán')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quản lý giao dịch QR & Ngân hàng',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Chọn một trong ba phương thức nhập dữ liệu giao dịch chi tiêu:',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 24),

                // Card 1: Scan QR Code (Live Camera)
                _buildOptionCard(
                  context: context,
                  title: 'Quét Mã QR Trực Tiếp',
                  subtitle: 'Mở camera để quét mã VietQR hoặc EMVCo',
                  icon: Icons.qr_code_scanner,
                  color: AppColors.qrSource,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LiveQrScannerScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Card 2: Import QR Image from Gallery
                _buildOptionCard(
                  context: context,
                  title: 'Tải Ảnh Mã QR Từ Thư Viện',
                  subtitle: 'Giải mã QR từ tệp hình ảnh JPEG, PNG',
                  icon: Icons.image_search,
                  color: AppColors.primary,
                  onTap: _importQrImage,
                ),

                const SizedBox(height: 16),

                // Card 3: Scan Payment Screenshot
                _buildOptionCard(
                  context: context,
                  title: 'Chụp / Tải Ảnh Xác Nhận Chuyển Khoản',
                  subtitle: 'Trích xuất số tiền & nội dung từ ảnh màn hình chuyển khoản ngân hàng',
                  icon: Icons.fit_screen,
                  color: AppColors.screenshotSource,
                  onTap: _scanPaymentScreenshot,
                ),

                const SizedBox(height: 32),

                // Sample QR Test Library Button
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const SampleQrPickerDialog(),
                      );
                    },
                    icon: const Icon(Icons.science, size: 18),
                    label: const Text(
                      'Tải Ảnh QR Mẫu Kiểm Thử (Sample Library)',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                      minimumSize: const Size(260, 46),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Đang xử lý hình ảnh...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
