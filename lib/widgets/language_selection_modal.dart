import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../themes/app_theme.dart';
import '../localization/app_localizations_extension.dart';
import '../utils/theme_extensions.dart';


class LanguageSelectionModal extends StatelessWidget {
  const LanguageSelectionModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const LanguageSelectionModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(
                    Icons.language_rounded,
                    color: context.primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child:                     Text(
                      context.l.selectLanguage,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            
            // Language options
            Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: LanguageProvider.supportedLocales.map((locale) {
                      final isSelected = languageProvider.currentLocale == locale;
                      final languageName = languageProvider.getLanguageName(locale);
                      final languageFlag = _getLanguageFlag(locale.languageCode);
                      final languageEnglishName = _getLanguageEnglishName(locale.languageCode);
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildLanguageOption(
                          context: context,
                          locale: locale,
                          languageName: languageName,
                          languageEnglishName: languageEnglishName,
                          languageFlag: languageFlag,
                          isSelected: isSelected,
                          isDark: isDark,
                          onTap: () async {
                            await languageProvider.changeLanguage(locale);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              _showLanguageChangedSnackBar(context);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required Locale locale,
    required String languageName,
    required String languageEnglishName,
    required String languageFlag,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? context.primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected 
                  ? context.primaryColor 
                  : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Flag
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? context.primaryColor.withValues(alpha: 0.1)
                      : (isDark ? Colors.grey[800] : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    languageFlag,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Language names
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected 
                            ? context.primaryColor 
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      languageEnglishName,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontFamily: 'Poppins Regular', // Always use English font for English names
                      ),
                    ),
                  ],
                ),
              ),
              
              // Selected indicator
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: context.primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getLanguageFlag(String languageCode) {
    switch (languageCode) {
      case 'ps':
        return '🇦🇫'; // Afghanistan flag for Pashto
      case 'en':
        return '🇺🇸'; // US flag for English
      case 'ur':
        return '🇵🇰'; // Pakistan flag for Urdu
      case 'ar':
        return '🇸🇦'; // Saudi Arabia flag for Arabic
      default:
        return '🌐';
    }
  }

  String _getLanguageEnglishName(String languageCode) {
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

  void _showLanguageChangedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l.languageChanged,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: context.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 