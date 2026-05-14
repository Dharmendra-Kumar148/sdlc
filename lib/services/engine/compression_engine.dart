import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/logging/logger_service.dart';
import '../../../model/preset/filter_preset.dart';

class CompressionEngine {
  Future<File?> compressImage(File file, FilterPreset preset) async {
    final originalSize = await file.length();
    LoggerService.log(LoggerService.compressionEngine, "Starting Quality-First Compression: ${file.path}");

    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(tempDir.path, "compressed_${DateTime.now().millisecondsSinceEpoch}.jpg");

    // Effect-Aware Strategy
    int quality = 85;
    
    // If cinematic filters are applied, preserve more detail
    bool hasCinematic = preset.layers.any((l) => 
      l.type == FilterType.vintage || l.type == FilterType.cinematicWarm || l.type == FilterType.cinematicCool
    );
    
    if (hasCinematic) {
      quality = 90; // Higher quality for cinematic grain preservation
      LoggerService.info(LoggerService.compressionEngine, "Cinematic effects detected. Adjusting quality to 90 to preserve grain.");
    } else if (originalSize > 5 * 1024 * 1024) {
      quality = 75;
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
      
      LoggerService.success(LoggerService.compressionEngine, 
        "Compression Complete\nFinal Size: ${(newSize / 1024 / 1024).toStringAsFixed(2)} MB\nReduction: $reduction%");
      
      return compressedFile;
    }
    return null;
  }
}
