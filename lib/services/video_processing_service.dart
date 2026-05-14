import 'dart:io';
import 'package:flutter_gpu_video_filters/flutter_gpu_video_filters.dart';
import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
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
      final gpuFilter = FilterUtils.getGPUConfig(layer);

      // Pass 1: Apply Color Filter (if any)
      if (gpuFilter != null) {
        LoggerService.log(LoggerService.filterEngine, "Pass 1: Applying GPU filter ${layer.type}...");
        final pass1File = File(p.join(tempDir.path, "pass1_${DateTime.now().millisecondsSinceEpoch}.mp4"));
        final exportConfig = VideoExportConfig(FileInputSource(currentInputFile), pass1File.absolute);
        
        await gpuFilter.prepare();
        final stream = gpuFilter.exportVideoFile(exportConfig);
        await for (final progress in stream) {
          if (onProgress != null) onProgress(progress * 0.5);
        }
        
        // Ensure hardware releases the file
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (await pass1File.exists() && await pass1File.length() > 0) {
          currentInputFile = pass1File;
          LoggerService.success(LoggerService.filterEngine, "Pass 1 successful: ${pass1File.length()} bytes");
        } else {
          throw Exception("Pass 1 failed: Output file missing or empty.");
        }
      }

      // Pass 2: Apply Watermark (if any)
      if (emojiOverlayPath != null) {
        LoggerService.log(LoggerService.filterEngine, "Pass 2: Applying emoji watermark...");
        final watermarkConfig = GPUWatermarkConfiguration();
        await _setWatermarkImage(watermarkConfig, emojiOverlayPath);
        
        final exportConfig = VideoExportConfig(FileInputSource(currentInputFile), outputFile.absolute);
        await watermarkConfig.prepare();
        final stream = watermarkConfig.exportVideoFile(exportConfig);
        await for (final progress in stream) {
          final base = gpuFilter != null ? 0.5 : 0.0;
          final factor = gpuFilter != null ? 0.5 : 1.0;
          if (onProgress != null) onProgress(base + (progress * factor));
        }
        
        await Future.delayed(const Duration(milliseconds: 500));
      } else if (gpuFilter != null) {
        // If no emojis, move pass1 result to final output
        await currentInputFile.rename(outputFile.path);
      } else {
        // No filter, no emoji
        return inputFile;
      }

      if (await outputFile.exists() && await outputFile.length() > 0) {
        LoggerService.success(LoggerService.filterEngine, "Final video export complete: ${outputFile.path}");
        return outputFile;
      } else {
        throw Exception("Final export failed: Output file missing or empty.");
      }
    } catch (e, stack) {
      LoggerService.error(LoggerService.filterEngine, "Video export failed", e, stack);
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
          // Dynamic attempt
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
