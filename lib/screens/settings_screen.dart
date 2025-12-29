import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations_extension.dart';
import '../widgets/app_text.dart';
import '../utils/theme_extensions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: AppText(
          context.l.settings,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: isDark ? context.backgroundColor : context.backgroundColor,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Appearance Section
            _buildSectionHeader(context, context.l.appearance ?? 'Appearance'),
            const SizedBox(height: 12),
            
            // Theme Preset Selection (Inline)
            _buildCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.palette_rounded,
                          color: context.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        AppText(
                          'Theme Preset',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return Column(
                        children: [
                          _buildThemePresetTile(
                            context,
                            themeProvider,
                            ThemePreset.classicGreen,
                            'Classic Green',
                            AppTheme.primaryGreen,
                            AppTheme.lightGreen,
                          ),
                          _buildThemePresetTile(
                            context,
                            themeProvider,
                            ThemePreset.royalBlue,
                            'Royal Blue',
                            AppTheme.primaryBlue,
                            AppTheme.goldAccent,
                          ),
                          _buildThemePresetTile(
                            context,
                            themeProvider,
                            ThemePreset.desertGold,
                            'Desert Gold',
                            AppTheme.primaryBeige,
                            AppTheme.bronzeAccent,
                          ),
                          _buildThemePresetTile(
                            context,
                            themeProvider,
                            ThemePreset.nightPurple,
                            'Night Purple',
                            AppTheme.primaryPurple,
                            AppTheme.silverAccent,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Dark Mode Toggle
            _buildCard(
              context,
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return _buildSettingTile(
                    context,
                    icon: themeProvider.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    title: context.l.darkMode,
                    trailing: Switch(
                      value: themeProvider.isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                      activeColor: context.primaryColor,
                    ),
                    onTap: () {
                      themeProvider.toggleTheme();
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Language Section
            _buildSectionHeader(context, context.l.language),
            const SizedBox(height: 12),
            
            // Language Selection (Inline)
            _buildCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.language_rounded,
                          color: context.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        AppText(
                          'Select Language',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return Column(
                        children: [
                          _buildLanguageTile(
                            context,
                            languageProvider,
                            'en',
                            'English',
                            '🇬🇧',
                          ),
                          _buildLanguageTile(
                            context,
                            languageProvider,
                            'ur',
                            'اردو',
                            '🇵🇰',
                          ),
                          _buildLanguageTile(
                            context,
                            languageProvider,
                            'ar',
                            'العربية',
                            '🇸🇦',
                          ),
                          _buildLanguageTile(
                            context,
                            languageProvider,
                            'ps',
                            'پښتو',
                            '🇦🇫',
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // About Section
            _buildSectionHeader(context, context.l.aboutUs),
            const SizedBox(height: 12),
            _buildCard(
              context,
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: context.l.aboutUs,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      _showAboutDialog(context);
                    },
                  ),
                  const Divider(height: 1, indent: 52),
                  _buildSettingTile(
                    context,
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      _showComingSoonDialog(context, 'Privacy Policy');
                    },
                  ),
                  const Divider(height: 1, indent: 52),
                  _buildSettingTile(
                    context,
                    icon: Icons.description_rounded,
                    title: 'Terms of Service',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      _showComingSoonDialog(context, 'Terms of Service');
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // App Info
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 48,
                      color: context.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppText(
                    context.l.appTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: AppText(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: context.primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? context.surfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: context.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    AppText(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    LanguageProvider languageProvider,
    String languageCode,
    String languageName,
    String flag,
  ) {
    final isSelected = languageProvider.currentLanguage == languageCode;
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () {
        // Convert language code to Locale
        Locale newLocale;
        switch (languageCode) {
          case 'en':
            newLocale = const Locale('en', 'US');
            break;
          case 'ur':
            newLocale = const Locale('ur', 'PK');
            break;
          case 'ar':
            newLocale = const Locale('ar', 'SA');
            break;
          case 'ps':
            newLocale = const Locale('ps', 'AF');
            break;
          default:
            newLocale = const Locale('en', 'US');
        }
        languageProvider.changeLanguage(newLocale);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? context.primaryColor.withOpacity(0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? context.primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppText(
                languageName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected 
                      ? context.primaryColor
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: context.primaryColor,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePresetTile(
    BuildContext context,
    ThemeProvider themeProvider,
    ThemePreset preset,
    String name,
    Color primaryColor,
    Color accentColor,
  ) {
    final isSelected = themeProvider.themePreset == preset;
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () {
        themeProvider.setThemePreset(preset);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected 
              ? context.primaryColor.withOpacity(0.08)
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? context.primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            // Color preview
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [primaryColor, accentColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppText(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected 
                      ? context.primaryColor
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: context.primaryColor,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: AppText(
            context.l.aboutUs,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: AppText(
            'Quran Majeed is a comprehensive Islamic app that provides access to the Holy Quran, translations, audio, and various Islamic content.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: AppText(
                context.l.ok,
                style: TextStyle(
                  color: context.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showComingSoonDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: AppText(
            context.l.comingSoon,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: AppText(
            '$featureName ${context.l.featureNotAvailable}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: AppText(
                context.l.ok,
                style: TextStyle(
                  color: context.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
