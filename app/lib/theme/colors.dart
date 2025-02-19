import 'package:flutter/material.dart';

class IrisColors {
  static const Color primary = Color(0xFF0057B7);
  static const Color secondary = Color(0xFF007BFF);
  static const Color accent = Color(0xFF66A3FF);
  static const Color background = Color(0xFFFFFFFF);

  // Vibrant gradient for better visibility
  static const gradientHome = GradientSet(
    color1: Color(0xFF1976D2), // More saturated blue
    color2: Color(0xFF2196F3), // Vibrant blue
    color3: Color(0xFF42A5F5), // Bright blue
  );

  static const gradientProcessing = GradientSet(
    color1: Color(0xFF2196F3), // Bright processing blue
    color2: Color(0xFF42A5F5), // Mid processing blue
    color3: Color(0xFF90CAF9), // Light processing blue
  );

  static const gradientResults = GradientSet(
    color1: Color(0xFFE8F5E9), // Light medical green/blue
    color2: Color(0xFFC8E6C9), // Mid green/blue
    color3: Color(0xFFE8F5E9), // Back to light green/blue
  );

  static const gradientGallery = GradientSet(
    color1: Color(0xFFE3F2FD), // Light gallery blue
    color2: Color(0xFFBBDEFB), // Mid gallery blue
    color3: Color(0xFFE3F2FD), // Back to light blue
  );
}

class GradientSet {
  final Color color1;
  final Color color2;
  final Color color3;

  const GradientSet({
    required this.color1,
    required this.color2,
    required this.color3,
  });
}
