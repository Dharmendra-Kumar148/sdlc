import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import '../../../core/logging/logger_service.dart';

class GlitchGifService {
  Future<File?> createGlitchGif(File sourceFile, double intensity, {Function(double)? onProgress}) async {
    try {
      LoggerService.log(LoggerService.filterEngine, "Starting background Glitch-to-GIF conversion...");
      
      if (onProgress != null) onProgress(0.1);
      final bytes = await sourceFile.readAsBytes();
      
      // Use compute to prevent UI jank
      final result = await compute(_generateGlitchGifTask, {
        'bytes': bytes,
        'intensity': intensity,
      });

      if (onProgress != null) onProgress(0.9);
      
      if (result == null) return null;

      final tempDir = await getTemporaryDirectory();
      final outputFile = File(p.join(tempDir.path, "glitch_${DateTime.now().millisecondsSinceEpoch}.gif"));
      await outputFile.writeAsBytes(result);

      if (onProgress != null) onProgress(1.0);
      LoggerService.success(LoggerService.filterEngine, "Glitch GIF created successfully.");
      return outputFile;
    } catch (e, stack) {
      LoggerService.error(LoggerService.filterEngine, "Failed to create Glitch GIF", e, stack);
      return null;
    }
  }

  static Uint8List? _generateGlitchGifTask(Map<String, dynamic> params) {
    try {
      final Uint8List bytes = params['bytes'];
      final double intensity = params['intensity'];
      final rand = Random();

      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) return null;

      img.Image baseImage = originalImage;
      if (baseImage.width > 720) {
        baseImage = img.copyResize(baseImage, width: 720);
      }

      img.Image? firstFrame;
      
      for (int f = 0; f < 10; f++) {
        img.Image frame = img.Image.from(baseImage);
        _applyColorGlitchStatic(frame, intensity, rand);
        _applyBlockGlitchStatic(frame, intensity, rand);
        
        frame.frameDuration = 100;
        
        if (firstFrame == null) {
          firstFrame = frame;
        } else {
          firstFrame.addFrame(frame);
        }
      }

      if (firstFrame == null) return null;
      return img.encodeGif(firstFrame);
    } catch (e) {
      return null;
    }
  }

  static void _applyColorGlitchStatic(img.Image image, double intensity, Random rand) {
    if (intensity <= 0) return;
    for (var pixel in image) {
      if (rand.nextDouble() < 0.05 * intensity) {
        final r = pixel.r;
        final g = pixel.g;
        pixel.r = g;
        pixel.g = r;
        pixel.b = (pixel.b + (rand.nextDouble() * 50 * intensity)).toInt().clamp(0, 255);
      }
    }
  }

  static void _applyBlockGlitchStatic(img.Image image, double intensity, Random rand) {
    final blockCount = (10 * intensity).toInt().clamp(2, 20);
    for (int i = 0; i < blockCount; i++) {
      final x = rand.nextInt(image.width);
      final y = rand.nextInt(image.height);
      final w = rand.nextInt((image.width * 0.3 * intensity).toInt().clamp(10, image.width));
      final h = rand.nextInt(15).clamp(2, 15);
      final color = [
        img.ColorRgba8(0, 255, 255, 100),
        img.ColorRgba8(255, 0, 255, 100),
        img.ColorRgba8(255, 255, 255, 80),
      ][rand.nextInt(3)];

      for (int ry = y; ry < y + h && ry < image.height; ry++) {
        for (int rx = x; rx < x + w && rx < image.width; rx++) {
          image.setPixel(rx, ry, color);
        }
      }
    }
  }
}
