import 'package:flutter/material.dart';
import '../utils/font_manager.dart';

class AppTheme {
  // Color Palette
  static const Color primaryGreen = Color(0xFF006653);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF004D40);
  static const Color accentGreen = Color(0xFF80CBC4);
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color lightGray = Color(0xFFF5F5F5);
  
  // Light Theme Colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  
  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCardBackground = Color(0xFF2D2D2D);

  // Text Colors
  static const Color lightTextPrimary = Color(0xFF212121);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // Method to get language-specific light theme
  static ThemeData getLightTheme(String languageCode) {
    String fontFamily = FontManager.getRegularFont(languageCode);
    double fontScale = FontManager.getFontSizeScale(languageCode);
    return _buildLightTheme(fontFamily, languageCode, fontScale);
  }

  // Method to get language-specific dark theme
  static ThemeData getDarkTheme(String languageCode) {
    String fontFamily = FontManager.getRegularFont(languageCode);
    double fontScale = FontManager.getFontSizeScale(languageCode);
    return _buildDarkTheme(fontFamily, languageCode, fontScale);
  }

  // Light Theme (default - keeping for backward compatibility)
  static ThemeData lightTheme = _buildLightTheme('Bahij Badr Light', 'ps', 1.15);

  // Dark Theme (default - keeping for backward compatibility)
  static ThemeData darkTheme = _buildDarkTheme('Bahij Badr Light', 'ps', 1.15);

  // Private method to build light theme with specific font
  static ThemeData _buildLightTheme(String fontFamily, String languageCode, double fontScale) {
    return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: lightBackground,
    fontFamily: fontFamily,
    
    colorScheme: const ColorScheme.light(
      primary: primaryGreen,
      secondary: accentGreen,
      surface: lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextPrimary,
    ),
    
    appBarTheme: AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20 * fontScale,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        fontFamily: fontFamily,
      ),
    ),
    
    cardTheme: CardThemeData(
      color: lightCardBackground,
      elevation: 0,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 24 * fontScale,
        fontWeight: FontWeight.bold,
        color: lightTextPrimary,
        fontFamily: FontManager.getBoldFont(languageCode),
      ),
      headlineMedium: TextStyle(
        fontSize: 20 * fontScale,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
        fontFamily: fontFamily,
      ),
      bodyLarge: TextStyle(
        fontSize: 16 * fontScale,
        color: lightTextPrimary,
        fontFamily: fontFamily,
      ),
      bodyMedium: TextStyle(
        fontSize: 14 * fontScale,
        color: lightTextSecondary,
        fontFamily: fontFamily,
      ),
      labelLarge: TextStyle(
        fontSize: 14 * fontScale,
        fontWeight: FontWeight.w600,
        color: lightTextPrimary,
        fontFamily: fontFamily,
      ),
    ),
    
    drawerTheme: const DrawerThemeData(
      backgroundColor: primaryGreen,
    ),
  );
  }

  // Private method to build dark theme with specific font
  static ThemeData _buildDarkTheme(String fontFamily, String languageCode, double fontScale) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryGreen,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: fontFamily,
      
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        secondary: accentGreen,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20 * fontScale,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontFamily: fontFamily,
        ),
      ),
      
      cardTheme: CardThemeData(
        color: darkCardBackground,
        elevation: 0,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 24 * fontScale,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
          fontFamily: FontManager.getBoldFont(languageCode),
        ),
        headlineMedium: TextStyle(
          fontSize: 20 * fontScale,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          fontFamily: fontFamily,
        ),
        bodyLarge: TextStyle(
          fontSize: 16 * fontScale,
          color: darkTextPrimary,
          fontFamily: fontFamily,
        ),
        bodyMedium: TextStyle(
          fontSize: 14 * fontScale,
          color: darkTextSecondary,
          fontFamily: fontFamily,
        ),
        labelLarge: TextStyle(
          fontSize: 14 * fontScale,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
          fontFamily: fontFamily,
        ),
      ),
      
      drawerTheme: const DrawerThemeData(
        backgroundColor: darkGreen,
      ),
    );
  }
} 