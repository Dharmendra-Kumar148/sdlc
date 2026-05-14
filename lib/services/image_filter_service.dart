import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../model/media/media_model.dart';
import '../core/logging/logger_service.dart';

class ImageFilterService {
  Future<File> applyFilter(File inputFile, FilterModel filter) async {
    LoggerService.log(LoggerService.filterEngine, "Starting filter application: ${filter.type}");
    final startTime = DateTime.now();

    // Use compute to run processing in a background isolate
    final resultBytes = await compute(_processImage, {
      'path': inputFile.path,
      'filter': filter,
    });

    final tempDir = await getTemporaryDirectory();
    final fileName = "filtered_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final outputFile = File(p.join(tempDir.path, fileName));
    await outputFile.writeAsBytes(resultBytes);

    final duration = DateTime.now().difference(startTime).inMilliseconds;
    LoggerService.success(LoggerService.filterEngine, "Filter Applied: ${filter.type} (Time: ${duration}ms)");
    
    return outputFile;
  }

  static Uint8List _processImage(Map<String, dynamic> params) {
    final String path = params['path'];
    final FilterModel filter = params['filter'];
    
    final bytes = File(path).readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);
    
    if (image == null) throw Exception("Could not decode image");

    switch (filter.type) {
      case FilterType.brightness:
        image = img.adjustColor(image, brightness: 1.0 + filter.intensity);
        break;
      case FilterType.contrast:
        image = img.adjustColor(image, contrast: 1.0 + filter.intensity);
        break;
      case FilterType.grayscale:
        image = img.grayscale(image);
        break;
      case FilterType.sepia:
        image = img.sepia(image, amount: filter.intensity);
        break;
      case FilterType.vintage:
        image = img.adjustColor(image, saturation: 0.6, contrast: 1.1);
        image = img.vignette(image, start: 0.5, end: 0.9);
        break;
      case FilterType.cinematicWarm:
        image = img.adjustColor(image, exposure: 0.1);
        image = img.colorOffset(image, red: (20 * filter.intensity).toInt(), green: (10 * filter.intensity).toInt());
        break;
      case FilterType.cinematicCool:
        image = img.adjustColor(image, exposure: 0.1);
        image = img.colorOffset(image, blue: (30 * filter.intensity).toInt(), green: (5 * filter.intensity).toInt());
        break;
      case FilterType.skinSmoothing:
        image = img.gaussianBlur(image, radius: (3 * filter.intensity).toInt());
        break;
      case FilterType.glow:
        final blurred = img.gaussianBlur(img.Image.from(image), radius: 10);
        image = img.compositeImage(image, blurred, blend: img.BlendMode.lighten);
        break;
      case FilterType.glitch:
        // Simple pixel shift for glitch effect
        image = img.colorOffset(image, red: 10, blue: -10);
        break;
      default:
        break;
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: 90));
  }
}
