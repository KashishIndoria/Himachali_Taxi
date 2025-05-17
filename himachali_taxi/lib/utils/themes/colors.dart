import 'package:flutter/material.dart';

// Light Mode Colors
class LightColors {
  static const Color primary = Colors.blue;
  static const Color primaryCaptain = Colors.amber;
  static const Color secondary = Color(0xFF1565C0); // darker blue
  static const Color surface = Color(0xFFFFFFFF); // white
  static const Color background = Color(0xFFF5F5F5);
  static const Color error = Colors.red;
  static const Color subtext = Colors.grey;
  static const Color divider = Color(0xFFE0E0E0);

  // Text colors
  static const Color text = Color(0xFF000000); // black
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryCaptain = Colors.black87;
  static const Color onSecondary = Colors.white;
  static const Color onSurface = Colors.black87;
  static const Color onBackground = Colors.black87;
  static const Color onError = Colors.white;

  // Additional colors
  static const Color cardBackground = Colors.white;
  static const Color shadow = Color(0x1F000000);
  static const Color dividerLight = Color(0xFFE0E0E0);
}

// Dark Mode Colors
class DarkColors {
  static const Color primary = Color(0xFF2196F3); // Blue
  static const Color primaryCaptain = Color(0xFFFFC107); // Amber
  static const Color secondary = Color(0xFF0D47A1);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color background = Color(0xFF121212);
  static const Color error = Color(0xFFCF6679);
  static const Color subtext = Colors.grey;
  static const Color divider = Color(0xFF424242);

  // Text colors
  static const Color text = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color onPrimaryCaptain = Colors.black87;
  static const Color onSecondary = Colors.white;
  static const Color onSurface = Colors.white;
  static const Color onBackground = Colors.white;
  static const Color onError = Colors.black;

  // Additional colors
  static const Color cardBackground = Color(0xFF2D2D2D);
  static const Color shadow = Color(0x3F000000);
  static const Color dividerLight = Color(0xFF424242);
}

// Color Extensions
extension ColorSchemeExtension on ColorScheme {
  Color get cardBackground => brightness == Brightness.light
      ? LightColors.cardBackground
      : DarkColors.cardBackground;

  Color get primaryByRole =>
      brightness == Brightness.light ? LightColors.primary : DarkColors.primary;

  Color get primaryCaptain => brightness == Brightness.light
      ? LightColors.primaryCaptain
      : DarkColors.primaryCaptain;
}
