import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gpu_video_filters/flutter_gpu_video_filters.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
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
      case FilterType.vintage:
        return ColorFilter.matrix([
          0.9, 0.1, 0.1, 0, 0,
          0.1, 0.8, 0.1, 0, 0,
          0.1, 0.1, 0.7, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case FilterType.cinematicCool:
        return ColorFilter.matrix([
          0.8, 0.1, 0.2, 0, 0,
          0.1, 0.9, 0.2, 0, 0,
          0.1, 0.1, 1.3, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case FilterType.skinSmoothing:
        // Much stronger smoothing/brightening matrix
        final i = 1.0 + (intensity * 0.4); 
        return ColorFilter.matrix([
          i, 0.05, 0.0, 0.0, 0,
          0.0, i, 0.0, 0.0, 0,
          0.0, 0.0, i, 0.0, 0,
          0, 0, 0, 1, 0,
        ]);
      case FilterType.glow:
        // Aggressive glow amplification
        final g = 1.0 + (intensity * 1.2);
        return ColorFilter.matrix([
          g, 0, 0, 0, 0,
          0, g, 0, 0, 0,
          0, 0, g, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case FilterType.glitch:
        // Match the "Broken" matrix used in the GPU export for consistency
        final shift = intensity * 40;
        return ColorFilter.matrix([
          -0.5, 2.0, 0.0, 0, shift,
          0.0, -0.5, 2.0, 0, shift * 0.5,
          2.0, 0.0, -0.5, 0, -shift,
          0, 0, 0, 1, 0,
        ]);
      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
    }
  }

  static List<GPUFilterConfiguration> getGPUConfigs(EffectLayer layer) {
    final List<GPUFilterConfiguration> configs = [];
    
    switch (layer.type) {
      case FilterType.brightness:
        configs.add(GPUBrightnessConfiguration()..brightness = layer.intensity);
        break;
      case FilterType.contrast:
        configs.add(GPUContrastConfiguration()..contrast = 1.0 + layer.intensity);
        break;
      case FilterType.grayscale:
        configs.add(GPUGrayScaleConfiguration());
        break;
      case FilterType.sepia:
        configs.add(GPUSepiaConfiguration());
        break;
      case FilterType.vintage:
        configs.add(GPUColorMatrixConfiguration()
          ..colorMatrix = Matrix4.fromList([
            0.9, 0.1, 0.1, 0.0,
            0.1, 0.8, 0.1, 0.0,
            0.1, 0.1, 0.7, 0.0,
            0.0, 0.0, 0.0, 1.0,
          ]));
        break;
      case FilterType.cinematicCool:
        configs.add(GPUColorMatrixConfiguration()
          ..colorMatrix = Matrix4.fromList([
            0.8, 0.1, 0.2, 0.0,
            0.1, 0.9, 0.2, 0.0,
            0.1, 0.1, 1.3, 0.0,
            0.0, 0.0, 0.0, 1.0,
          ]));
        break;
      case FilterType.cinematicWarm:
        configs.add(GPUColorMatrixConfiguration()
          ..colorMatrix = Matrix4.fromList([
            1.2, 0.1, 0.1, 0.0,
            0.1, 1.1, 0.1, 0.0,
            0.1, 0.1, 0.9, 0.0,
            0.0, 0.0, 0.0, 1.0,
          ]));
        break;
      case FilterType.skinSmoothing:
        final i = 1.0 + (layer.intensity * 0.4);
        configs.add(GPUColorMatrixConfiguration()
          ..colorMatrix = Matrix4.fromList([
            i, 0.05, 0.0, 0.0,
            0.0, i, 0.0, 0.0,
            0.0, 0.0, i, 0.0,
            0.0, 0.0, 0.0, 1.0,
          ]));
        break;
      case FilterType.faceSlimming:
        configs.add(GPUBulgeDistortionConfiguration()
          ..radius = 0.5
          ..scale = -layer.intensity * 0.4);
        break;
      case FilterType.eyeEnlargement:
        configs.add(GPUBulgeDistortionConfiguration()
          ..radius = 0.3
          ..scale = layer.intensity * 0.5);
        break;
      case FilterType.glow:
        final g = 1.0 + (layer.intensity * 1.5);
        configs.add(GPUColorMatrixConfiguration()
          ..colorMatrix = Matrix4.fromList([
            g, 0.0, 0.0, 0.0,
            0.0, g, 0.0, 0.0,
            0.0, 0.0, g, 0.0,
            0.0, 0.0, 0.0, 1.0,
          ]));
        break;
      case FilterType.glitch:
        // High-fidelity static glitch for export:
        // Pass 1: "Broken" color matrix with inversion/overflow for a digital look
        final shift = layer.intensity * 0.4;
        configs.add(GPUColorMatrixConfiguration()
          ..colorMatrix = Matrix4.fromList([
            -0.5, 2.0, 0.0, shift,
            0.0, -0.5, 2.0, shift * 0.5,
            2.0, 0.0, -0.5, -shift,
            0.0, 0.0, 0.0, 1.0,
          ]));
          
        // Pass 2: Digital Pixelation to make it look "broken/blocky"
        configs.add(GPUPixelationConfiguration()
          ..pixel = 5.0 + (layer.intensity * 15.0));

        // Pass 3: Off-center distortion to create "bending"
        configs.add(GPUBulgeDistortionConfiguration()
          ..center = const Point<double>(0.2, 0.8)
          ..radius = 0.8
          ..scale = layer.intensity * 0.4);
        break;
      default:
        if (layer.type.name.contains('bulge')) {
          configs.add(GPUBulgeDistortionConfiguration()
            ..radius = 0.3
            ..scale = layer.intensity * 0.5);
        }
        break;
    }
    return configs;
  }
  static GPUFilterConfiguration get identityConfig => GPUColorMatrixConfiguration()..colorMatrix = Matrix4.identity();
}
