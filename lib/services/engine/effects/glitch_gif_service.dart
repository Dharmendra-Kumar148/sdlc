import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../../core/logging/logger_service.dart';

class GlitchGifService {
  Future<File?> createGlitchGif(File sourceFile, double intensity) async {
    try {
      LoggerService.log(LoggerService.filterEngine, "Starting Glitch-to-GIF conversion...");
      
      final bytes = await sourceFile.readAsBytes();
      final originalImage = img.decodeImage(bytes);
      if (originalImage == null) return null;

      // Resize for performance if needed
      img.Image baseImage = originalImage;
      if (baseImage.width > 720) {
        baseImage = img.copyResize(baseImage, width: 720);
      }

      img.Image? firstFrame;
      final rand = Random();
      
      // Generate 12 frames for a smooth 1-second loop at 12fps
      for (int f = 0; f < 12; f++) {
        img.Image frame = img.Image.from(baseImage);
        
        // 1. Digital Color Distortion (Internal Glitch)
        _applyColorGlitch(frame, intensity, rand);
        
        // 2. Block Noise
        _applyBlockGlitch(frame, intensity, rand);
        
        frame.frameDuration = 80; // ~12 fps
        
        if (firstFrame == null) {
          firstFrame = frame;
        } else {
          firstFrame.addFrame(frame);
        }
      }

      if (firstFrame == null) return null;
      final gifBytes = img.encodeGif(firstFrame);
      if (gifBytes == null) return null;

      final tempDir = await getTemporaryDirectory();
      final outputFile = File(p.join(tempDir.path, "glitch_${DateTime.now().millisecondsSinceEpoch}.gif"));
      await outputFile.writeAsBytes(gifBytes);

      LoggerService.success(LoggerService.filterEngine, "Glitch GIF created: ${outputFile.path} (${outputFile.lengthSync()} bytes)");
      return outputFile;
    } catch (e, stack) {
      LoggerService.error(LoggerService.filterEngine, "Failed to create Glitch GIF", e, stack);
      return null;
    }
  }

  void _applyColorGlitch(img.Image image, double intensity, Random rand) {
    if (intensity <= 0) return;
    
    // Channel swapping and shifting
    for (var pixel in image) {
      if (rand.nextDouble() < 0.05 * intensity) {
        // Corrupt this pixel
        final r = pixel.r;
        final g = pixel.g;
        final b = pixel.b;
        
        // Swap R and G for a digital error look
        pixel.r = g;
        pixel.g = r;
        pixel.b = (b + (rand.nextDouble() * 50 * intensity)).toInt().clamp(0, 255);
      }
    }
  }

  void _applyBlockGlitch(img.Image image, double intensity, Random rand) {
    final blockCount = (10 * intensity).toInt().clamp(2, 20);
    
    for (int i = 0; i < blockCount; i++) {
      final x = rand.nextInt(image.width);
      final y = rand.nextInt(image.height);
      final w = rand.nextInt((image.width * 0.3 * intensity).toInt().clamp(10, image.width));
      final h = rand.nextInt(15).clamp(2, 15);
      
      final color = [
        img.ColorRgba8(0, 255, 255, 100), // Cyan
        img.ColorRgba8(255, 0, 255, 100), // Magenta
        img.ColorRgba8(255, 255, 255, 80), // White
      ][rand.nextInt(3)];

      // Draw a glitch rectangle
      for (int ry = y; ry < y + h && ry < image.height; ry++) {
        for (int rx = x; rx < x + w && rx < image.width; rx++) {
          image.setPixel(rx, ry, color);
        }
      }
    }
  }
}
