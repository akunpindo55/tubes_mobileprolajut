import 'package:flutter/material.dart';

class AppColors {
  // Primaries (Pastels)
  static const Color softPeach = Color(0xFFFDBCB4);
  static const Color babyBlue = Color(0xFFADD8E6);
  static const Color mint = Color(0xFF98FF98);
  static const Color lilac = Color(0xFFE6E6FA);

  // Backgrounds & Surfaces
  static const Color background = Color(0xFFF9FAFB); // light background
  static const Color cardSurface = Colors.white;
  static const Color border = Color(0x26000000); // 15% opacity black for chunky borders

  // Gradients
  static const LinearGradient peachToLilac = LinearGradient(
    colors: [softPeach, lilac],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueToMint = LinearGradient(
    colors: [babyBlue, mint],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient lilacToBlue = LinearGradient(
    colors: [lilac, babyBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Typography
  static const Color textDark = Color(0xFF1F2937); // off-black
  static const Color textMuted = Color(0xFF6B7280);
}
