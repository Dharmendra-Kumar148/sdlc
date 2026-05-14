import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = "GaonGram";

  // Colors - Premium Aesthetic
  static const Color darkBackground = Color(0xFF050505);
  static const Color surfaceColor = Color(0xFF121212);
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color accentPink = Color(0xFFFF2D55);
  static const Color accentGreen = Color(0xFF34C759);
  
  // Padding & Radius
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 24.0;

  // Typography (Standard)
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 1.2,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: Colors.white70,
  );
}
