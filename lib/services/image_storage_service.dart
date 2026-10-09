import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageStorageService {
  final Uuid _uuid = const Uuid();

  /// Saves a temporary image file (from camera or gallery) into app document storage directory
  Future<String?> saveImageLocally(String tempPath) async {
    try {
      final file = File(tempPath);
      if (!await file.exists()) return null;

      final docsDir = await getApplicationDocumentsDirectory();
      final receiptsDir = Directory(p.join(docsDir.path, 'receipt_images'));

      if (!await receiptsDir.exists()) {
        await receiptsDir.create(recursive: true);
      }

      final ext = p.extension(tempPath).isNotEmpty
          ? p.extension(tempPath)
          : '.jpg';
      final fileName = 'receipt_${_uuid.v4()}$ext';
      final savedPath = p.join(receiptsDir.path, fileName);

      final savedFile = await file.copy(savedPath);
      return savedFile.path;
    } catch (e) {
      return null;
    }
  }

  /// Verifies if local image exists at given path
  Future<bool> imageExists(String? path) async {
    if (path == null || path.isEmpty) return false;
    return await File(path).exists();
  }
}
