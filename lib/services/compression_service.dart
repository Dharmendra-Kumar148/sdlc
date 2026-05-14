import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../model/media/media_model.dart';
import '../core/logging/logger_service.dart';

class CompressionService {
  Future<File?> compressImage(File file) async {
    final originalSize = await file.length();
    LoggerService.log(LoggerService.compressionEngine, "Compressing Image: ${file.path} ($originalSize bytes)");

    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(tempDir.path, "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg");

    // Adaptive Quality Strategy
    int quality = 85;
    if (originalSize > 5 * 1024 * 1024) { // > 5MB
      quality = 70;
    } else if (originalSize > 2 * 1024 * 1024) { // > 2MB
      quality = 80;
    }

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      format: CompressFormat.jpeg,
    );

    if (result != null) {
      final compressedFile = File(result.path);
      final newSize = await compressedFile.length();
      final reduction = ((originalSize - newSize) / originalSize * 100).toStringAsFixed(1);
      
      LoggerService.success(LoggerService.compressionEngine, "Image Compressed: $newSize bytes (Reduced by $reduction%)");
      return compressedFile;
    }
    return null;
  }

  Future<File?> compressVideo(String path, {Function(double)? onProgress}) async {
    final originalSize = await File(path).length();
    LoggerService.log(LoggerService.compressionEngine, "Compressing Video: $path ($originalSize bytes)");

    if (onProgress != null) {
      VideoCompress.compressProgress$.subscribe((progress) {
        onProgress(progress / 100);
      });
    }

    // Adaptive Bitrate / Quality Strategy
    VideoQuality quality = VideoQuality.MediumQuality;
    if (originalSize > 50 * 1024 * 1024) { // > 50MB
      quality = VideoQuality.LowQuality;
    }

    final info = await VideoCompress.compressVideo(
      path,
      quality: quality,
      deleteOrigin: false,
      includeAudio: true,
    );

    if (info != null && info.file != null) {
      final newSize = await info.file!.length();
      final reduction = ((originalSize - newSize) / originalSize * 100).toStringAsFixed(1);
      
      LoggerService.success(LoggerService.compressionEngine, "Video Compressed: $newSize bytes (Reduced by $reduction%)");
      return info.file;
    }
    return null;
  }
}
