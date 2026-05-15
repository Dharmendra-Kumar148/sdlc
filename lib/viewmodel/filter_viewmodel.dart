import 'package:flutter/material.dart';
import 'package:flutter_gpu_video_filters/flutter_gpu_video_filters.dart';
import 'package:sdlc/utils/filter_utils.dart';
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

  GPUFilterConfiguration? get currentGPUConfig {
    if (_currentPreset.layers.isEmpty) return null;
    final configs = FilterUtils.getGPUConfigs(_currentPreset.layers.first);
    return configs.isNotEmpty ? configs.last : null;
  }

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

  void applyFilter(FilterType type, double intensity) {
    if (_originalMedia == null) return;

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

    // Instant notification for the UI/GPU preview
    notifyListeners();
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
