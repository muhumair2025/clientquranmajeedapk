import 'package:flutter/material.dart';

class FontManager {
  // Font size scale factors for each language
  static const Map<String, double> _fontSizeScales = {
    'ps': 1.15, // Pashto font appears smaller, increase by 15%
    'en': 1.0,  // English standard size
    'ur': 1.0,  // Urdu standard size
    'ar': 1.0,  // Arabic standard size
  };

  // Font families for each language
  static const Map<String, FontConfig> _languageFonts = {
    'ps': FontConfig(
      regular: 'Bahij Badr Light',
      bold: 'Bahij Badr Bold',
      light: 'Bahij Badr Light',
    ),
    'en': FontConfig(
      regular: 'Poppins Regular',
      bold: 'Poppins Bold',
      light: 'Poppins Regular',
    ),
    'ur': FontConfig(
      regular: 'Noto Nastaliq Regular',
      bold: 'Noto Nastaliq Bold',
      light: 'Noto Nastaliq Regular',
    ),
    'ar': FontConfig(
      regular: 'Tajawal Regular',
      bold: 'Tajawal Bold',
      light: 'Tajawal Regular',
    ),
  };

  // Quran Arabic fonts (separate from UI Arabic)
  static const Map<String, String> quranFonts = {
    'Al Qalam Quran Majeed': 'Al Qalam Quran Majeed',
    'Kitab': 'Kitab',
    'Noorehuda': 'Noorehuda',
    'Noorehira': 'Noorehira',
  };

  // Get font family for a specific language
  static String getFontFamily(String languageCode, {FontWeight weight = FontWeight.normal}) {
    final fontConfig = _languageFonts[languageCode];
    if (fontConfig == null) {
      return _languageFonts['ps']!.regular; // Default to Pashto
    }

    if (weight.index >= FontWeight.w600.index) {
      return fontConfig.bold;
    } else if (weight.index <= FontWeight.w300.index) {
      return fontConfig.light;
    } else {
      return fontConfig.regular;
    }
  }

  // Get regular font for language
  static String getRegularFont(String languageCode) {
    return _languageFonts[languageCode]?.regular ?? _languageFonts['ps']!.regular;
  }

  // Get bold font for language
  static String getBoldFont(String languageCode) {
    return _languageFonts[languageCode]?.bold ?? _languageFonts['ps']!.bold;
  }

  // Get light font for language
  static String getLightFont(String languageCode) {
    return _languageFonts[languageCode]?.light ?? _languageFonts['ps']!.light;
  }

  // Get font size scale for language
  static double getFontSizeScale(String languageCode) {
    return _fontSizeScales[languageCode] ?? 1.0;
  }

  // Get scaled font size for language
  static double getScaledFontSize(String languageCode, double baseFontSize) {
    return baseFontSize * getFontSizeScale(languageCode);
  }

  // Get text style for specific language
  static TextStyle getTextStyle(
    String languageCode, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    double? letterSpacing,
    double? wordSpacing,
  }) {
    final scaledFontSize = getScaledFontSize(languageCode, fontSize);
    return TextStyle(
      fontFamily: getFontFamily(languageCode, weight: fontWeight),
      fontSize: scaledFontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
    );
  }

  // Get heading text style for specific language
  static TextStyle getHeadingStyle(
    String languageCode, {
    double fontSize = 20,
    Color? color,
    double? height,
  }) {
    final scaledFontSize = getScaledFontSize(languageCode, fontSize);
    return TextStyle(
      fontFamily: getBoldFont(languageCode),
      fontSize: scaledFontSize,
      fontWeight: FontWeight.bold,
      color: color,
      height: height,
    );
  }

  // Get body text style for specific language
  static TextStyle getBodyStyle(
    String languageCode, {
    double fontSize = 14,
    Color? color,
    double? height,
  }) {
    final scaledFontSize = getScaledFontSize(languageCode, fontSize);
    return TextStyle(
      fontFamily: getRegularFont(languageCode),
      fontSize: scaledFontSize,
      fontWeight: FontWeight.normal,
      color: color,
      height: height,
    );
  }

  // Get caption text style for specific language
  static TextStyle getCaptionStyle(
    String languageCode, {
    double fontSize = 12,
    Color? color,
    double? height,
  }) {
    final scaledFontSize = getScaledFontSize(languageCode, fontSize);
    return TextStyle(
      fontFamily: getLightFont(languageCode),
      fontSize: scaledFontSize,
      fontWeight: FontWeight.w300,
      color: color,
      height: height,
    );
  }

  // Get Quran Arabic font (for Arabic text of Quran)
  static String getQuranFont([String fontName = 'Al Qalam Quran Majeed']) {
    return quranFonts[fontName] ?? quranFonts['Al Qalam Quran Majeed']!;
  }

  // Get Quran text style
  static TextStyle getQuranTextStyle({
    String fontName = 'Al Qalam Quran Majeed',
    double fontSize = 24,
    Color? color,
    double? height,
    double? letterSpacing,
    double? wordSpacing,
  }) {
    return TextStyle(
      fontFamily: getQuranFont(fontName),
      fontSize: fontSize,
      color: color,
      height: height ?? 1.6,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
    );
  }

  // Check if language needs RTL text direction
  static bool isRTL(String languageCode) {
    return ['ps', 'ur', 'ar'].contains(languageCode);
  }

  // Get text direction for language
  static TextDirection getTextDirection(String languageCode) {
    return isRTL(languageCode) ? TextDirection.rtl : TextDirection.ltr;
  }

  // Get text align for language (for UI elements)
  static TextAlign getTextAlign(String languageCode) {
    return isRTL(languageCode) ? TextAlign.right : TextAlign.left;
  }

  // Get default font fallbacks for each language
  static List<String> getFontFallbacks(String languageCode) {
    switch (languageCode) {
      case 'ps':
        return ['Bahij Badr Light', 'Bahij Badr', 'sans-serif'];
      case 'en':
        return ['Poppins Regular', 'Poppins', 'sans-serif'];
      case 'ur':
        return ['Noto Nastaliq Regular', 'Noto Nastaliq', 'serif'];
      case 'ar':
        return ['Tajawal Regular', 'Tajawal', 'sans-serif'];
      default:
        return ['Bahij Badr Light', 'sans-serif'];
    }
  }
}

class FontConfig {
  final String regular;
  final String bold;
  final String light;

  const FontConfig({
    required this.regular,
    required this.bold,
    required this.light,
  });
}

// Font weight extensions for convenience
extension FontWeightHelper on FontWeight {
  bool get isBold => index >= FontWeight.w600.index;
  bool get isLight => index <= FontWeight.w300.index;
  bool get isRegular => !isBold && !isLight;
} 