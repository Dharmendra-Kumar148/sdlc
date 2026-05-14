import 'dart:io';
import 'package:flutter/material.dart';
import '../model/media/media_model.dart';
import '../model/preset/filter_preset.dart';
import '../services/compression_service.dart';
import '../services/video_processing_service.dart';
import '../core/logging/logger_service.dart';

class CompressionViewModel extends ChangeNotifier {
  final CompressionService _compressionService = CompressionService();
  final VideoProcessingService _videoService = VideoProcessingService();

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

    try {
      if (media.type == MediaType.image) {
        // For images, the filter is already applied in FilterViewModel
        final compressed = await _compressionService.compressImage(media.file);
        if (compressed != null) {
          _finalMedia = MediaModel(
            file: compressed,
            type: MediaType.image,
            size: await compressed.length(),
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

        if (exported != null) {
          final compressed = await _compressionService.compressVideo(
            exported.path,
            onProgress: (p) => { _progress = 0.7 + (p * 0.3), notifyListeners() }
          );
          if (compressed != null) {
            _finalMedia = MediaModel(
              file: compressed,
              type: MediaType.video,
              size: await compressed.length(),
              width: media.width,
              height: media.height,
            );
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
