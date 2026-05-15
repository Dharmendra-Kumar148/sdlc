import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gpu_video_filters/flutter_gpu_video_filters.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import '../model/media/media_model.dart';
import '../model/preset/filter_preset.dart';

class FilterUtils {
  /// CPU-based ColorFilter for real-time preview in editor
  static ColorFilter getFilter(EffectLayer layer) {
    if (layer.type == FilterType.none || !layer.isVisible) {
      return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
    }

    final double intensity = layer.intensity.clamp(0.0, 1.0);

    switch (layer.type) {
      // ============ BASIC FILTERS ============
      case FilterType.brightness:
        // Increase/decrease overall luminosity
        // intensity: 0.0 = dark (-100), 0.5 = normal, 1.0 = bright (+100)
        final brightnessValue = (intensity - 0.5) * 200; // Range: -100 to +100
        return ColorFilter.matrix([
          1, 0, 0, 0, brightnessValue,
          0, 1, 0, 0, brightnessValue,
          0, 0, 1, 0, brightnessValue,
          0, 0, 0, 1, 0,
        ]);

      case FilterType.contrast:
        // Increase/decrease difference between light and dark areas
        // intensity: 0.5 = low, 1.0 = normal, 1.5+ = high
        final contrastValue = 0.5 + (intensity * 1.5); // Range: 0.5 to 2.0
        final adjustment = (1.0 - contrastValue) * 128;
        return ColorFilter.matrix([
          contrastValue, 0, 0, 0, adjustment,
          0, contrastValue, 0, 0, adjustment,
          0, 0, contrastValue, 0, adjustment,
          0, 0, 0, 1, 0,
        ]);

      case FilterType.grayscale:
        // Convert to black and white with intensity control
        // intensity: 0.0 = full color, 0.5 = 50% grayscale, 1.0 = full grayscale
        final amount = intensity;
        return ColorFilter.matrix([
          0.2126 + 0.7874 * (1 - amount), 0.7152 - 0.7152 * (1 - amount), 0.0722 - 0.0722 * (1 - amount), 0, 0,
          0.2126 - 0.2126 * (1 - amount), 0.7152 + 0.2848 * (1 - amount), 0.0722 - 0.0722 * (1 - amount), 0, 0,
          0.2126 - 0.2126 * (1 - amount), 0.7152 - 0.7152 * (1 - amount), 0.0722 + 0.9278 * (1 - amount), 0, 0,
          0, 0, 0, 1, 0,
        ]);

      case FilterType.sepia:
        // Warm vintage brown tone for retro film look
        // intensity: 0.0 = original color, 1.0 = full sepia
        final amount = intensity;
        return ColorFilter.matrix([
          0.393 + 0.607 * (1 - amount), 0.769 - 0.769 * (1 - amount), 0.189 - 0.189 * (1 - amount), 0, 0,
          0.349 - 0.349 * (1 - amount), 0.686 + 0.314 * (1 - amount), 0.168 - 0.168 * (1 - amount), 0, 0,
          0.272 - 0.272 * (1 - amount), 0.534 - 0.534 * (1 - amount), 0.131 + 0.869 * (1 - amount), 0, 0,
          0, 0, 0, 1, 0,
        ]);

      // ============ CINEMATIC FILTERS ============
      case FilterType.cinematicWarm:
        // Golden warm cinematic look (like sunset/golden hour)
        final warmAmount = intensity * 0.4;
        return ColorFilter.matrix([
          1.0 + (0.2 * warmAmount), 0.0, -0.1 * warmAmount, 0, 30 * warmAmount,
          -0.05 * warmAmount, 1.0, -0.05 * warmAmount, 0, 20 * warmAmount,
          -0.1 * warmAmount, 0.0, 0.9, 0, -10 * warmAmount,
          0, 0, 0, 1, 0,
        ]);

      case FilterType.cinematicCool:
        // Cool blue/cyan cinematic look (like night/cool tones)
        final coolAmount = intensity * 0.3;
        return ColorFilter.matrix([
          0.9, -0.05 * coolAmount, 0.1 * coolAmount, 0, -20 * coolAmount,
          -0.05 * coolAmount, 0.95 + (0.1 * coolAmount), 0.05 * coolAmount, 0, 10 * coolAmount,
          0.1 * coolAmount, 0.05 * coolAmount, 1.0 + (0.15 * coolAmount), 0, 40 * coolAmount,
          0, 0, 0, 1, 0,
        ]);

      // ============ BEAUTY FILTERS ============
      case FilterType.skinSmoothing:
        // Soft skin smoothing with subtle brightness and reduced texture
        final smoothAmount = 1.0 + (intensity * 0.4);
        return ColorFilter.matrix([
          smoothAmount, 0.05 * intensity, 0.05 * intensity, 0, 20 * intensity,
          0.05 * intensity, smoothAmount, 0.05 * intensity, 0, 20 * intensity,
          0.02 * intensity, 0.02 * intensity, 0.95, 0, 10 * intensity,
          0, 0, 0, 1, 0,
        ]);

      case FilterType.glow:
        // Soft glowing effect - increased brightness with slight bloom
        final glowAmount = 1.0 + (intensity * 1.2);
        return ColorFilter.matrix([
          glowAmount, 0.05 * intensity, 0.05 * intensity, 0, 50 * intensity,
          0.05 * intensity, glowAmount, 0.05 * intensity, 0, 50 * intensity,
          0.05 * intensity, 0.05 * intensity, glowAmount, 0, 50 * intensity,
          0, 0, 0, 1, 0,
        ]);

      // ============ EFFECTS FILTERS ============
      case FilterType.vintage:
        // Classic vintage film look with desaturated colors and warm tone
        final vintageAmount = intensity * 0.3;
        return ColorFilter.matrix([
          1.0 + (0.1 * vintageAmount), 0.05 * vintageAmount, -0.05 * vintageAmount, 0, 15 * vintageAmount,
          0.02 * vintageAmount, 0.95 - (0.05 * vintageAmount), 0.02 * vintageAmount, 0, 10 * vintageAmount,
          -0.08 * vintageAmount, -0.05 * vintageAmount, 0.85, 0, -5 * vintageAmount,
          0, 0, 0, 1, 0,
        ]);

      case FilterType.glitch:
        // Digital glitch effect - RGB channel shifts with distortion
        final glitchAmount = intensity * 0.3;
        final shift = intensity * 40;
        return ColorFilter.matrix([
          1.0 - glitchAmount, glitchAmount * 0.5, -glitchAmount * 0.2, 0, shift * 0.5,
          -glitchAmount * 0.3, 1.0, glitchAmount * 0.3, 0, -shift * 0.5,
          glitchAmount * 0.2, -glitchAmount * 0.2, 1.0 - glitchAmount, 0, shift * 0.3,
          0, 0, 0, 1, 0,
        ]);

      default:
        return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
    }
  }

