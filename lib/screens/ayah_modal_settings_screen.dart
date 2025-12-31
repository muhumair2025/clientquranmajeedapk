import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ayah_modal_settings_provider.dart';
import '../localization/app_localizations_extension.dart';
import '../utils/font_manager.dart';
import '../utils/theme_extensions.dart';
import '../providers/language_provider.dart';
import '../widgets/app_text.dart';

/// Compact settings screen for ayah modal customization
class AyahModalSettingsScreen extends StatelessWidget {
  const AyahModalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final isRTL = FontManager.isRTL(languageProvider.currentLanguage);
    final uiFont = FontManager.getRegularFont(languageProvider.currentLanguage);
    
    return Directionality(
      textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: isDark ? context.backgroundColor : Colors.white,
        appBar: AppBar(
          title: AppText(
            context.l.ayahModalSettings,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: uiFont,
            ),
          ),
          backgroundColor: context.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Consumer<AyahModalSettingsProvider>(
          builder: (context, settings, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Visibility Settings Section
                _buildSectionHeader(context, context.l.adjustSettings, isDark, uiFont),
                const SizedBox(height: 12),
                
                // Show Arabic Text Toggle
                _buildSwitchTile(
                  context: context,
                  title: context.l.showArabicText,
                  value: settings.showArabicText,
                  onChanged: (value) => settings.setShowArabicText(value),
                  isDark: isDark,
                  uiFont: uiFont,
                ),
                
                const SizedBox(height: 8),
                
                // Show Translation Toggle
                _buildSwitchTile(
                  context: context,
                  title: context.l.showTranslation,
                  value: settings.showTranslation,
                  onChanged: (value) => settings.setShowTranslation(value),
                  isDark: isDark,
                  uiFont: uiFont,
                ),
                
                const SizedBox(height: 24),
                
                // Font Settings Section
                _buildSectionHeader(context, context.l.fontSettings, isDark, uiFont),
                const SizedBox(height: 12),
                
                // Arabic Font Selection
                _buildFontSelector(
                  context: context,
                  title: context.l.arabicFont,
                  currentFont: settings.arabicFont,
                  availableFonts: AyahModalSettingsProvider.availableArabicFonts,
                  onFontSelected: (font) => settings.setArabicFont(font),
                  isDark: isDark,
                  uiFont: uiFont,
                ),
                
                const SizedBox(height: 12),
                
                // Translation Font Selection
                _buildFontSelector(
                  context: context,
                  title: context.l.translationFont,
                  currentFont: settings.pashtoFont,
                  availableFonts: AyahModalSettingsProvider.availablePashtoFonts,
                  onFontSelected: (font) => settings.setPashtoFont(font),
                  isDark: isDark,
                  uiFont: uiFont,
                ),
                
                const SizedBox(height: 24),
                
                // Font Size Settings Section
                _buildSectionHeader(context, context.l.fontSize, isDark, uiFont),
                const SizedBox(height: 12),
                
                // Arabic Font Size
                _buildFontSizeSlider(
                  context: context,
                  title: context.l.arabicFontSize,
                  value: settings.arabicFontSize,
                  min: 12.0,
                  max: 40.0,
                  onChanged: (value) => settings.setArabicFontSize(value),
                  isDark: isDark,
                  uiFont: uiFont,
                ),
                
                const SizedBox(height: 16),
                
                // Translation Font Size
                _buildFontSizeSlider(
                  context: context,
                  title: context.l.translationFontSize,
                  value: settings.translationFontSize,
                  min: 10.0,
                  max: 24.0,
                  onChanged: (value) => settings.setTranslationFontSize(value),
                  isDark: isDark,
                  uiFont: uiFont,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, bool isDark, String uiFont) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: AppText(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : context.primaryColor,
          fontFamily: uiFont,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required String uiFont,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? context.cardColor : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: SwitchListTile(
        title: AppText(
          title,
          style: TextStyle(
            fontSize: 14,
            fontFamily: uiFont,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: context.primaryColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildFontSelector({
    required BuildContext context,
    required String title,
    required String currentFont,
    required List<String> availableFonts,
    required ValueChanged<String> onFontSelected,
    required bool isDark,
    required String uiFont,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? context.cardColor : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: ExpansionTile(
        title: AppText(
          title,
          style: TextStyle(
            fontSize: 14,
            fontFamily: uiFont,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: AppText(
          currentFont,
          style: TextStyle(
            fontSize: 12,
            fontFamily: uiFont,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        iconColor: context.primaryColor,
        collapsedIconColor: isDark ? Colors.white70 : Colors.black54,
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        children: availableFonts.map((font) {
          final isSelected = font == currentFont;
          return ListTile(
            title: AppText(
              font,
              style: TextStyle(
                fontSize: 13,
                fontFamily: uiFont,
                color: isSelected
                    ? context.primaryColor
                    : (isDark ? Colors.white : Colors.black87),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: context.primaryColor, size: 20)
                : null,
            onTap: () => onFontSelected(font),
            contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFontSizeSlider({
    required BuildContext context,
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required bool isDark,
    required String uiFont,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? context.cardColor : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: uiFont,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              AppText(
                value.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: uiFont,
                  fontWeight: FontWeight.w600,
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) / 2).round(),
            onChanged: onChanged,
            activeColor: context.primaryColor,
            inactiveColor: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
        ],
      ),
    );
  }
}


