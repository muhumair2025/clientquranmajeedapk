import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing ayah modal display settings
class AyahModalSettingsProvider with ChangeNotifier {
  // Visibility settings
  bool _showArabicText = true;
  bool _showTranslation = true;
  
  // Font settings
  String _arabicFont = 'Noorehuda';
  String _pashtoFont = 'Bahij Badr Light';
  
  // Font size settings
  double _arabicFontSize = 22.0;
  double _translationFontSize = 14.0;
  
  // Keys for SharedPreferences
  static const String _keyShowArabic = 'ayah_modal_show_arabic';
  static const String _keyShowTranslation = 'ayah_modal_show_translation';
  static const String _keyArabicFont = 'ayah_modal_arabic_font';
  static const String _keyPashtoFont = 'ayah_modal_pashto_font';
  static const String _keyArabicFontSize = 'ayah_modal_arabic_font_size';
  static const String _keyTranslationFontSize = 'ayah_modal_translation_font_size';
  
  // Getters
  bool get showArabicText => _showArabicText;
  bool get showTranslation => _showTranslation;
  String get arabicFont => _arabicFont;
  String get pashtoFont => _pashtoFont;
  double get arabicFontSize => _arabicFontSize;
  double get translationFontSize => _translationFontSize;
  
  // Available Arabic fonts for ayah modal
  static const List<String> availableArabicFonts = [
    'Noorehuda',
    'Noorehira',
    'Al Qalam Quran Majeed',
    'Kitab',
  ];
  
  // Available Pashto fonts for translation
  static const List<String> availablePashtoFonts = [
    'Bahij Badr Light',
    'Bahij Badr Bold',
    'Poppins Regular',
  ];
  
  AyahModalSettingsProvider() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _showArabicText = prefs.getBool(_keyShowArabic) ?? true;
      _showTranslation = prefs.getBool(_keyShowTranslation) ?? true;
      _arabicFont = prefs.getString(_keyArabicFont) ?? 'Noorehuda';
      _pashtoFont = prefs.getString(_keyPashtoFont) ?? 'Bahij Badr Light';
      _arabicFontSize = prefs.getDouble(_keyArabicFontSize) ?? 22.0;
      _translationFontSize = prefs.getDouble(_keyTranslationFontSize) ?? 14.0;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading ayah modal settings: $e');
    }
  }
  
  Future<void> setShowArabicText(bool value) async {
    if (_showArabicText != value) {
      _showArabicText = value;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyShowArabic, value);
      } catch (e) {
        debugPrint('Error saving showArabicText setting: $e');
      }
    }
  }
  
  Future<void> setShowTranslation(bool value) async {
    if (_showTranslation != value) {
      _showTranslation = value;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_keyShowTranslation, value);
      } catch (e) {
        debugPrint('Error saving showTranslation setting: $e');
      }
    }
  }
  
  Future<void> setArabicFont(String font) async {
    if (_arabicFont != font && availableArabicFonts.contains(font)) {
      _arabicFont = font;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyArabicFont, font);
      } catch (e) {
        debugPrint('Error saving arabicFont setting: $e');
      }
    }
  }
  
  Future<void> setPashtoFont(String font) async {
    if (_pashtoFont != font && availablePashtoFonts.contains(font)) {
      _pashtoFont = font;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyPashtoFont, font);
      } catch (e) {
        debugPrint('Error saving pashtoFont setting: $e');
      }
    }
  }
  
  Future<void> setArabicFontSize(double size) async {
    if (_arabicFontSize != size && size >= 12.0 && size <= 40.0) {
      _arabicFontSize = size;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_keyArabicFontSize, size);
      } catch (e) {
        debugPrint('Error saving arabicFontSize setting: $e');
      }
    }
  }
  
  Future<void> setTranslationFontSize(double size) async {
    if (_translationFontSize != size && size >= 10.0 && size <= 24.0) {
      _translationFontSize = size;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_keyTranslationFontSize, size);
      } catch (e) {
        debugPrint('Error saving translationFontSize setting: $e');
      }
    }
  }
}

