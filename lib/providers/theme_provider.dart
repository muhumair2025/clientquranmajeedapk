import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Preset Options
enum ThemePreset {
  classicGreen,  // Traditional Islamic green
  royalBlue,     // Deep blue with gold accents (Ottoman/Persian)
  desertGold,    // Warm gold/beige tones (Middle Eastern)
  nightPurple,   // Deep purple with silver accents (Night sky)
}

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  ThemePreset _themePreset = ThemePreset.classicGreen;
  double _arabicFontSize = 24.0; // Default font size
  
  // Font size constraints
  static const double _minFontSize = 16.0;
  static const double _maxFontSize = 40.0;
  static const double _fontSizeStep = 2.0;
  
  // SharedPreferences keys
  static const String _themeModeKey = 'theme_mode';
  static const String _themePresetKey = 'theme_preset';
  static const String _arabicFontSizeKey = 'arabic_font_size';

  ThemeMode get themeMode => _themeMode;
  ThemePreset get themePreset => _themePreset;
  double get arabicFontSize => _arabicFontSize;

  bool get isDarkMode {
    return _themeMode == ThemeMode.dark;
  }

  bool get canIncreaseFontSize => _arabicFontSize < _maxFontSize;
  bool get canDecreaseFontSize => _arabicFontSize > _minFontSize;

  /// Initialize theme from saved preferences
  Future<void> loadThemePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme mode
      final themeModeIndex = prefs.getInt(_themeModeKey);
      if (themeModeIndex != null) {
        _themeMode = ThemeMode.values[themeModeIndex];
      }
      
      // Load theme preset
      final themePresetIndex = prefs.getInt(_themePresetKey);
      if (themePresetIndex != null && themePresetIndex < ThemePreset.values.length) {
        _themePreset = ThemePreset.values[themePresetIndex];
      }
      
      // Load font size
      final fontSize = prefs.getDouble(_arabicFontSizeKey);
      if (fontSize != null) {
        _arabicFontSize = fontSize;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
    }
  }

  /// Save theme mode
  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, _themeMode.index);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  /// Save theme preset
  Future<void> _saveThemePreset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themePresetKey, _themePreset.index);
    } catch (e) {
      debugPrint('Error saving theme preset: $e');
    }
  }

  /// Save font size
  Future<void> _saveFontSize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_arabicFontSizeKey, _arabicFontSize);
    } catch (e) {
      debugPrint('Error saving font size: $e');
    }
  }

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    _saveThemeMode();
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    _saveThemeMode();
    notifyListeners();
  }

  /// Change theme preset
  void setThemePreset(ThemePreset preset) {
    _themePreset = preset;
    _saveThemePreset();
    notifyListeners();
  }

  void increaseFontSize() {
    if (canIncreaseFontSize) {
      _arabicFontSize += _fontSizeStep;
      _saveFontSize();
      notifyListeners();
    }
  }

  void decreaseFontSize() {
    if (canDecreaseFontSize) {
      _arabicFontSize -= _fontSizeStep;
      _saveFontSize();
      notifyListeners();
    }
  }

  void resetFontSize() {
    _arabicFontSize = 24.0;
    _saveFontSize();
    notifyListeners();
  }
  
  /// Get theme preset name
  String getThemePresetName() {
    switch (_themePreset) {
      case ThemePreset.classicGreen:
        return 'Classic Green';
      case ThemePreset.royalBlue:
        return 'Royal Blue';
      case ThemePreset.desertGold:
        return 'Desert Gold';
      case ThemePreset.nightPurple:
        return 'Night Purple';
    }
  }
} 