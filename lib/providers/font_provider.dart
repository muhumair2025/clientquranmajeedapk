import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/app_localizations_extension.dart';

class FontProvider with ChangeNotifier {
  String _selectedArabicFont = 'Al Qalam Quran Majeed';
  FontSize _selectedFontSize = FontSize.medium; // Default font size
  
  String get selectedArabicFont => _selectedArabicFont;
  FontSize get selectedFontSize => _selectedFontSize;
  double get arabicFontSize => _selectedFontSize.size;
  
  // List of available Arabic fonts
  final List<FontOption> availableFonts = [
    FontOption(
      name: 'Al Qalam Quran Majeed',
      displayName: 'القلم قرآن مجید',
      family: 'Al Qalam Quran Majeed',
    ),
    FontOption(
      name: 'Kitab',
      displayName: 'کتاب',
      family: 'Kitab',
    ),
    FontOption(
      name: 'Noorehuda',
      displayName: 'نور ہدیٰ',
      family: 'Noorehuda',
    ),
  ];
  
  FontProvider() {
    _loadFontPreferences();
  }
  
  Future<void> _loadFontPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load font family
      final savedFont = prefs.getString('arabic_font');
      if (savedFont != null && availableFonts.any((font) => font.family == savedFont)) {
        _selectedArabicFont = savedFont;
      }
      
      // Load font size preset
      final savedFontSizeIndex = prefs.getInt('arabic_font_size_preset');
      if (savedFontSizeIndex != null && savedFontSizeIndex >= 0 && savedFontSizeIndex < FontSize.values.length) {
        _selectedFontSize = FontSize.values[savedFontSizeIndex];
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading font preferences: $e');
    }
  }
  
  Future<void> setArabicFont(String fontFamily) async {
    if (_selectedArabicFont != fontFamily) {
      _selectedArabicFont = fontFamily;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('arabic_font', fontFamily);
      } catch (e) {
        debugPrint('Error saving font preference: $e');
      }
    }
  }
  
  Future<void> setArabicFontSize(FontSize fontSize) async {
    if (_selectedFontSize != fontSize) {
      _selectedFontSize = fontSize;
      notifyListeners();
      
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('arabic_font_size_preset', fontSize.index);
      } catch (e) {
        debugPrint('Error saving font size preference: $e');
      }
    }
  }
  
  FontOption get selectedFontOption {
    return availableFonts.firstWhere(
      (font) => font.family == _selectedArabicFont,
      orElse: () => availableFonts.first,
    );
  }
}

class FontOption {
  final String name;
  final String displayName;
  final String family;
  
  FontOption({
    required this.name,
    required this.displayName,
    required this.family,
  });
}

enum FontSize {
  small(20.0),
  medium(24.0),
  large(28.0),
  xl(38.0);
  
  const FontSize(this.size);
  
  final double size;
  
  // Check if this font size needs flexible layout
  bool get needsFlexibleLayout => this == FontSize.xl;
  
  // Get localized display name for font size
  String getDisplayName(BuildContext context) {
    switch (this) {
      case FontSize.small:
        return context.l.fontSizeSmall;
      case FontSize.medium:
        return context.l.fontSizeMedium;
      case FontSize.large:
        return context.l.fontSizeLarge;
      case FontSize.xl:
        return context.l.fontSizeXLarge;
    }
  }
} 