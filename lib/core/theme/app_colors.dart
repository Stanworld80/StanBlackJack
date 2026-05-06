import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0F0F0F);
  static const Color tableGreen = Color(0xFF0A4D2E);
  static const Color tableLightGreen = Color(0xFF14633D);
  static const Color tableBorder = Color(0xFF052D1B);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldLight = Color(0xFFFFECB3);
  static const Color accent = Color(0xFFE91E63);
  static const Color cardBackground = Colors.white;
  
  // Chips
  static const Color chipWhite = Color(0xFFFFFFFF);
  static const Color chipRed = Color(0xFFB71C1C);
  static const Color chipBlue = Color(0xFF0D47A1);
  static const Color chipGreen = Color(0xFF1B5E20);
  static const Color chipBlack = Color(0xFF212121);
  
  static const LinearGradient tableGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0D5E38),
      Color(0xFF0A4D2E),
      Color(0xFF073C24),
    ],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFD700),
      Color(0xFFFFA000),
      Color(0xFFFFD700),
    ],
  );
}
