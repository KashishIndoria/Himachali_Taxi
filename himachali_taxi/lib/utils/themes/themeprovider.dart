import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'colors.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false;
  bool _isLoading = false;
  static const String _themeKey = 'theme_mode';

  bool get isDarkMode => _isDarkMode;
  bool get isLoading => _isLoading;

  ThemeData get darkTheme => _darkTheme;
  ThemeData get lightTheme => _lightTheme;
  ThemeData get themeData => _isDarkMode ? _darkTheme : _lightTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme: $e');
    }
  }

  Future<void> toggleTheme() async {
    try {
      _isLoading = true;

      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = !_isDarkMode;
      await prefs.setBool(_themeKey, _isDarkMode);
    } catch (e) {
      _isDarkMode = !_isDarkMode; // Revert on error
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: LightColors.primary,
    scaffoldBackgroundColor: LightColors.background,
    colorScheme: ColorScheme.light(
      primary: LightColors.primary,
      secondary: LightColors.secondary,
      surface: LightColors.surface,
      background: LightColors.background,
      error: LightColors.error,
      onPrimary: LightColors.onPrimary,
      onSecondary: LightColors.onSecondary,
      onSurface: LightColors.onSurface,
      onBackground: LightColors.onBackground,
      onError: LightColors.onError,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: LightColors.text),
      displayMedium: TextStyle(color: LightColors.text),
      displaySmall: TextStyle(color: LightColors.text),
      headlineLarge: TextStyle(color: LightColors.text),
      headlineMedium: TextStyle(color: LightColors.text),
      headlineSmall: TextStyle(color: LightColors.text),
      titleLarge: TextStyle(color: LightColors.text),
      titleMedium: TextStyle(color: LightColors.text),
      titleSmall: TextStyle(color: LightColors.text),
      bodyLarge: TextStyle(color: LightColors.text),
      bodyMedium: TextStyle(color: LightColors.text),
      bodySmall: TextStyle(color: LightColors.text),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: LightColors.primary,
      foregroundColor: LightColors.onPrimary,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: LightColors.surface,
      elevation: 2,
    ),
    iconTheme: IconThemeData(
      color: LightColors.primary,
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: LightColors.primary,
      textTheme: ButtonTextTheme.primary,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: DarkColors.primary,
    scaffoldBackgroundColor: DarkColors.background,
    colorScheme: ColorScheme.dark(
      primary: DarkColors.primary,
      secondary: DarkColors.secondary,
      surface: DarkColors.surface,
      background: DarkColors.background,
      error: DarkColors.error,
      onPrimary: DarkColors.onPrimary,
      onSecondary: DarkColors.onSecondary,
      onSurface: DarkColors.onSurface,
      onBackground: DarkColors.onBackground,
      onError: DarkColors.onError,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(color: DarkColors.text),
      displayMedium: TextStyle(color: DarkColors.text),
      displaySmall: TextStyle(color: DarkColors.text),
      headlineLarge: TextStyle(color: DarkColors.text),
      headlineMedium: TextStyle(color: DarkColors.text),
      headlineSmall: TextStyle(color: DarkColors.text),
      titleLarge: TextStyle(color: DarkColors.text),
      titleMedium: TextStyle(color: DarkColors.text),
      titleSmall: TextStyle(color: DarkColors.text),
      bodyLarge: TextStyle(color: DarkColors.text),
      bodyMedium: TextStyle(color: DarkColors.text),
      bodySmall: TextStyle(color: DarkColors.text),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: DarkColors.primary,
      foregroundColor: DarkColors.onPrimary,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: DarkColors.surface,
      elevation: 2,
    ),
    iconTheme: IconThemeData(
      color: DarkColors.primary,
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: DarkColors.primary,
      textTheme: ButtonTextTheme.primary,
    ),
  );
}
