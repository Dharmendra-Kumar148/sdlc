import 'package:flutter/material.dart';
import 'package:sdlc/services/engine/media_engine.dart';
import 'package:sdlc/services/engine/adapters/isolate_processing_provider.dart';
import 'package:sdlc/services/engine/adapters/gpu_processing_provider.dart';
import 'package:sdlc/model/media/media_model.dart';
import 'package:sdlc/model/preset/filter_preset.dart';
import 'package:sdlc/core/logging/logger_service.dart';

class FilterViewModel extends ChangeNotifier {
  final MediaEngine _engine = MediaEngine();
  MediaEngine get engine => _engine;
  
  bool _isRendering = false;
  bool get isRendering => _isRendering;

  MediaModel? _originalMedia;
  MediaModel? _processedMedia;
  MediaModel? get processedMedia => _processedMedia ?? _originalMedia;

  FilterPreset _currentPreset = FilterPreset.none;
  FilterPreset get currentPreset => _currentPreset;

  FilterViewModel() {
    // Phase 1: Default to Isolate provider
    _engine.setProvider(IsolateProcessingProvider());
  }

  void init(MediaModel media) {
    LoggerService.log(LoggerService.ui, "FilterViewModel initialized for media: ${media.file.path}");
    _originalMedia = media;
    _processedMedia = null;
    _currentPreset = FilterPreset.none;
    notifyListeners();
  }

  Future<void> applyFilter(FilterType type, double intensity) async {
    if (_originalMedia == null || _isRendering) {
      debugPrint('[GPU_PIPELINE] Sequential check failed: Already rendering');
      return;
    }

    final startTime = DateTime.now();
    _isRendering = true;
    notifyListeners();

    try {
      debugPrint('[FILTER_PIPELINE] render start - Type: $type, Intensity: $intensity');
      
      // Stage 1: CPU Composition (Still enabled)
      final newLayer = EffectLayer(
        id: type.name,
        type: type,
        intensity: intensity,
      );

      _currentPreset = FilterPreset(
        id: 'current_session',
        name: 'Custom Look',
        layers: [newLayer],
      );

      // Stage 2: Controlled GPU Certification
      if (type == FilterType.brightness) {
        // Enforce GPU provider for certification stage
        _engine.setProvider(GPUProcessingProvider());
        
        final resultFile = await Future.any([
          _engine.process(_originalMedia!, _currentPreset),
          Future.delayed(const Duration(seconds: 3), () => throw Exception('GPU render timeout')),
        ]);

        if (resultFile != null) {
          _processedMedia = MediaModel(
            file: resultFile,
            type: MediaType.image,
            size: await resultFile.length(),
          );
        }
      }

      final duration = DateTime.now().difference(startTime);
      debugPrint('[FILTER_PIPELINE] render complete');
      debugPrint('[FILTER_PIPELINE] render duration: ${duration.inMilliseconds}ms');
    } catch (e, st) {
      debugPrint('[GPU_PIPELINE_ERROR] $e');
      debugPrintStack(stackTrace: st);
    } finally {
      _isRendering = false;
      notifyListeners();
    }
  }

  void reset() {
    LoggerService.info(LoggerService.ui, "Resetting engine and filters.");
    _processedMedia = null;
    _currentPreset = FilterPreset.none;
    notifyListeners();
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }
}
