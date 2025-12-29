import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations_extension.dart';
import '../widgets/app_text.dart';
import '../widgets/language_selection_modal.dart';

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
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Appearance Section
            _buildSectionHeader(context, context.l.appearance ?? 'Appearance'),
            const SizedBox(height: 8),
            _buildCard(
              context,
              child: Column(
                children: [
                  // Theme Preset Selector
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      return _buildSettingTile(
                        context,
                        icon: Icons.palette_rounded,
                        title: 'Theme Preset',
                        subtitle: themeProvider.getThemePresetName(),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          _showThemePresetDialog(context);
                        },
                      );
                    },
                  ),
                  const Divider(height: 1),
                  Consumer<ThemeProvider>(
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
                          activeColor: Theme.of(context).colorScheme.primary,
                        ),
                        onTap: () {
                          themeProvider.toggleTheme();
                        },
                      );
                    },
                  ),
                  const Divider(height: 1),
                  Consumer<LanguageProvider>(
                    builder: (context, languageProvider, child) {
                      return _buildSettingTile(
                        context,
                        icon: Icons.language_rounded,
                        title: context.l.language,
                        subtitle: _getLanguageName(languageProvider.currentLanguage),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          LanguageSelectionModal.show(context);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // About Section
            _buildSectionHeader(context, context.l.aboutUs),
            const SizedBox(height: 8),
            _buildCard(
              context,
              child: Column(
                children: [
                  _buildSettingTile(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: context.l.aboutUs,
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showAboutDialog(context);
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    context,
                    icon: Icons.privacy_tip_rounded,
                    title: 'Privacy Policy',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showComingSoonDialog(context, 'Privacy Policy');
                    },
                  ),
                  const Divider(height: 1),
                  _buildSettingTile(
                    context,
                    icon: Icons.description_rounded,
                    title: 'Terms of Service',
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 48,
                      color: AppTheme.primaryGreen,
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
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : Colors.white,
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
    
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryGreen,
        size: 24,
      ),
      title: AppText(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? AppText(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  String _getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'en':
        return 'English';
      case 'ur':
        return 'اردو';
      case 'ar':
        return 'العربية';
      case 'ps':
        return 'پښتو';
      default:
        return 'English';
    }
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
                style: const TextStyle(
                  color: AppTheme.primaryGreen,
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
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showThemePresetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Consumer<ThemeProvider>(
          builder: (context, themeProvider, child) {
            return AlertDialog(
              title: const AppText(
                'Choose Theme',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildThemePresetOption(
                      context,
                      themeProvider,
                      ThemePreset.classicGreen,
                      'Classic Green',
                      'Traditional Islamic theme with emerald green',
                      AppTheme.primaryGreen,
                      AppTheme.accentGreen,
                    ),
                    const SizedBox(height: 12),
                    _buildThemePresetOption(
                      context,
                      themeProvider,
                      ThemePreset.royalBlue,
                      'Royal Blue',
                      'Elegant deep blue with golden accents',
                      AppTheme.primaryBlue,
                      AppTheme.goldAccent,
                    ),
                    const SizedBox(height: 12),
                    _buildThemePresetOption(
                      context,
                      themeProvider,
                      ThemePreset.desertGold,
                      'Desert Gold',
                      'Warm earthy tones inspired by desert landscapes',
                      AppTheme.primaryBeige,
                      AppTheme.bronzeAccent,
                    ),
                    const SizedBox(height: 12),
                    _buildThemePresetOption(
                      context,
                      themeProvider,
                      ThemePreset.nightPurple,
                      'Night Purple',
                      'Mystical purple with silver highlights',
                      AppTheme.primaryPurple,
                      AppTheme.silverAccent,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: AppText(
                    context.l.close,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildThemePresetOption(
    BuildContext context,
    ThemeProvider themeProvider,
    ThemePreset preset,
    String name,
    String description,
    Color primaryColor,
    Color accentColor,
  ) {
    final isSelected = themeProvider.themePreset == preset;
    
    return InkWell(
      onTap: () {
        themeProvider.setThemePreset(preset);
        Navigator.of(context).pop();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected 
              ? primaryColor.withOpacity(0.1) 
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Color Preview
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    accentColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Theme Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? primaryColor 
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

