import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_compress/video_compress.dart';
import '../model/media/media_model.dart';
import '../model/preset/filter_preset.dart';
import '../services/compression_service.dart';
import '../services/video_processing_service.dart';
import '../core/logging/logger_service.dart';

import '../services/engine/media_engine.dart';
import '../services/engine/adapters/isolate_processing_provider.dart';
import '../services/engine/effects/glitch_gif_service.dart';

class CompressionViewModel extends ChangeNotifier {
  final CompressionService _compressionService = CompressionService();
  final VideoProcessingService _videoService = VideoProcessingService();
  final MediaEngine _engine = MediaEngine()..setProvider(IsolateProcessingProvider());

  MediaModel? _finalMedia;
  MediaModel? get finalMedia => _finalMedia;

  double _progress = 0;
  double get progress => _progress;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  Future<void> compress(MediaModel media, FilterPreset preset, {String? emojiOverlayPath}) async {
    LoggerService.log(LoggerService.ui, "Starting final export pipeline...");
    _isProcessing = true;
    _progress = 0;
    notifyListeners();
    
    // Safety delay to allow UI to show the processing overlay
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      if (media.type == MediaType.image) {
        File? processedFile;
        
        // Special case: If glitch is applied to an image, convert to animated GIF
        if (preset.layers.any((l) => l.type == FilterType.glitch)) {
          LoggerService.log(LoggerService.filterEngine, "Glitch detected on photo - converting to GIF...");
          processedFile = await GlitchGifService().createGlitchGif(
            media.file, 
            preset.layers.firstWhere((l) => l.type == FilterType.glitch).intensity,
            onProgress: (p) {
              _progress = p;
              notifyListeners();
            },
          );
        } else {
          // Standard image filter processing
          processedFile = await _engine.process(media, preset);
        }
        
        if (processedFile != null) {
          _finalMedia = MediaModel(
            file: processedFile,
            type: MediaType.image, // GIFs are handled by Image.file
            size: await processedFile.length(),
            width: media.width,
            height: media.height,
          );
        }
      } else {
        // For videos, apply filters/overlays first, then compress
        final EffectLayer layer = preset.layers.isNotEmpty 
            ? preset.layers.first 
            : EffectLayer(id: 'none', type: FilterType.none);

        final exported = await _videoService.applyFilterAndExport(
          media.file, 
          layer, 
          emojiOverlayPath: emojiOverlayPath,
          onProgress: (p) => { _progress = p * 0.7, notifyListeners() }
        );

        if (exported != null && await exported.exists()) {
          final isGlitch = preset.layers.any((l) => l.type == FilterType.glitch);
          
          if (isGlitch) {
            LoggerService.log(LoggerService.ui, "Glitch video detected - skipping extra compression pass for quality.");
            _finalMedia = MediaModel(
              file: exported,
              type: MediaType.video,
              size: await exported.length(),
              width: media.width ?? 1080,
              height: media.height ?? 1920,
              duration: media.duration,
            );
            _progress = 1.0;
            notifyListeners();
          } else {
            LoggerService.log(LoggerService.ui, "Export successful, starting compression pass...");
            
            final compressed = await _compressionService.compressVideo(
              exported.path,
              onProgress: (p) => { _progress = 0.7 + (p * 0.3), notifyListeners() }
            );

            if (compressed != null && await compressed.exists()) {
              _finalMedia = MediaModel(
                file: compressed,
                type: MediaType.video,
                size: await compressed.length(),
                width: media.width ?? 1080,
                height: media.height ?? 1920,
                duration: media.duration,
              );
            } else {
              LoggerService.warning(LoggerService.ui, "Compression failed, using exported file.");
              _finalMedia = MediaModel(
                file: exported,
                type: MediaType.video,
                size: await exported.length(),
                width: media.width ?? 1080,
                height: media.height ?? 1920,
                duration: media.duration,
              );
            }
          }
        }
      }
      LoggerService.success(LoggerService.ui, "Export Pipeline Complete.");
    } catch (e, stack) {
      LoggerService.error(LoggerService.ui, "Export Pipeline Failed", e, stack);
    } finally {
      _isProcessing = false;
      _progress = 1.0;
      notifyListeners();
    }
  }

  Future<void> cancel() async {
    LoggerService.warning(LoggerService.ui, "User cancelled export process.");
    await VideoCompress.cancelCompression();
    _isProcessing = false;
    _progress = 0;
    notifyListeners();
  }

  void clear() {
    _finalMedia = null;
    _progress = 0;
    notifyListeners();
  }
}
