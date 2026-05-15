import 'dart:io';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sdlc/core/logging/logger_service.dart';

class FaceProcessorService {
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true, // Needed for Lipstick/Reshaping
      enableLandmarks: true, // Needed for Eyes/Nose
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  Future<List<Face>> processImage(File imageFile) async {
    final startTime = DateTime.now();
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);
      
      final duration = DateTime.now().difference(startTime);
      LoggerService.log(LoggerService.filterEngine, "[FACE_TRACKER] Detected ${faces.length} faces in ${duration.inMilliseconds}ms");
      
      return faces;
    } catch (e) {
      LoggerService.error(LoggerService.filterEngine, "Face detection failed", e);
      return [];
    }
  }

  void dispose() {
    _faceDetector.close();
  }
}
