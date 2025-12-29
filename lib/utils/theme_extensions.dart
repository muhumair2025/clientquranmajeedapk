import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

/// Extension on BuildContext to easily access theme-aware colors
/// This ensures all colors automatically update when theme preset changes
extension ThemeColorsExtension on BuildContext {
  /// Get the current theme's primary color (changes with theme preset)
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  
  /// Get the current theme's secondary/accent color
  Color get accentColor => Theme.of(this).colorScheme.secondary;
  
  /// Get the current theme's surface color
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  
  /// Get the current theme's background color
  Color get backgroundColor => Theme.of(this).scaffoldBackgroundColor;
  
  /// Get the current theme's card background color
  Color get cardColor => Theme.of(this).cardTheme.color ?? Colors.white;
  
  /// Get text color for primary background
  Color get onPrimaryColor => Theme.of(this).colorScheme.onPrimary;
  
  /// Get text color for surface background
  Color get onSurfaceColor => Theme.of(this).colorScheme.onSurface;
  
  /// Get text color for background
  Color get textColor => Theme.of(this).colorScheme.onSurface;
  
  /// Get secondary text color (lighter)
  Color get secondaryTextColor {
    final isDark = Theme.of(this).brightness == Brightness.dark;
    return isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
  }
  
  /// Get error color
  Color get errorColor => Theme.of(this).colorScheme.error;
  
  /// Check if current theme is dark mode
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
  
  /// Get theme-aware divider color
  Color get dividerColor => isDarkTheme 
      ? Colors.white.withOpacity(0.12) 
      : Colors.black.withOpacity(0.12);
  
  /// Get theme-aware shadow color
  Color get shadowColor => isDarkTheme 
      ? Colors.black.withOpacity(0.3) 
      : Colors.black.withOpacity(0.1);
}

/// Extension for common color variants
extension ColorVariants on Color {
  /// Get a lighter variant of the color
  Color lighter([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  /// Get a darker variant of the color
  Color darker([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  /// Get color with opacity
  Color withAlpha(double opacity) {
    return withOpacity(opacity);
  }
}

