import 'package:flutter/material.dart';

class FontManager {
  // Font size scale factors for each language
  static const Map<String, double> _fontSizeScales = {
    'ps': 1.15, // Pashto font appears smaller, increase by 15%
    'en': 1.0,  // English standard size
    'ur': 1.0,  // Urdu standard size
    'ar': 1.0,  // Arabic standard size
  };

  // English fonts (used as fallback for numbers and English text)
  static const String _englishRegular = 'Poppins Regular';
  static const String _englishBold = 'Poppins Bold';

  // Font families for each language
  static const Map<String, FontConfig> _languageFonts = {
    'ps': FontConfig(
      regular: 'Bahij Badr Light',
      bold: 'Bahij Badr Bold',
      light: 'Bahij Badr Light',
      // Fallback to English font for numbers and English text
      fallbacks: ['Poppins Regular', 'Poppins Bold', 'sans-serif'],
    ),
    'en': FontConfig(
      regular: 'Poppins Regular',
      bold: 'Poppins Bold',
      light: 'Poppins Regular',
      fallbacks: ['sans-serif'],
    ),
    'ur': FontConfig(
      regular: 'Noto Nastaliq Regular',
      bold: 'Noto Nastaliq Bold',
      light: 'Noto Nastaliq Regular',
      // Fallback to English font for numbers and English text
      fallbacks: ['Poppins Regular', 'Poppins Bold', 'serif'],
    ),
    'ar': FontConfig(
      regular: 'Tajawal Regular',
      bold: 'Tajawal Bold',
      light: 'Tajawal Regular',
      // Fallback to English font for numbers and English text
      fallbacks: ['Poppins Regular', 'Poppins Bold', 'sans-serif'],
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

  // Get font fallbacks for a language (English font for numbers/English text)
  static List<String> getFontFallbacksForLanguage(String languageCode) {
    return _languageFonts[languageCode]?.fallbacks ?? ['Poppins Regular', 'sans-serif'];
  }

  // Get text style for specific language
  // Uses language font for native script, falls back to English for numbers/English
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
      fontFamilyFallback: getFontFallbacksForLanguage(languageCode),
      fontSize: scaledFontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
    );
  }

  // Get heading text style for specific language
  // Uses language font for native script, falls back to English for numbers/English
  static TextStyle getHeadingStyle(
    String languageCode, {
    double fontSize = 20,
    Color? color,
    double? height,
  }) {
    final scaledFontSize = getScaledFontSize(languageCode, fontSize);
    return TextStyle(
      fontFamily: getBoldFont(languageCode),
      fontFamilyFallback: getFontFallbacksForLanguage(languageCode),
      fontSize: scaledFontSize,
      fontWeight: FontWeight.bold,
      color: color,
      height: height,
    );
  }

  // Get body text style for specific language
  // Uses language font for native script, falls back to English for numbers/English
  static TextStyle getBodyStyle(
    String languageCode, {
    double fontSize = 14,
    Color? color,
    double? height,
  }) {
    final scaledFontSize = getScaledFontSize(languageCode, fontSize);
    return TextStyle(
      fontFamily: getRegularFont(languageCode),
      fontFamilyFallback: getFontFallbacksForLanguage(languageCode),
      fontSize: scaledFontSize,
      fontWeight: FontWeight.normal,
      color: color,
      height: height,
    );
  }

