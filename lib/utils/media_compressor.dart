import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class MediaCompressor {
  /// Compresses [bytes] of an image. If the image is already smaller than 150 KB,
  /// it skips compression.
  static Future<Uint8List> compressImageBytes(Uint8List bytes, {int quality = 70}) async {
    try {
      final double sizeInKb = bytes.lengthInBytes / 1024;
      debugPrint("Original image size: ${sizeInKb.toStringAsFixed(2)} KB");

      if (bytes.lengthInBytes < 150 * 1024) {
        debugPrint("Image is already small (${sizeInKb.toStringAsFixed(2)} KB), skipping compression.");
        return bytes;
      }

      final Uint8List compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minWidth: 1080,
        minHeight: 1080,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      final double compressedSizeInKb = compressedBytes.lengthInBytes / 1024;
      debugPrint("Compressed image size: ${compressedSizeInKb.toStringAsFixed(2)} KB");
      return compressedBytes;
    } catch (e) {
      debugPrint("Image compression failed: $e");
      return bytes;
    }
  }

  /// Compresses [file] of an image. If the image file is already smaller than 150 KB,
  /// it skips compression.
  static Future<File> compressImageFile(File file, {int quality = 70}) async {
    try {
      final int originalSize = file.lengthSync();
      final double sizeInKb = originalSize / 1024;
      debugPrint("Original image file size: ${sizeInKb.toStringAsFixed(2)} KB");

      if (originalSize < 150 * 1024) {
        debugPrint("Image file is already small (${sizeInKb.toStringAsFixed(2)} KB), skipping compression.");
        return file;
      }

      final String targetPath = file.path.replaceAll(RegExp(r'\.[^.]+$'), '_compressed.jpg');
      
      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        minWidth: 1080,
        minHeight: 1080,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        final compressedFileInstance = File(compressedFile.path);
        final double compressedSizeInKb = compressedFileInstance.lengthSync() / 1024;
        debugPrint("Compressed image file size: ${compressedSizeInKb.toStringAsFixed(2)} KB");
        return compressedFileInstance;
      }
      return file;
    } catch (e) {
      debugPrint("Image file compression failed: $e");
      return file;
    }
  }
}
