import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/payment_qr_parser.dart';
import '../receipt_review/review_screen.dart';

class LiveQrScannerScreen extends StatefulWidget {
  const LiveQrScannerScreen({super.key});

  @override
  State<LiveQrScannerScreen> createState() => _LiveQrScannerScreenState();
}

class _LiveQrScannerScreenState extends State<LiveQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final firstQr = barcodes.first.rawValue;
    if (firstQr != null && firstQr.trim().isNotEmpty) {
      setState(() {
        _isProcessing = true;
      });

      _controller.stop();

      final qrResult = PaymentQrParser.parse(firstQr);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReviewScreen(
            qrResult: qrResult,
            sourceType: AppConstants.sourceQrCode,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã QR Thanh Toán'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.amber),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          // Frame overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.success, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Instruction hint text
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Di chuyển camera tới mã VietQR hoặc QR thanh toán để tự động quét',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
