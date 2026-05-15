import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sdlc/services/engine/face/face_processor_service.dart';
import 'package:sdlc/core/logging/logger_service.dart';

class MakeupViewModel extends ChangeNotifier {
  final FaceProcessorService _faceService = FaceProcessorService();
  
  List<Face> _detectedFaces = [];
  List<Face> get detectedFaces => _detectedFaces;

  Color _lipstickColor = Colors.transparent;
  Color get lipstickColor => _lipstickColor;
  double _lipstickIntensity = 0.0;
  double get lipstickIntensity => _lipstickIntensity;

  void updateLipstick(Color color, double intensity) {
    _lipstickColor = color;
    _lipstickIntensity = intensity;
    LoggerService.log(LoggerService.ui, "[MAKEUP] Updating lipstick: $color, intensity: $intensity");
    notifyListeners();
  }

  Future<void> detectFaces(File file) async {
    _detectedFaces = await _faceService.processImage(file);
    notifyListeners();
  }

  @override
  void dispose() {
    _faceService.dispose();
    super.dispose();
  }
}
