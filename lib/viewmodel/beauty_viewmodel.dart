import 'package:flutter/material.dart';
import 'package:sdlc/model/media/media_model.dart';
import 'package:sdlc/model/preset/filter_preset.dart';
import 'package:sdlc/services/engine/media_engine.dart';
import 'package:sdlc/core/logging/logger_service.dart';

class BeautyViewModel extends ChangeNotifier {
  final MediaEngine _engine;
  
  double _smoothingIntensity = 0.0;
  double get smoothingIntensity => _smoothingIntensity;

  BeautyViewModel(this._engine);

  void updateSmoothing(double value) {
    _smoothingIntensity = value;
    LoggerService.log(LoggerService.ui, "[BEAUTY] Updating skin smoothing intensity: $value");
    notifyListeners();
  }

  // This will be called by the EditorScreen when applying beauty effects
  FilterPreset getBeautyPreset() {
    if (_smoothingIntensity == 0) return FilterPreset.none;
    
    return FilterPreset(
      id: 'beauty_session',
      name: 'Beauty Layer',
      layers: [
        EffectLayer(
          id: 'skin_smoothing',
          type: FilterType.skinSmoothing,
          intensity: _smoothingIntensity,
        ),
      ],
    );
  }
}
