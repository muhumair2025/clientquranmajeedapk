import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../utils/font_manager.dart';

/// AppText - Drop-in replacement for Text widget
/// Automatically uses correct font for each character type:
/// - Pashto/Urdu/Arabic characters → Language font
/// - English/Numbers → Poppins (English font)
/// 
/// Usage: Just replace `Text(` with `AppText(` in your code
class AppText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final double? textScaleFactor;
  final StrutStyle? strutStyle;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  const AppText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textScaleFactor,
    this.strutStyle,
    this.textWidthBasis,
    this.textHeightBehavior,
  });

  @override
  Widget build(BuildContext context) {
    // Get current language
    final languageProvider = context.watch<LanguageProvider>();
    final languageCode = languageProvider.currentLanguage;
    
    // If English language, just use regular Text
    if (languageCode == 'en') {
      return Text(
        data,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        strutStyle: strutStyle,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
      );
    }

    // If text is all English/numbers, use English font
    if (FontManager.isAllEnglishOrNumbers(data)) {
      final englishStyle = _getEnglishStyle(context);
      return Text(
        data,
        style: englishStyle,
        textAlign: textAlign,
        textDirection: textDirection,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        strutStyle: strutStyle,
        textWidthBasis: textWidthBasis,
        textHeightBehavior: textHeightBehavior,
      );
    }

    // Mixed text - use RichText with different fonts for each segment
    final spans = _buildMixedSpans(context, languageCode);
    
    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign ?? TextAlign.start,
      textDirection: textDirection ?? FontManager.getTextDirection(languageCode),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      softWrap: softWrap ?? true,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis ?? TextWidthBasis.parent,
      textHeightBehavior: textHeightBehavior,
    );
  }

  /// Build text spans with correct font for each character type
  List<TextSpan> _buildMixedSpans(BuildContext context, String languageCode) {
    if (data.isEmpty) return [];

    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final spans = <TextSpan>[];
    
    // Get font properties from base style
    final fontSize = baseStyle.fontSize ?? 14.0;
    final fontWeight = baseStyle.fontWeight ?? FontWeight.normal;
    final color = baseStyle.color;
    final height = baseStyle.height;
    final letterSpacing = baseStyle.letterSpacing;
    final decoration = baseStyle.decoration;
    final decorationColor = baseStyle.decorationColor;
    final decorationStyle = baseStyle.decorationStyle;
    
    // Language-specific style (scaled font size for Pashto etc)
    final scaledFontSize = FontManager.getScaledFontSize(languageCode, fontSize);
    final languageStyle = TextStyle(
      fontFamily: FontManager.getFontFamily(languageCode, weight: fontWeight),
      fontSize: scaledFontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
    );
    
    // English/number style (no scaling, uses Poppins)
    final englishStyle = TextStyle(
      fontFamily: fontWeight.index >= FontWeight.w600.index 
          ? 'Poppins Bold' 
          : 'Poppins Regular',
      fontSize: fontSize, // No scaling for English
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
    );

    StringBuffer currentSegment = StringBuffer();
    bool currentIsEnglish = FontManager.isEnglishOrNumber(data[0]);

    for (int i = 0; i < data.length; i++) {
      final char = data[i];
      final charIsEnglish = FontManager.isEnglishOrNumber(char);

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

  /// Get English style based on base style
  TextStyle _getEnglishStyle(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    final fontWeight = baseStyle.fontWeight ?? FontWeight.normal;
    
    return baseStyle.copyWith(
      fontFamily: fontWeight.index >= FontWeight.w600.index 
          ? 'Poppins Bold' 
          : 'Poppins Regular',
    );
  }
}