  /// GPU-based filter configurations for video export and high-quality rendering
  static List<GPUFilterConfiguration> getGPUConfigs(EffectLayer layer) {
    final List<GPUFilterConfiguration> configs = [];
    final intensity = layer.intensity.clamp(0.0, 1.0);

    switch (layer.type) {
      case FilterType.brightness:
        // GPU brightness: -1.0 (dark) to 1.0 (bright)
        configs.add(GPUBrightnessConfiguration()..brightness = (intensity - 0.5) * 2.0);
        break;

      case FilterType.contrast:
        // GPU contrast: 0.5 (low) to 2.0 (high)
        configs.add(GPUContrastConfiguration()..contrast = 0.5 + (intensity * 1.5));
        break;

      case FilterType.grayscale:
        // GPU grayscale - full desaturation
        configs.add(GPUGrayScaleConfiguration());
        break;

      case FilterType.sepia:
        // GPU sepia - warm vintage tone
        configs.add(GPUSepiaConfiguration());
        break;

      case FilterType.vintage:
        // Vintage: reduced saturation and warm tone using color matrix
        configs.add(GPUColorMatrixConfiguration()
          ..colorMatrix = Matrix4.fromList([
            0.9, 0.1, 0.1, 0.0,
            0.1, 0.8, 0.1, 0.0,
            0.1, 0.1, 0.7, 0.0,
            0.0, 0.0, 0.0, 1.0,
          ]));
        break;

      case FilterType.cinematicCool:
        // Cool blue cinematic tone
        configs.add(GPUColorMatrixConfiguration()
          ..colorMatrix = Matrix4.fromList([
            0.8, 0.1, 0.2, 0.0,
            0.1, 0.9, 0.2, 0.0,
            0.1, 0.1, 1.3, 0.0,
            0.0, 0.0, 0.0, 1.0,
          ]));
        break;

      case FilterType.cinematicWarm:
        // Warm golden cinematic tone
        configs.add(GPUColorMatrixConfiguration()
          ..colorMatrix = Matrix4.fromList([
            1.2, 0.1, 0.1, 0.0,
            0.1, 1.1, 0.1, 0.0,
            0.1, 0.1, 0.9, 0.0,
            0.0, 0.0, 0.0, 1.0,
          ]));
        break;

      case FilterType.skinSmoothing:
        // Skin smoothing: brightness boost + subtle color shift
        final smoothAmount = 1.0 + (intensity * 0.4);
        configs.add(GPUBrightnessConfiguration()..brightness = intensity * 0.1);
        configs.add(GPUColorMatrixConfiguration()
          ..colorMatrix = Matrix4.fromList([
            smoothAmount, 0.05, 0.0, 0.0,
            0.0, smoothAmount, 0.0, 0.0,
            0.0, 0.0, smoothAmount, 0.0,
            0.0, 0.0, 0.0, 1.0,
          ]));
        break;

      case FilterType.glow:
        // Glow: brightness increase for soft luminous effect
        configs.add(GPUBrightnessConfiguration()..brightness = intensity * 0.3);
        final glowAmount = 1.0 + (intensity * 1.5);
        configs.add(GPUColorMatrixConfiguration()
          ..colorMatrix = Matrix4.fromList([
            glowAmount, 0.0, 0.0, 0.0,
            0.0, glowAmount, 0.0, 0.0,
            0.0, 0.0, glowAmount, 0.0,
            0.0, 0.0, 0.0, 1.0,
          ]));
        break;

      case FilterType.glitch:
        // Glitch: digital distortion with contrast + color matrix
        configs.add(GPUContrastConfiguration()..contrast = 1.0 + (intensity * 0.5));
        
        final shift = intensity * 0.4;
        configs.add(GPUColorMatrixConfiguration()
          ..colorMatrix = Matrix4.fromList([
            1.0 - (shift * 0.5), shift * 0.2, -shift * 0.1, shift * 0.1,
            -shift * 0.15, 1.0, shift * 0.15, -shift * 0.1,
            shift * 0.1, -shift * 0.1, 1.0 - (shift * 0.3), shift * 0.15,
            0.0, 0.0, 0.0, 1.0,
          ]));

        // Add pixelation for "broken" digital look
        configs.add(GPUPixelationConfiguration()..pixel = 2.0 + (intensity * 8.0));
        break;

      default:
        break;
    }

    return configs;
  }