  // Get caption text style for specific language
  // Uses language font for native script, falls back to English for numbers/English
  static TextStyle getCaptionStyle(
    String languageCode, {
    double fontSize = 12,
    Color? color,
    double? height,
  }) {
    final scaledFontSize = getScaledFontSize(languageCode, fontSize);
    return TextStyle(
      fontFamily: getLightFont(languageCode),
      fontFamilyFallback: getFontFallbacksForLanguage(languageCode),
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

  // Get default font fallbacks for each language (deprecated - use getFontFallbacksForLanguage)
  static List<String> getFontFallbacks(String languageCode) {
    return getFontFallbacksForLanguage(languageCode);
  }

  // Get a pure English text style (for content that should always be in English font)
  // Use this for labels, numbers, time stamps, etc. that should not use RTL fonts
  static TextStyle getEnglishTextStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    final fontFamily = fontWeight.index >= FontWeight.w600.index 
        ? _englishBold 
        : _englishRegular;
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // Check if a character is English letter or number
  static bool isEnglishOrNumber(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    // A-Z: 65-90, a-z: 97-122, 0-9: 48-57
    // Also include common punctuation and symbols
    return (code >= 48 && code <= 57) ||   // 0-9
           (code >= 65 && code <= 90) ||   // A-Z
           (code >= 97 && code <= 122) ||  // a-z
           (code == 32) ||                  // space
           (code >= 33 && code <= 47) ||   // ! " # $ % & ' ( ) * + , - . /
           (code >= 58 && code <= 64) ||   // : ; < = > ? @
           (code >= 91 && code <= 96) ||   // [ \ ] ^ _ `
           (code >= 123 && code <= 126);   // { | } ~
  }

  // Check if entire string is English/numbers only
  static bool isAllEnglishOrNumbers(String text) {
    for (int i = 0; i < text.length; i++) {
      if (!isEnglishOrNumber(text[i])) {
        return false;
      }
    }
    return true;
  }

  // Build mixed font text spans for a string
  // Applies language font to native script, English font to English/numbers
  static List<TextSpan> buildMixedFontSpans(
    String text,
    String languageCode, {
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
    double? height,
  }) {
    if (text.isEmpty) return [];

    final spans = <TextSpan>[];
    final scaledFontSize = getScaledFontSize(languageCode, fontSize);
    
    // Language-specific style
    final languageStyle = TextStyle(
      fontFamily: getFontFamily(languageCode, weight: fontWeight),
      fontSize: scaledFontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
    
    // English/number style
    final englishStyle = TextStyle(
      fontFamily: fontWeight.index >= FontWeight.w600.index ? _englishBold : _englishRegular,
      fontSize: fontSize, // No scaling for English
      fontWeight: fontWeight,
      color: color,
      height: height,
    );

    StringBuffer currentSegment = StringBuffer();
    bool currentIsEnglish = isEnglishOrNumber(text[0]);

    for (int i = 0; i < text.length; i++) {
      final char = text[i];
      final charIsEnglish = isEnglishOrNumber(char);

      if (charIsEnglish == currentIsEnglish) {
        currentSegment.write(char);
      } else {
        // Style changed - add current segment
        if (currentSegment.isNotEmpty) {
          spans.add(TextSpan(
            text: currentSegment.toString(),
            style: currentIsEnglish ? englishStyle : languageStyle,
          ));
        }
        currentSegment = StringBuffer(char);
        currentIsEnglish = charIsEnglish;
      }
    }

    // Add final segment
    if (currentSegment.isNotEmpty) {
      spans.add(TextSpan(
        text: currentSegment.toString(),
        style: currentIsEnglish ? englishStyle : languageStyle,
      ));
    }

    return spans;
  }
}

/// Widget that automatically applies correct font based on character type
/// Uses language font for native script, English font for English/numbers
class MixedFontText extends StatelessWidget {
  final String text;
  final String languageCode;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;
  final double? height;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final int? maxLines;
  final TextOverflow? overflow;

  const MixedFontText(
    this.text, {
    super.key,
    required this.languageCode,
    this.fontSize = 14,
    this.fontWeight = FontWeight.normal,
    this.color,
    this.height,
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    // If text is all English/numbers, just use simple Text with English font
    if (FontManager.isAllEnglishOrNumbers(text)) {
      return Text(
        text,
        style: FontManager.getEnglishTextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          height: height,
        ),
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // Mixed text - use RichText with different fonts
    final spans = FontManager.buildMixedFontSpans(
      text,
      languageCode,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );

    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign ?? TextAlign.start,
      textDirection: textDirection,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );
  }
}

class FontConfig {
  final String regular;
  final String bold;
  final String light;
  final List<String> fallbacks;

  const FontConfig({
    required this.regular,
    required this.bold,
    required this.light,
    this.fallbacks = const ['sans-serif'],
  });
}

// Font weight extensions for convenience
extension FontWeightHelper on FontWeight {
  bool get isBold => index >= FontWeight.w600.index;
  bool get isLight => index <= FontWeight.w300.index;
  bool get isRegular => !isBold && !isLight;
} 