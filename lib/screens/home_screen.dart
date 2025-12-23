import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations_extension.dart';
import 'quran_navigation_screen.dart';

class QuranMajeedHomePage extends StatefulWidget {
  const QuranMajeedHomePage({super.key});

  @override
  State<QuranMajeedHomePage> createState() => _QuranMajeedHomePageState();
}

class _QuranMajeedHomePageState extends State<QuranMajeedHomePage> {
  // Card data with icons (using theme colors)
  final List<CardData> _cardData = [
    CardData(
      icon: Icons.menu_book,
      titleKey: 'tafseerTranslation',
      hasNavigation: true,
    ),
    CardData(
      icon: Icons.verified,
      titleKey: 'aqeedah',
      hasNavigation: false,
    ),
    CardData(
      icon: Icons.article,
      titleKey: 'hadith',
      hasNavigation: false,
    ),
    CardData(
      icon: Icons.balance,
      titleKey: 'fiqh',
      hasNavigation: false,
    ),
    CardData(
      icon: Icons.history_edu,
      titleKey: 'seerahHistory',
      hasNavigation: false,
    ),
    CardData(
      icon: Icons.school,
      titleKey: 'scientificCourses',
      hasNavigation: false,
    ),
    CardData(
      icon: Icons.favorite,
      titleKey: 'ethicsManners',
      hasNavigation: false,
    ),
    CardData(
      icon: Icons.spa,
      titleKey: 'adhkarDuas',
      hasNavigation: false,
    ),
    CardData(
      icon: Icons.campaign,
      titleKey: 'variousStatements',
      hasNavigation: false,
    ),
    CardData(
      icon: Icons.help_outline,
      titleKey: 'questionAnswer',
      hasNavigation: false,
    ),
    CardData(
      icon: Icons.library_books,
      titleKey: 'books',
      hasNavigation: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Watch LanguageProvider to rebuild when language changes
    final languageProvider = context.watch<LanguageProvider>();
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          key: ValueKey(languageProvider.currentLanguage), // Force rebuild on language change
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.15,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _cardData.length,
          itemBuilder: (context, index) {
            return _buildCard(context, _cardData[index]);
          },
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, CardData data) {
    String title = _getTitleForKey(context, data.titleKey);
    final isRTL = context.isRTL;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Use theme colors for a clean, consistent look
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = isDark 
        ? const Color(0xFF2D2D2D) 
        : Colors.white;
    final borderColor = isDark 
        ? primaryColor.withOpacity(0.2) 
        : primaryColor.withOpacity(0.12);
    final iconBgColor = isDark 
        ? primaryColor.withOpacity(0.15) 
        : primaryColor.withOpacity(0.08);
    final textColor = theme.colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3) 
                : primaryColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: data.hasNavigation
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const QuranNavigationScreen(),
                    ),
                  );
                }
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(context.l.comingSoon),
                      duration: const Duration(seconds: 1),
                      backgroundColor: primaryColor,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
          splashColor: primaryColor.withOpacity(0.15),
          highlightColor: primaryColor.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Top section with icon and navigation indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon container with theme colors
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        data.icon,
                        size: 26,
                        color: primaryColor,
                      ),
                    ),
                    // Navigation arrow if applicable
                    if (data.hasNavigation)
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isRTL ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
                          size: 12,
                          color: primaryColor,
                        ),
                      ),
                  ],
                ),
                // Bottom section with title
                Column(
                  crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: isRTL ? TextAlign.right : TextAlign.left,
                      style: context.textStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Decorative accent line
                    Container(
                      width: 28,
                      height: 3,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTitleForKey(BuildContext context, String key) {
    switch (key) {
      case 'tafseerTranslation':
        return context.l.tafseerTranslation;
      case 'aqeedah':
        return context.l.aqeedah;
      case 'hadith':
        return context.l.hadith;
      case 'fiqh':
        return context.l.fiqh;
      case 'seerahHistory':
        return context.l.seerahHistory;
      case 'scientificCourses':
        return context.l.scientificCourses;
      case 'ethicsManners':
        return context.l.ethicsManners;
      case 'adhkarDuas':
        return context.l.adhkarDuas;
      case 'variousStatements':
        return context.l.variousStatements;
      case 'questionAnswer':
        return context.l.questionAnswer;
      case 'books':
        return context.l.books;
      default:
        return '';
    }
  }
}

// Helper class for card data
class CardData {
  final IconData icon;
  final String titleKey;
  final bool hasNavigation;

  CardData({
    required this.icon,
    required this.titleKey,
    required this.hasNavigation,
  });
}

