import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations_extension.dart';
import '../screens/quran_navigation_screen.dart';
import 'language_selection_modal.dart';

class QuranMajeedDrawer extends StatelessWidget {
  final VoidCallback onNavigateToHome;
  
  const QuranMajeedDrawer({
    super.key,
    required this.onNavigateToHome,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark 
                  ? [
                      AppTheme.darkGreen,
                      AppTheme.primaryGreen.withValues(alpha: 0.9),
                      AppTheme.darkGreen.withValues(alpha: 0.8),
                    ]
                  : [AppTheme.primaryGreen, AppTheme.darkGreen],
              ),
            ),
            child: Column(
              children: [
                // Fixed header
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.l.appTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildDrawerItem(
                        context,
                        icon: Icons.home_rounded,
                        title: context.l.home,
                        onTap: () {
                          Navigator.of(context).pop();
                          onNavigateToHome();
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.book_rounded,
                        title: context.l.quranKareem,
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QuranNavigationScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.star_rounded,
                        title: context.l.aqeedah,
                        onTap: () {
                          Navigator.of(context).pop();
                          _showComingSoonDialog(context, context.l.aqeedah);
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.library_books_rounded,
                        title: context.l.tafseerTranslation,
                        onTap: () {
                          Navigator.of(context).pop();
                          _showComingSoonDialog(context, context.l.tafseerTranslation);
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.balance_rounded,
                        title: context.l.fiqh,
                        onTap: () {
                          Navigator.of(context).pop();
                          _showComingSoonDialog(context, context.l.fiqh);
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.chat_bubble_rounded,
                        title: context.l.hadith,
                        onTap: () {
                          Navigator.of(context).pop();
                          _showComingSoonDialog(context, context.l.hadith);
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.help_rounded,
                        title: context.l.questionAnswer,
                        onTap: () {
                          Navigator.of(context).pop();
                          _showComingSoonDialog(context, context.l.questionAnswer);
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.library_books_rounded,
                        title: context.l.books,
                        onTap: () {
                          Navigator.of(context).pop();
                          _showComingSoonDialog(context, context.l.books);
                        },
                      ),
                      const Divider(color: Colors.white54),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return _buildDrawerItem(
                            context,
                            icon: themeProvider.isDarkMode
                              ? Icons.light_mode_rounded 
                              : Icons.dark_mode_rounded,
                            title: themeProvider.isDarkMode
                              ? context.l.lightMode
                              : context.l.darkMode,
                            onTap: () {
                              themeProvider.toggleTheme();
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.language_rounded,
                        title: context.l.language,
                        onTap: () {
                          Navigator.of(context).pop();
                          LanguageSelectionModal.show(context);
                        },
                      ),
                      _buildDrawerItem(
                        context,
                        icon: Icons.info_rounded,
                        title: context.l.aboutUs,
                        onTap: () {
                          Navigator.of(context).pop();
                          _showComingSoonDialog(context, context.l.aboutUs);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            context.l.comingSoon,
            style: const TextStyle(
              fontFamily: 'Bahij Badr Bold',
            ),
          ),
          content: Text(
            '$featureName ${context.l.featureNotAvailable}',
            style: const TextStyle(
              fontFamily: 'Bahij Badr Light',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                context.l.ok,
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontFamily: 'Bahij Badr Medium',
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

