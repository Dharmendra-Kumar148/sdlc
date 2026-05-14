import 'package:flutter/material.dart';
import 'package:flutter_gpu_video_filters/flutter_gpu_video_filters.dart';
import '../model/media/media_model.dart';
import '../model/preset/filter_preset.dart';

class FilterUtils {
  static ColorFilter getFilter(EffectLayer layer) {
    if (layer.type == FilterType.none || !layer.isVisible) {
      return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
    }

    final double intensity = layer.intensity;

    switch (layer.type) {
      case FilterType.brightness:
        return ColorFilter.matrix([
          1, 0, 0, 0, intensity * 255,
          0, 1, 0, 0, intensity * 255,
          0, 0, 1, 0, intensity * 255,
          0, 0, 0, 1, 0,
        ]);
      case FilterType.grayscale:
        return const ColorFilter.matrix([
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0,      0,      0,      1, 0,
        ]);
      case FilterType.sepia:
        return ColorFilter.matrix([
          0.393 + 0.607 * (1 - intensity), 0.769 - 0.769 * (1 - intensity), 0.189 - 0.189 * (1 - intensity), 0, 0,
          0.349 - 0.349 * (1 - intensity), 0.686 + 0.314 * (1 - intensity), 0.168 - 0.168 * (1 - intensity), 0, 0,
          0.272 - 0.272 * (1 - intensity), 0.534 - 0.534 * (1 - intensity), 0.131 + 0.869 * (1 - intensity), 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case FilterType.cinematicWarm:
        return ColorFilter.matrix([
          1.2, 0.1, 0.1, 0, 0,
          0.1, 1.1, 0.1, 0, 0,
          0.1, 0.1, 0.9, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
    }
  }

  static GPUFilterConfiguration? getGPUConfig(EffectLayer layer) {
    switch (layer.type) {
      case FilterType.brightness:
        return GPUBrightnessConfiguration()..brightness = layer.intensity;
      case FilterType.contrast:
        return GPUContrastConfiguration()..contrast = 1.0 + layer.intensity;
      case FilterType.grayscale:
        return GPUGrayScaleConfiguration();
      case FilterType.sepia:
        return GPUSepiaConfiguration();
      default:
        return null;
    }
  }
}
