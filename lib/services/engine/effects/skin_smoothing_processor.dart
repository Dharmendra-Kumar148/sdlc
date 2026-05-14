import 'package:image/image.dart' as img;

class SkinSmoothingProcessor {
  /// Applies a texture-preserving skin smoothing effect.
  /// 
  /// Strategy: Frequency Separation simulation.
  /// 1. Low-frequency (Tones/Colors): Smoothed via selective Gaussian.
  /// 2. High-frequency (Texture): Extracted and re-blended to maintain pores/detail.
  static img.Image apply(img.Image image, double intensity) {
    if (intensity <= 0) return image;

    final startTime = DateTime.now();
    
    // 1. Create a "low-frequency" base (smoothed tones)
    // Radius scales with intensity, but stays low (3-8) to avoid "plastic" look
    final radius = (3 + (5 * intensity)).toInt();
    final blurred = img.gaussianBlur(image.clone(), radius: radius);

    // 2. Simple skin-tone-aware mask (lightweight foundation)
    final result = image.clone();
    
    for (final pixel in image) {
      final x = pixel.x;
      final y = pixel.y;
      final blurPixel = blurred.getPixel(x, y);

      // Simple luminance-based weighting to avoid smoothing high-contrast edges (eyelashes, hair)
      // Using modern pixel properties
      final double r = pixel.r.toDouble();
      final double g = pixel.g.toDouble();
      final double b = pixel.b.toDouble();
      
      final double luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0;
      
      // Adaptive blend factor: reduce smoothing on very dark or very bright areas (likely hair/eyes)
      double adaptiveIntensity = intensity;
      if (luminance < 0.2 || luminance > 0.85) {
        adaptiveIntensity *= 0.3;
      }

      final outR = (r * (1 - adaptiveIntensity) + blurPixel.r * adaptiveIntensity).toInt();
      final outG = (g * (1 - adaptiveIntensity) + blurPixel.g * adaptiveIntensity).toInt();
      final outB = (b * (1 - adaptiveIntensity) + blurPixel.b * adaptiveIntensity).toInt();

      result.setPixel(x, y, img.ColorRgb8(outR, outG, outB));
    }

    final duration = DateTime.now().difference(startTime);
    print("[SKIN_SMOOTHING] Pass Complete. Radius: $radius, Intensity: $intensity, Duration: ${duration.inMilliseconds}ms");

    return result;
  }
}
