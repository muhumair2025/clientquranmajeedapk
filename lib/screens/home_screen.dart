import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations_extension.dart';
import '../services/content_api_service.dart';
import '../models/category_models.dart';
import '../widgets/hero_slider.dart';
import '../widgets/floating_social_button.dart';
import 'quran_navigation_screen.dart';
import 'subcategories_screen.dart';

class QuranMajeedHomePage extends StatefulWidget {
  const QuranMajeedHomePage({super.key});

  @override
  State<QuranMajeedHomePage> createState() => _QuranMajeedHomePageState();
}

class _QuranMajeedHomePageState extends State<QuranMajeedHomePage> {
  final ContentApiService _apiService = ContentApiService();
  List<ContentCategory> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// Load categories from API or cache
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await _apiService.getCategories();
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load categories';
          _isLoading = false;
        });
      }
    }
  }

  /// Refresh categories from API
  Future<void> _refreshCategories() async {
    try {
      final categories = await _apiService.refreshCategories();
      
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      // Silently fail for refresh, keep existing categories
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l.comingSoon), // Use appropriate error message
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch LanguageProvider to rebuild when language changes
    final languageProvider = context.watch<LanguageProvider>();
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      color: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      child: Stack(
        children: [
          _buildBody(context, languageProvider),
          
          // Floating social button
          Positioned(
            right: 16,
            bottom: 100, // Above bottom nav bar
            child: FloatingSocialButton(
              facebookUrl: 'https://facebook.com/quranmajeed',
              youtubeUrl: 'https://youtube.com/@quranmajeed',
              tiktokUrl: 'https://tiktok.com/@quranmajeed',
              instagramUrl: 'https://instagram.com/quranmajeed',
              onSocialPressed: (url) => _launchUrl(url),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Launch URL in browser
  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch URL: $e');
    }
  }

  Widget _buildBody(BuildContext context, LanguageProvider languageProvider) {
    // Loading state
    if (_isLoading && _categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading categories...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    // Error state (only if no cached categories available)
    if (_errorMessage != null && _categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadCategories,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Categories grid with hero slider at top
    return RefreshIndicator(
      onRefresh: _refreshCategories,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive column count based on screen width
          int crossAxisCount = 2;
          double childAspectRatio = 1.0;
          
          if (constraints.maxWidth > 600) {
            crossAxisCount = 3; // Tablets: 3 columns
            childAspectRatio = 1.1;
          } else if (constraints.maxWidth > 400) {
            crossAxisCount = 2; // Large phones: 2 columns
            childAspectRatio = 1.05;
          } else {
            crossAxisCount = 2; // Small phones: 2 columns
            childAspectRatio = 0.95;
          }

          return CustomScrollView(
            key: ValueKey(languageProvider.currentLanguage),
            slivers: [
              // Hero Slider at top
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 8),
                  child: HeroSlider(
                    height: 180,
                    autoScrollInterval: Duration(seconds: 5),
                  ),
                ),
              ),
              
              // Categories grid
              SliverPadding(
                padding: const EdgeInsets.all(12),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _buildCard(context, _categories[index], languageProvider);
                    },
                    childCount: _categories.length,
                  ),
                ),
              ),
              
              // Bottom padding for navigation bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCard(BuildContext context, ContentCategory category, LanguageProvider languageProvider) {
    // Get category name based on current language
    String languageCode = languageProvider.currentLanguage;
    String title = category.getName(languageCode);
    String? description = category.description;
    
    final isRTL = context.isRTL;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Parse category color from API
    final categoryColor = _parseColor(category.color);
    
    // Use category color or fallback to theme primary color
    final primaryColor = categoryColor ?? theme.colorScheme.primary;
    final surfaceColor = isDark 
        ? const Color(0xFF2D2D2D) 
        : Colors.white;
    final borderColor = isDark 
        ? primaryColor.withOpacity(0.2) 
        : primaryColor.withOpacity(0.12);
    final textColor = theme.colorScheme.onSurface;
    final subtitleColor = theme.colorScheme.onSurface.withOpacity(0.6);

    // Check if this is the Quran category (ID 2) or first in list - it has navigation to Quran
    final bool hasNavigation = category.id == 2; // Quran category

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // Islamic pattern background
            Positioned.fill(
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  color: primaryColor.withOpacity(isDark ? 0.08 : 0.05),
                ),
              ),
            ),
            
            // Card content
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  if (hasNavigation) {
                    // Quran category - navigate to Quran Navigation Screen
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const QuranNavigationScreen(),
                      ),
                    );
                  } else {
                    // Other categories - navigate to Subcategories Screen
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
                splashColor: primaryColor.withOpacity(0.15),
                highlightColor: primaryColor.withOpacity(0.08),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // Top section with icon and navigation indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon container - BIGGER SIZE
                          Container(
                            width: 72,
                            height: 72,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: _buildCategoryIcon(category, primaryColor),
                          ),
                          // Navigation arrow if applicable
                          if (hasNavigation)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isRTL ? Icons.arrow_back_ios_new : Icons.arrow_forward_ios,
                                size: 14,
                                color: primaryColor,
                              ),
                            ),
                        ],
                      ),
                      // Bottom section with title and real description only
                      Column(
                        crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            textAlign: isRTL ? TextAlign.right : TextAlign.left,
                            style: context.textStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Show ONLY real description from backend if available
                          if (description != null && description.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              description,
                              textAlign: isRTL ? TextAlign.right : TextAlign.left,
                              style: context.textStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: subtitleColor,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 6),
                          // Decorative accent line
                          Container(
                            width: 36,
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
          ],
        ),
      ),
    );
  }

  /// Build category icon widget - uses cached icon if available
  Widget _buildCategoryIcon(ContentCategory category, Color primaryColor) {
    // Priority: Use local cached icon path if available
    if (category.localIconPath.isNotEmpty && category.localIconPath.startsWith('/')) {
      final iconFile = File(category.localIconPath);
      return Image.file(
        iconFile,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // If cached file is somehow invalid, show loading indicator
          debugPrint('⚠️ Error loading cached icon for category ${category.id}');
          return Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: primaryColor,
              ),
            ),
          );
        },
      );
    }

    // Fallback: If no cached icon, show loading state
    // The background refresh will download the icon
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: primaryColor,
        ),
      ),
    );
  }

  /// Parse color string from API (e.g., "#10b981")
  Color? _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        final hexColor = colorString.substring(1);
        return Color(int.parse('FF$hexColor', radix: 16));
      }
    } catch (e) {
      // Return null to use theme default
    }
    return null;
  }

}

/// Custom painter for Islamic geometric pattern background
class IslamicPatternPainter extends CustomPainter {
  final Color color;

  IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double spacing = 30.0;
    const double starSize = 9.0;

    // Draw geometric Islamic star pattern
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        // Offset every other row
        final double offsetX = (y ~/ spacing).isOdd ? spacing / 2 : 0;
        _drawStar(canvas, Offset(x + offsetX, y), starSize, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    const int points = 8;
    const double innerRadius = 0.38;

    for (int i = 0; i < points * 2; i++) {
      final double radius = i.isEven ? size : size * innerRadius;
      final double angle = (i * math.pi / points) - (math.pi / 2);
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

