import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/app_theme.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations_extension.dart';
import '../screens/quran_navigation_screen.dart';
import '../screens/subcategories_screen.dart';
import '../screens/settings_screen.dart';
import '../services/content_api_service.dart';
import '../services/mushaf_download_service.dart';
import '../models/category_models.dart';
import '../widgets/mushaf_script_modal.dart';
import 'app_text.dart';

class QuranMajeedDrawer extends StatefulWidget {
  final VoidCallback onNavigateToHome;
  
  const QuranMajeedDrawer({
    super.key,
    required this.onNavigateToHome,
  });

  @override
  State<QuranMajeedDrawer> createState() => _QuranMajeedDrawerState();
}

class _QuranMajeedDrawerState extends State<QuranMajeedDrawer> {
  final ContentApiService _apiService = ContentApiService();
  List<ContentCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories.take(5).toList(); // Only first 5 categories
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        final primaryColor = theme.colorScheme.primary;
        final darkColor = isDark 
            ? primaryColor.withValues(alpha: 0.7) 
            : Color.lerp(primaryColor, Colors.black, 0.3)!;
        
        return Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark 
                  ? [
                      darkColor,
                      primaryColor.withValues(alpha: 0.9),
                      darkColor.withValues(alpha: 0.8),
                    ]
                  : [primaryColor, darkColor],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Compact header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.menu_book_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.l.appTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(color: Colors.white24, height: 1),
                  
                  // Scrollable content
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        // Home menu
                        _buildCompactDrawerItem(
                          context,
                          title: context.l.home,
                          onTap: () {
                            Navigator.of(context).pop();
                            widget.onNavigateToHome();
                          },
                        ),
                        
                        // API Categories (first 5)
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          )
                        else
                          ..._categories.map((category) {
                            final title = category.getName(languageProvider.currentLanguage);
                            final isQuranCategory = category.id == 2;
                            
                            return _buildCompactDrawerItem(
                              context,
                              title: title,
                              onTap: () async {
                                Navigator.of(context).pop();
                                
                                if (isQuranCategory) {
                                  // Quran category - check if script is downloaded first
                                  final isScriptReady = await MushafDownloadService.shouldUseDownloadedImages();
                                  
                                  if (!isScriptReady) {
                                    if (!context.mounted) return;
                                    final result = await MushafScriptModal.show(context);
                                    if (!result) return;
                                  }
                                  
                                  if (!context.mounted) return;
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const QuranNavigationScreen(),
                                    ),
                                  );
                                } else {
                                  // Other categories - navigate to subcategories
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SubcategoriesScreen(
                                        categoryId: category.id,
                                        categoryName: title,
                                        categoryColor: category.color,
                                      ),
                                    ),
                                  );
                                }
                              },
                            );
                          }),
                        
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Divider(color: Colors.white24, height: 1),
                        ),
                        
                        // Settings menu
                        _buildCompactDrawerItem(
                          context,
                          title: context.l.settings,
                          onTap: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactDrawerItem(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    final isRTL = context.isRTL;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          isRTL ? 16 : 20,
          10,
          isRTL ? 20 : 16,
          10,
        ),
        child: Row(
          children: [
            Expanded(
              child: AppText(
                title,
                textAlign: isRTL ? TextAlign.right : TextAlign.left,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
            Icon(
              isRTL ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}

