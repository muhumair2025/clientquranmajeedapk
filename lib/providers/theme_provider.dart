import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  double _arabicFontSize = 24.0; // Default font size
  
  // Font size constraints
  static const double _minFontSize = 16.0;
  static const double _maxFontSize = 40.0;
  static const double _fontSizeStep = 2.0;

  ThemeMode get themeMode => _themeMode;
  double get arabicFontSize => _arabicFontSize;

  bool get isDarkMode {
    return _themeMode == ThemeMode.dark;
  }

  bool get canIncreaseFontSize => _arabicFontSize < _maxFontSize;
  bool get canDecreaseFontSize => _arabicFontSize > _minFontSize;

  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }

  void toggleTheme() {
    if (_themeMode == ThemeMode.dark) {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }

  void increaseFontSize() {
    if (canIncreaseFontSize) {
      _arabicFontSize += _fontSizeStep;
      notifyListeners();
    }
  }

  void decreaseFontSize() {
    if (canDecreaseFontSize) {
      _arabicFontSize -= _fontSizeStep;
      notifyListeners();
    }
  }

  void resetFontSize() {
    _arabicFontSize = 24.0;
    notifyListeners();
  }
} 