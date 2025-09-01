import 'package:flutter/material.dart';
import 'app_localizations.dart';
import '../utils/font_manager.dart';

extension LocalizationExtension on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this)!;
  
  // Convenient getter for localized strings
  AppLocalizations get localizations => AppLocalizations.of(this)!;
  
  // Check if current language is RTL
  bool get isRTL {
    final locale = Localizations.localeOf(this);
    return ['ps', 'ur', 'ar'].contains(locale.languageCode); // Pashto, Urdu, and Arabic are RTL
  }
  
  // Get text direction for current language
  TextDirection get textDirection {
    return isRTL ? TextDirection.rtl : TextDirection.ltr;
  }
  
  // Get current language code
  String get currentLanguage {
    return Localizations.localeOf(this).languageCode;
  }
  
  // Check if current language is Pashto
  bool get isPashto => currentLanguage == 'ps';
  
  // Check if current language is English
  bool get isEnglish => currentLanguage == 'en';
  
  // Check if current language is Urdu
  bool get isUrdu => currentLanguage == 'ur';
  
  // Check if current language is Arabic
  bool get isArabic => currentLanguage == 'ar';
  
  // Font helper methods using FontManager
  String get fontFamily => FontManager.getRegularFont(currentLanguage);
  String get boldFontFamily => FontManager.getBoldFont(currentLanguage);
  String get lightFontFamily => FontManager.getLightFont(currentLanguage);
  
  // Text style helpers for current language
  TextStyle textStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    double? letterSpacing,
    double? wordSpacing,
  }) => FontManager.getTextStyle(
    currentLanguage,
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    wordSpacing: wordSpacing,
  );
  
  TextStyle get headingStyle => FontManager.getHeadingStyle(currentLanguage);
  TextStyle get bodyStyle => FontManager.getBodyStyle(currentLanguage);
  TextStyle get captionStyle => FontManager.getCaptionStyle(currentLanguage);
  
  // Custom text styles with sizes
  TextStyle headingStyle1({Color? color}) => FontManager.getHeadingStyle(
    currentLanguage,
    fontSize: 24,
    color: color,
  );
  
  TextStyle headingStyle2({Color? color}) => FontManager.getHeadingStyle(
    currentLanguage,
    fontSize: 20,
    color: color,
  );
  
  TextStyle headingStyle3({Color? color}) => FontManager.getHeadingStyle(
    currentLanguage,
    fontSize: 18,
    color: color,
  );
  
  TextStyle bodyStyle1({Color? color}) => FontManager.getBodyStyle(
    currentLanguage,
    fontSize: 16,
    color: color,
  );
  
  TextStyle bodyStyle2({Color? color}) => FontManager.getBodyStyle(
    currentLanguage,
    fontSize: 14,
    color: color,
  );
  
  TextStyle captionStyle1({Color? color}) => FontManager.getCaptionStyle(
    currentLanguage,
    fontSize: 12,
    color: color,
  );
} 