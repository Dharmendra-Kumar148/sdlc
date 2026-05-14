import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sdlc/core/engine/engine_state.dart';
import 'package:sdlc/core/logging/logger_service.dart';
import 'package:sdlc/model/preset/filter_preset.dart';
import 'package:sdlc/services/engine/pipeline/i_processing_provider.dart';
import 'package:sdlc/services/engine/effects/skin_smoothing_processor.dart';

class IsolateProcessingProvider implements IProcessingProvider {
  @override
  Future<File> applyPreset(File inputFile, FilterPreset preset) async {
    LoggerService.log(LoggerService.filterPipeline, "Starting Isolate-based processing for ${preset.name}");
    
    final resultBytes = await compute(_processImage, {
      'path': inputFile.path,
      'preset': preset.toJson(),
    });

    final tempDir = await getTemporaryDirectory();
    final fileName = "processed_${DateTime.now().millisecondsSinceEpoch}.jpg";
    final outputFile = File(p.join(tempDir.path, fileName));
    await outputFile.writeAsBytes(resultBytes);

    return outputFile;
  }

  static Uint8List _processImage(Map<String, dynamic> params) {
    final String path = params['path'];
    final FilterPreset preset = FilterPreset.fromJson(params['preset']);
    
    final bytes = File(path).readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception("Could not decode image");

    // Process layers sequentially
    for (final layer in preset.layers) {
      if (!layer.isVisible) continue;
      
      switch (layer.type) {
        case FilterType.brightness:
          image = img.adjustColor(image!, brightness: 1.0 + layer.intensity);
          break;
        case FilterType.contrast:
          image = img.adjustColor(image!, contrast: 1.0 + layer.intensity);
          break;
        case FilterType.grayscale:
          image = img.grayscale(image!);
          break;
        case FilterType.sepia:
          image = img.sepia(image!, amount: layer.intensity);
          break;
        case FilterType.vintage:
          image = img.adjustColor(image!, saturation: 0.6, contrast: 1.1);
          image = img.vignette(image!, start: 0.5, end: 0.9);
          break;
        case FilterType.cinematicWarm:
          image = img.adjustColor(image!, exposure: 0.1);
          image = img.colorOffset(image!, red: (20 * layer.intensity).toInt(), green: (10 * layer.intensity).toInt());
          break;
        case FilterType.cinematicCool:
          image = img.adjustColor(image!, exposure: 0.1);
          image = img.colorOffset(image!, blue: (30 * layer.intensity).toInt(), green: (5 * layer.intensity).toInt());
          break;
        case FilterType.skinSmoothing:
          image = SkinSmoothingProcessor.apply(image!, layer.intensity);
          break;
        case FilterType.glow:
          final blurred = img.gaussianBlur(image!.clone(), radius: 10);
          // Using modern compositeImage if available, or manual blend
          image = img.compositeImage(image!, blurred, blend: img.BlendMode.lighten);
          break;
        case FilterType.glitch:
          // Modern colorOffset or manual channel shift
          image = img.colorOffset(image!, red: 10, blue: -10);
          break;
        default:
          break;
      }
    }

    return Uint8List.fromList(img.encodeJpg(image!, quality: 90));
  }

  @override
  Future<void> dispose() async {
    LoggerService.log(LoggerService.memoryManager, "IsolateProcessingProvider cleaning up references.");
  }
}
