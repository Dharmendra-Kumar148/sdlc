import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_gpu_video_filters/flutter_gpu_video_filters.dart';
import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import '../model/media/media_model.dart';
import '../model/preset/filter_preset.dart';
import '../utils/filter_utils.dart';
import '../core/logging/logger_service.dart';

class VideoProcessingService {
  Future<File?> applyFilterAndExport(
    File inputFile, 
    EffectLayer layer, {
    String? emojiOverlayPath,
    Function(double)? onProgress,
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final outputFileName = "final_video_${DateTime.now().millisecondsSinceEpoch}.mp4";
      final outputFile = File(p.join(tempDir.path, outputFileName));
      
      File currentInputFile = inputFile;
      final gpuFilter = FilterUtils.getGPUConfigs(layer).lastOrNull;

      // Pass 1: Apply Primary GPU Filter (Distortion/Color)
      if (gpuFilter != null) {
        final pass1File = File(p.join(tempDir.path, "pass1_${DateTime.now().millisecondsSinceEpoch}.mp4"));
        LoggerService.log(LoggerService.filterEngine, "Pass 1: Applying ${gpuFilter.runtimeType}...");
        
        final exportConfig = VideoExportConfig(FileInputSource(currentInputFile), pass1File.absolute);
        await gpuFilter.prepare();
        final stream = gpuFilter.exportVideoFile(exportConfig);
        
        await for (final progress in stream) {
          if (onProgress != null) onProgress(progress * 0.6);
        }
        
        await Future.delayed(const Duration(milliseconds: 500));
        if (await pass1File.exists() && await pass1File.length() > 0) {
          currentInputFile = pass1File;
        }
      }

      // Pass 2: Final Watermark (Noise Blocks + Color Tint + Emojis)
      String? finalOverlayPath = emojiOverlayPath;
      if (layer.type == FilterType.glitch) {
        final noiseFile = await _generateGlitchNoiseOverlay(layer.intensity, emojiOverlayPath);
        finalOverlayPath = noiseFile?.path;
      }

      if (finalOverlayPath != null) {
        LoggerService.log(LoggerService.filterEngine, "Pass 2: Applying combined glitch/emoji overlay...");
        final watermarkConfig = GPUWatermarkConfiguration();
        await _setWatermarkImage(watermarkConfig, finalOverlayPath);
        
        final exportConfig = VideoExportConfig(FileInputSource(currentInputFile), outputFile.absolute);
        await watermarkConfig.prepare();
        final stream = watermarkConfig.exportVideoFile(exportConfig);
        
        await for (final progress in stream) {
          if (onProgress != null) {
            onProgress(0.6 + (progress * 0.4));
          }
        }
        
        await Future.delayed(const Duration(milliseconds: 500));
        // Cleanup Pass 1 intermediate
        if (currentInputFile != inputFile) {
          try { await currentInputFile.delete(); } catch (_) {}
        }
        // Cleanup noise file
        if (layer.type == FilterType.glitch && finalOverlayPath != emojiOverlayPath) {
          try { await File(finalOverlayPath).delete(); } catch (_) {}
        }
      } else if (currentInputFile != inputFile) {
        await currentInputFile.copy(outputFile.path);
        try { await currentInputFile.delete(); } catch (_) {}
      } else {
        await inputFile.copy(outputFile.path);
        return outputFile;
      }

      if (await outputFile.exists() && await outputFile.length() > 0) {
        return outputFile;
      } else {
        throw Exception("Export failed: Final file is missing or empty.");
      }
    } catch (e, stack) {
      LoggerService.error(LoggerService.filterEngine, "Video export failed", e, stack);
      return null;
    }
  }

  Future<File?> _generateGlitchNoiseOverlay(double intensity, String? baseEmojiPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      Uint8List? emojiBytes;
      if (baseEmojiPath != null) {
        emojiBytes = await File(baseEmojiPath).readAsBytes();
      }

      // Offload image processing to background isolate to prevent UI freeze
      final result = await compute(_generateOverlayTask, {
        'intensity': intensity,
        'emojiBytes': emojiBytes,
      });

      if (result == null) return baseEmojiPath != null ? File(baseEmojiPath) : null;

      final outFile = File(p.join(tempDir.path, "glitch_final_${DateTime.now().millisecondsSinceEpoch}.png"));
      await outFile.writeAsBytes(result);
      return outFile;
    } catch (e) {
      LoggerService.error(LoggerService.filterEngine, "Glitch overlay generation failed", e);
      return baseEmojiPath != null ? File(baseEmojiPath) : null;
    }
  }

  static Uint8List? _generateOverlayTask(Map<String, dynamic> params) {
    try {
      final double intensity = params['intensity'];
      final Uint8List? emojiBytes = params['emojiBytes'];
      
      final image = img.Image(width: 1080, height: 1920);
      img.fill(image, color: img.ColorRgba8(0, 200, 255, (25 * intensity).toInt()));

      if (emojiBytes != null) {
        final emojiImage = img.decodeImage(emojiBytes);
        if (emojiImage != null) {
          img.compositeImage(image, emojiImage);
        }
      }

      final rand = Random();
      final blockCount = (30 * intensity).toInt().clamp(10, 60);
      for (int i = 0; i < blockCount; i++) {
        final color = [
          img.ColorRgba8(0, 255, 255, 150),
          img.ColorRgba8(255, 40, 255, 150),
          img.ColorRgba8(255, 255, 255, 100),
        ][rand.nextInt(3)];
        
        final x = rand.nextInt(1080);
        final y = rand.nextInt(1920);
        final w = rand.nextInt(500);
        final h = rand.nextInt(30);
        img.fillRect(image, x1: x, y1: y, x2: x + w, y2: y + h, color: color);
      }

      return img.encodePng(image);
    } catch (e) {
      return null;
    }
  }

  Future<void> _setWatermarkImage(GPUFilterConfiguration watermarkConfig, String emojiOverlayPath) async {
    final watermarkFile = File(emojiOverlayPath);
    final bytes = await watermarkFile.readAsBytes();
    
    bool paramSet = false;
    final possibleNames = ['inputImage2', 'watermark', 'inputTexture', 'inputWatermark'];
    
    for (final name in possibleNames) {
      try {
        final param = watermarkConfig.parameters.firstWhere((p) => p.name == name);
        if (param is DataParameter) {
          param.data = bytes;
          paramSet = true;
          break;
        } else {
          (param as dynamic).file = watermarkFile;
          paramSet = true;
          break;
        }
      } catch (_) {}
    }
    
    if (!paramSet) {
      LoggerService.warning(LoggerService.filterEngine, "Could not find suitable parameter for watermark.");
    }
  }
}
