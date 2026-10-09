import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  TextRecognizer? _textRecognizer;

  TextRecognizer get textRecognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Process image at path using on-device ML Kit OCR
  Future<String> recognizeTextFromImagePath(String imagePath) async {
    final file = File(imagePath);
    if (!await file.exists()) {
      throw Exception('Tệp ảnh không tồn tại: $imagePath');
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );

    return recognizedText.text;
  }

  /// Dispose ML Kit resources when finished
  void dispose() {
    _textRecognizer?.close();
    _textRecognizer = null;
  }
}