  /// Get single GPU config (backward compatibility)
  static GPUFilterConfiguration? getGPUConfig(EffectLayer layer) {
    final configs = getGPUConfigs(layer);
    return configs.isNotEmpty ? configs.first : null;
  }

  /// Identity/no-op GPU configuration
  static GPUFilterConfiguration get identityConfig =>
      GPUColorMatrixConfiguration()..colorMatrix = Matrix4.identity();

  /// Get human-readable filter name for UI display
  static String getFilterName(FilterType type) {
    switch (type) {
      case FilterType.brightness:
        return 'Brightness';
      case FilterType.contrast:
        return 'Contrast';
      case FilterType.grayscale:
        return 'Grayscale';
      case FilterType.sepia:
        return 'Sepia';
      case FilterType.cinematicWarm:
        return 'Warm';
      case FilterType.cinematicCool:
        return 'Cool';
      case FilterType.skinSmoothing:
        return 'Smooth';
      case FilterType.glow:
        return 'Glow';
      case FilterType.vintage:
        return 'Vintage';
      case FilterType.glitch:
        return 'Glitch';
      case FilterType.none:
        return 'None';
      default:
        return type.toString().split('.').last;
    }
  }

  /// Get filter description for tooltips
  static String getFilterDescription(FilterType type) {
    switch (type) {
      case FilterType.brightness:
        return 'Increase or decrease overall brightness';
      case FilterType.contrast:
        return 'Enhance the difference between light and dark areas';
      case FilterType.grayscale:
        return 'Convert to black and white';
      case FilterType.sepia:
        return 'Warm vintage brown tone';
      case FilterType.cinematicWarm:
        return 'Golden warm cinematic look';
      case FilterType.cinematicCool:
        return 'Cool blue cinematic look';
      case FilterType.skinSmoothing:
        return 'Soft skin smoothing effect';
      case FilterType.glow:
        return 'Soft glowing luminous effect';
      case FilterType.vintage:
        return 'Classic vintage film look';
      case FilterType.glitch:
        return 'Digital glitch effect';
      case FilterType.none:
        return 'No filter applied';
      default:
        return '';
    }
  }

  /// Get color for filter button in UI
  static Color getFilterColor(FilterType type) {
    switch (type) {
      case FilterType.brightness:
        return Colors.yellow.shade600;
      case FilterType.contrast:
        return Colors.grey.shade700;
      case FilterType.grayscale:
        return Colors.grey.shade500;
      case FilterType.sepia:
        return Colors.brown.shade600;
      case FilterType.cinematicWarm:
        return Colors.orange.shade600;
      case FilterType.cinematicCool:
        return Colors.blue.shade600;
      case FilterType.skinSmoothing:
        return Colors.pink.shade400;
      case FilterType.glow:
        return Colors.amber.shade400;
      case FilterType.vintage:
        return Colors.amber.shade700;
      case FilterType.glitch:
        return Colors.purple.shade600;
      case FilterType.none:
        return Colors.white;
      default:
        return Colors.grey;
    }
  }
}
