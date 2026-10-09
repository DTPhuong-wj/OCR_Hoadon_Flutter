import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../services/ocr_service.dart';
import '../../services/receipt_parser.dart';
import '../receipt_review/review_screen.dart';

class CaptureScreen extends StatefulWidget {
  final ImageSource initialSource;

  const CaptureScreen({super.key, this.initialSource = ImageSource.camera});

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocrService = OcrService();
  final ReceiptParser _receiptParser = ReceiptParser();

  XFile? _selectedImage;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pickImage(widget.initialSource);
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (image == null) {
        // User cancelled picker
        if (_selectedImage == null && mounted) {
          // If no previous image, pop screen
          Navigator.of(context).pop();
        }
        return;
      }

      setState(() {
        _selectedImage = image;
      });

      // Automatically trigger OCR processing
      await _processOcr();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Không thể mở ${source == ImageSource.camera ? "camera" : "thư viện ảnh"}: $e';
      });
    }
  }

  Future<void> _processOcr() async {
    if (_selectedImage == null || _isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final rawText = await _ocrService.recognizeTextFromImagePath(
        _selectedImage!.path,
      );
      final ocrResult = _receiptParser.parse(rawText);

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      // Navigate to Mandatory Review Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ReviewScreen(
            ocrResult: ocrResult,
            imagePath: _selectedImage!.path,
            sourceType: AppConstants.sourceReceiptOcr,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Lỗi nhận diện OCR: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét Hóa Đơn Giấy')),
      body: _selectedImage == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Image Preview Card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.file(
                        File(_selectedImage!.path),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.error,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  if (_isProcessing)
                    Column(
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text(
                          'Đang trích xuất dữ liệu bằng ML Kit OCR...',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _processOcr,
                          icon: const Icon(Icons.analytics),
                          label: const Text('Trích Xuất Hóa Đơn (OCR)'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Chụp lại'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Chọn ảnh khác'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }
}
