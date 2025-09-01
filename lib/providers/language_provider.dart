import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../localization/app_localizations.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'app_language';
  static const String _firstLaunchKey = 'is_first_launch_completed'; // Changed key name for clarity
  
  // Supported languages
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English (United States) - Default for first launch
    Locale('ps', 'AF'), // Pashto (Afghanistan)
    Locale('ur', 'PK'), // Urdu (Pakistan)
    Locale('ar', 'SA'), // Arabic (Saudi Arabia)
  ];
  
  Locale _currentLocale = supportedLocales[0]; // Default to English for first launch
  AppLocalizations? _localizations;
  bool _isFirstLaunch = true;
  bool _isLoaded = false; // Track if preferences have been loaded
  
  // Getters
  Locale get currentLocale => _currentLocale;
  AppLocalizations? get localizations => _localizations;
  String get currentLanguage => _currentLocale.languageCode;
  bool get isPashto => _currentLocale.languageCode == 'ps';
  bool get isEnglish => _currentLocale.languageCode == 'en';
  bool get isUrdu => _currentLocale.languageCode == 'ur';
  bool get isArabic => _currentLocale.languageCode == 'ar';
  bool get isFirstLaunch => _isFirstLaunch;
  bool get isLoaded => _isLoaded; // Public getter to check if loading is complete
  
  // Get text direction based on current language
  TextDirection get textDirection {
    switch (_currentLocale.languageCode) {
      case 'ar':
      case 'ps':
      case 'ur':
        return TextDirection.rtl;
      case 'en':
      default:
        return TextDirection.ltr;
    }
  }
  
  LanguageProvider() {
    _loadSavedLanguage();
  }
  
  // Initialize localizations
  void setLocalizations(AppLocalizations localizations) {
    _localizations = localizations;
  }
  
  // Load saved language preference and check first launch
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if first launch has been completed
      // If the key doesn't exist, it's the first launch
      final hasCompletedFirstLaunch = prefs.getBool(_firstLaunchKey) ?? false;
      _isFirstLaunch = !hasCompletedFirstLaunch;
      
      debugPrint('First launch status: $_isFirstLaunch');
      
      final savedLanguageCode = prefs.getString(_languageKey);
      
      if (savedLanguageCode != null) {
        final savedLocale = supportedLocales.firstWhere(
          (locale) => locale.languageCode == savedLanguageCode,
          orElse: () => supportedLocales[0],
        );
        _currentLocale = savedLocale;
      }
      
      // Mark as loaded
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved language: $e');
      // Even on error, mark as loaded to prevent infinite waiting
      _isLoaded = true;
      notifyListeners();
    }
  }
  
  // Mark first launch as completed and save language choice
  Future<void> completeFirstLaunch(Locale selectedLocale) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save that first launch has been completed
      await prefs.setBool(_firstLaunchKey, true);
      
      // Save the selected language
      await prefs.setString(_languageKey, selectedLocale.languageCode);
      
      // Ensure the preferences are written to disk
      await prefs.reload();
      
      _isFirstLaunch = false;
      _currentLocale = selectedLocale;
      
      debugPrint('First launch completed. Language set to: ${selectedLocale.languageCode}');
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error completing first launch: $e');
    }
  }
  
  // Change language
  Future<void> changeLanguage(Locale newLocale) async {
    if (!supportedLocales.contains(newLocale)) {
      debugPrint('Unsupported locale: $newLocale');
      return;
    }
    
    if (_currentLocale == newLocale) return;
    
    try {
      _currentLocale = newLocale;
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, newLocale.languageCode);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error changing language: $e');
    }
  }
  
  // Toggle between Pashto and English
  Future<void> toggleLanguage() async {
    final newLocale = isPashto ? const Locale('en', 'US') : const Locale('ps', 'AF');
    await changeLanguage(newLocale);
  }
  
  // Get language name for display
  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'ps':
        return 'پښتو';
      case 'en':
        return 'English';
      case 'ur':
        return 'اردو';
      case 'ar':
        return 'العربية';
      default:
        return locale.languageCode;
    }
  }
  
  // Get current language name
  String get currentLanguageName => getLanguageName(_currentLocale);
  
  // Get language flag emoji
  String getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'ps':
        return '🇦🇫';
      case 'en':
        return '🇺🇸';
      case 'ur':
        return '🇵🇰';
      case 'ar':
        return '🇸🇦';
      default:
        return '🌐';
    }
  }
  
  // Get language description in English for first launch
  String getLanguageDescription(String languageCode) {
    switch (languageCode) {
      case 'ps':
        return 'Pashto';
      case 'en':
        return 'English';
      case 'ur':
        return 'Urdu';
      case 'ar':
        return 'Arabic';
      default:
        return languageCode;
    }
  }
} 