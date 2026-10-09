import 'dart:io';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

import '../data/models/qr_result.dart';
import 'payment_qr_parser.dart';

class QrScannerService {
  BarcodeScanner? _barcodeScanner;

  BarcodeScanner get barcodeScanner {
    _barcodeScanner ??= BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    return _barcodeScanner!;
  }

  /// Decodes QR code from static image file at imagePath
  Future<QrResult?> scanQrFromImagePath(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Tệp ảnh không tồn tại: $imagePath');
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final List<Barcode> barcodes = await barcodeScanner.processImage(
      inputImage,
    );

    if (barcodes.isEmpty) {
      return null;
    }

    // Process the first valid QR code with text payload
    for (final barcode in barcodes) {
      final rawPayload = barcode.rawValue;
      if (rawPayload != null && rawPayload.trim().isNotEmpty) {
        return PaymentQrParser.parse(rawPayload);
      }
    }

    return null;
  }

  /// Decode raw QR text directly
  QrResult parseQrPayload(String rawPayload) {
    return PaymentQrParser.parse(rawPayload);
  }

  void dispose() {
    _barcodeScanner?.close();
    _barcodeScanner = null;
  }
}
