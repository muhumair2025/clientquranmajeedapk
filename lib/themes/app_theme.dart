import 'package:flutter/material.dart';
import '../utils/font_manager.dart';
import '../providers/theme_provider.dart';

class AppTheme {
  // ==================== CLASSIC GREEN THEME ====================
  static const Color primaryGreen = Color(0xFF006653);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF004D40);
  static const Color accentGreen = Color(0xFF80CBC4);
  static const Color primaryGold = Color(0xFFD4AF37);
  
  // ==================== ROYAL BLUE THEME ====================
  static const Color primaryBlue = Color(0xFF1A237E);      // Deep indigo blue
  static const Color lightBlue = Color(0xFF3949AB);        // Lighter blue
  static const Color darkBlue = Color(0xFF0D1642);         // Very dark blue
  static const Color accentBlue = Color(0xFF7986CB);       // Soft blue
  static const Color goldAccent = Color(0xFFFFD700);       // Rich gold
  
  // ==================== DESERT GOLD THEME ====================
  static const Color primaryBeige = Color(0xFF8B6914);     // Rich golden brown
  static const Color lightBeige = Color(0xFFD4A574);       // Light sand
  static const Color darkBeige = Color(0xFF5C4A1A);        // Dark brown
  static const Color accentBeige = Color(0xFFF5DEB3);      // Wheat
  static const Color bronzeAccent = Color(0xFFCD7F32);     // Bronze
  
  // ==================== NIGHT PURPLE THEME ====================
  static const Color primaryPurple = Color(0xFF4A148C);    // Deep purple
  static const Color lightPurple = Color(0xFF7B1FA2);      // Medium purple
  static const Color darkPurple = Color(0xFF2C0952);       // Very dark purple
  static const Color accentPurple = Color(0xFFBA68C8);     // Light purple
  static const Color silverAccent = Color(0xFFC0C0C0);     // Silver
  
  // ==================== COMMON COLORS ====================
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
  
  /// Get primary color for a theme preset
  static Color getPrimaryColor(ThemePreset preset) {
    switch (preset) {
      case ThemePreset.classicGreen:
        return primaryGreen;
      case ThemePreset.royalBlue:
        return primaryBlue;
      case ThemePreset.desertGold:
        return primaryBeige;
      case ThemePreset.nightPurple:
        return primaryPurple;
    }
  }
  
  /// Get accent color for a theme preset
  static Color getAccentColor(ThemePreset preset) {
    switch (preset) {
      case ThemePreset.classicGreen:
        return accentGreen;
      case ThemePreset.royalBlue:
        return accentBlue;
      case ThemePreset.desertGold:
        return accentBeige;
      case ThemePreset.nightPurple:
        return accentPurple;
    }
  }
  
  /// Get dark variant for a theme preset
  static Color getDarkColor(ThemePreset preset) {
    switch (preset) {
      case ThemePreset.classicGreen:
        return darkGreen;
      case ThemePreset.royalBlue:
        return darkBlue;
      case ThemePreset.desertGold:
        return darkBeige;
      case ThemePreset.nightPurple:
        return darkPurple;
    }
  }
  
  /// Get light variant for a theme preset
  static Color getLightColor(ThemePreset preset) {
    switch (preset) {
      case ThemePreset.classicGreen:
        return lightGreen;
      case ThemePreset.royalBlue:
        return lightBlue;
      case ThemePreset.desertGold:
        return lightBeige;
      case ThemePreset.nightPurple:
        return lightPurple;
    }
  }

  // Method to get language-specific light theme with preset
  static ThemeData getLightTheme(String languageCode, [ThemePreset preset = ThemePreset.classicGreen]) {
    String fontFamily = FontManager.getRegularFont(languageCode);
    double fontScale = FontManager.getFontSizeScale(languageCode);
    return _buildLightTheme(fontFamily, languageCode, fontScale, preset);
  }

  // Method to get language-specific dark theme with preset
  static ThemeData getDarkTheme(String languageCode, [ThemePreset preset = ThemePreset.classicGreen]) {
    String fontFamily = FontManager.getRegularFont(languageCode);
    double fontScale = FontManager.getFontSizeScale(languageCode);
    return _buildDarkTheme(fontFamily, languageCode, fontScale, preset);
  }

  // Light Theme (default - keeping for backward compatibility)
  static ThemeData lightTheme = _buildLightTheme('Bahij Badr Light', 'ps', 1.15, ThemePreset.classicGreen);

  // Dark Theme (default - keeping for backward compatibility)
  static ThemeData darkTheme = _buildDarkTheme('Bahij Badr Light', 'ps', 1.15, ThemePreset.classicGreen);

  // Private method to build light theme with specific font and preset
  static ThemeData _buildLightTheme(String fontFamily, String languageCode, double fontScale, ThemePreset preset) {
    final primaryColor = getPrimaryColor(preset);
    final accentColor = getAccentColor(preset);
    
    return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: lightBackground,
    fontFamily: fontFamily,
    
    colorScheme: ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
      surface: lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightTextPrimary,
    ),
    
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
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
        backgroundColor: primaryColor,
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
    
    drawerTheme: DrawerThemeData(
      backgroundColor: primaryColor,
    ),
  );
  }

  // Private method to build dark theme with specific font and preset
  static ThemeData _buildDarkTheme(String fontFamily, String languageCode, double fontScale, ThemePreset preset) {
    final primaryColor = getPrimaryColor(preset);
    final accentColor = getAccentColor(preset);
    final darkColor = getDarkColor(preset);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackground,
      fontFamily: fontFamily,
      
      colorScheme: ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkTextPrimary,
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
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
          backgroundColor: primaryColor,
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
      
      drawerTheme: DrawerThemeData(
        backgroundColor: darkColor,
      ),
    );
  }
} 