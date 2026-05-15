import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceOverlayPainter extends CustomPainter {
  final List<Face> faces;
  final Size absoluteImageSize;
  final Color lipstickColor;
  final double lipstickIntensity;
  final Color blushColor;
  final double blushIntensity;

  FaceOverlayPainter({
    required this.faces,
    required this.absoluteImageSize,
    required this.lipstickColor,
    required this.lipstickIntensity,
    this.blushColor = Colors.pinkAccent,
    this.blushIntensity = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    for (final face in faces) {
      if (lipstickIntensity > 0) {
        _drawLipstick(canvas, face, scaleX, scaleY);
      }
      if (blushIntensity > 0) {
        _drawBlush(canvas, face, scaleX, scaleY);
      }
    }
  }

  void _drawBlush(Canvas canvas, Face face, double scaleX, double scaleY) {
    final leftCheek = face.landmarks[FaceLandmarkType.leftCheek]?.position;
    final rightCheek = face.landmarks[FaceLandmarkType.rightCheek]?.position;

    if (leftCheek == null && rightCheek == null) return;

    final radius = 35.0 * scaleX;
    
    void drawCheek(Point<int> pos) {
      final center = Offset(pos.x.toDouble() * scaleX, pos.y.toDouble() * scaleY);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            blushColor.withOpacity(blushIntensity * 0.4),
            blushColor.withOpacity(0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius, paint);
    }

    if (leftCheek != null) drawCheek(leftCheek);
    if (rightCheek != null) drawCheek(rightCheek);
  }

  void _drawLipstick(Canvas canvas, Face face, double scaleX, double scaleY) {
    final upperTop = face.contours[FaceContourType.upperLipTop]?.points;
    final upperBottom = face.contours[FaceContourType.upperLipBottom]?.points;
    final lowerTop = face.contours[FaceContourType.lowerLipTop]?.points;
    final lowerBottom = face.contours[FaceContourType.lowerLipBottom]?.points;

    if (upperTop == null || lowerBottom == null) return;

    final paint = Paint()
      ..color = lipstickColor.withOpacity(lipstickIntensity * 0.7)
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final path = Path();
    
    // 1. Draw Upper Lip
    path.moveTo(upperTop.first.x.toDouble() * scaleX, upperTop.first.y.toDouble() * scaleY);
    for (var p in upperTop) path.lineTo(p.x.toDouble() * scaleX, p.y.toDouble() * scaleY);
    if (upperBottom != null) {
      for (var p in upperBottom.reversed) path.lineTo(p.x.toDouble() * scaleX, p.y.toDouble() * scaleY);
    }
    path.close();

    // 2. Draw Lower Lip
    if (lowerTop != null) {
      path.moveTo(lowerTop.first.x.toDouble() * scaleX, lowerTop.first.y.toDouble() * scaleY);
      for (var p in lowerTop) path.lineTo(p.x.toDouble() * scaleX, p.y.toDouble() * scaleY);
      for (var p in lowerBottom.reversed) path.lineTo(p.x.toDouble() * scaleX, p.y.toDouble() * scaleY);
      path.close();
    } else {
      // Fallback if inner contour missing
      path.moveTo(lowerBottom.first.x.toDouble() * scaleX, lowerBottom.first.y.toDouble() * scaleY);
      for (var p in lowerBottom) path.lineTo(p.x.toDouble() * scaleX, p.y.toDouble() * scaleY);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(FaceOverlayPainter oldDelegate) {
    return oldDelegate.faces != faces || 
           oldDelegate.lipstickColor != lipstickColor ||
           oldDelegate.lipstickIntensity != lipstickIntensity;
  }
}
