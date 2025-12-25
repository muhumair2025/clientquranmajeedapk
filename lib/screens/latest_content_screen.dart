import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../localization/app_localizations_extension.dart';
import '../services/content_api_service.dart';
import '../models/latest_content_models.dart';
import '../themes/app_theme.dart';
import '../utils/font_manager.dart';
import 'subcategories_screen.dart';

/// Latest Content Screen - Minimal, clean, modern design
/// Shows newest content from categories, subcategories, and materials
class LatestContentScreen extends StatefulWidget {
  const LatestContentScreen({super.key});

  @override
  State<LatestContentScreen> createState() => _LatestContentScreenState();
}

class _LatestContentScreenState extends State<LatestContentScreen> {
  final ContentApiService _apiService = ContentApiService();
  List<LatestItem> _items = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Filter state
  LatestContentType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _loadLatestContent();
  }

  Future<void> _loadLatestContent() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final filter = _selectedFilter != null 
          ? LatestContentFilter(types: {_selectedFilter!})
          : null;
      final items = await _apiService.getLatestContent(filter: filter);
      
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading latest content: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load latest content';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshLatestContent() async {
    try {
      final filter = _selectedFilter != null 
          ? LatestContentFilter(types: {_selectedFilter!})
          : null;
      final items = await _apiService.refreshLatestContent(filter: filter);
      
      if (mounted) {
        setState(() {
          _items = items;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Refresh failed: $e');
    }
  }

  void _setFilter(LatestContentType? type) {
    setState(() {
      _selectedFilter = type;
    });
    _loadLatestContent();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      child: Column(
        children: [
          // Minimal filter bar
          _buildFilterBar(context, isDark),
          
          // Content list
          Expanded(
            child: _buildBody(context, languageProvider, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context, bool isDark) {
    final isRTL = context.isRTL;
    
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        reverse: isRTL,
        children: [
          // All filter
          _buildFilterChip(
            context,
            label: context.l.home,
            icon: Icons.apps_rounded,
            isSelected: _selectedFilter == null,
            onTap: () => _setFilter(null),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          // Category filter
          _buildFilterChip(
            context,
            label: context.l.category,
            icon: Icons.category_outlined,
            isSelected: _selectedFilter == LatestContentType.category,
            onTap: () => _setFilter(LatestContentType.category),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          // Audio filter
          _buildFilterChip(
            context,
            label: context.l.audio,
            icon: Icons.headphones_outlined,
            isSelected: _selectedFilter == LatestContentType.audio || 
                       _selectedFilter == LatestContentType.ayahAudio,
            onTap: () => _setFilter(LatestContentType.audio),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          // Video filter
          _buildFilterChip(
            context,
            label: context.l.video,
            icon: Icons.play_circle_outline_rounded,
            isSelected: _selectedFilter == LatestContentType.video || 
                       _selectedFilter == LatestContentType.ayahVideo,
            onTap: () => _setFilter(LatestContentType.video),
            isDark: isDark,
          ),
          const SizedBox(width: 8),
          // Text filter
          _buildFilterChip(
            context,
            label: context.l.text,
            icon: Icons.article_outlined,
            isSelected: _selectedFilter == LatestContentType.text,
            onTap: () => _setFilter(LatestContentType.text),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.primaryGreen 
              : (isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppTheme.primaryGreen 
                : (isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected 
                  ? Colors.white 
                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected 
                    ? Colors.white 
                    : (isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, LanguageProvider languageProvider, bool isDark) {
    // Loading state
    if (_isLoading && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l.loadingLatestContent,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Error state
    if (_errorMessage != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                context.l.failedToLoadLatest,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _loadLatestContent,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(context.l.retry),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Empty state
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_rounded,
                size: 48,
                color: isDark 
                    ? AppTheme.darkTextSecondary.withOpacity(0.5) 
                    : AppTheme.lightTextSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                context.l.noNewContent,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l.checkBackLater,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Content list
    return RefreshIndicator(
      onRefresh: _refreshLatestContent,
      color: AppTheme.primaryGreen,
      child: ListView.separated(
        key: ValueKey(languageProvider.currentLanguage),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
        itemCount: _items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 1),
        itemBuilder: (context, index) {
          return _buildLatestItem(context, _items[index], isDark, languageProvider);
        },
      ),
    );
  }

  Widget _buildLatestItem(
    BuildContext context,
    LatestItem item,
    bool isDark,
    LanguageProvider languageProvider,
  ) {
    final languageCode = languageProvider.currentLanguage;
    final isRTL = FontManager.isRTL(languageCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBackground : AppTheme.lightCardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _onItemTapped(context, item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              children: [
                // Type indicator
                _buildTypeIndicator(item, isDark),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: isRTL 
                        ? CrossAxisAlignment.end 
                        : CrossAxisAlignment.start,
                    children: [
                      // Title with optional NEW badge
                      Row(
                        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          Expanded(
                            child: MixedFontText(
                              item.title,
                              languageCode: languageCode,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: isDark 
                                  ? AppTheme.darkTextPrimary 
                                  : AppTheme.lightTextPrimary,
                              height: 1.3,
                              textAlign: isRTL ? TextAlign.right : TextAlign.left,
                              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.isNew)
                            Container(
                              margin: EdgeInsets.only(
                                left: isRTL ? 0 : 8,
                                right: isRTL ? 8 : 0,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                context.l.newBadge,
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 3),
                      
                      // Meta info row
                      Row(
                        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          // Type label
                          Text(
                            _getTypeLabel(context, item.type),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.primaryGreen.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          
                          // Dot separator
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark 
                                    ? AppTheme.darkTextSecondary.withOpacity(0.4)
                                    : AppTheme.lightTextSecondary.withOpacity(0.4),
                              ),
                            ),
                          ),
                          
                          // Time ago
                          Text(
                            item.timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark 
                                  ? AppTheme.darkTextSecondary 
                                  : AppTheme.lightTextSecondary,
                            ),
                          ),
                          
                          // Breadcrumb (if exists)
                          if (item.breadcrumb.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark 
                                      ? AppTheme.darkTextSecondary.withOpacity(0.4)
                                      : AppTheme.lightTextSecondary.withOpacity(0.4),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.breadcrumb,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark 
                                      ? AppTheme.darkTextSecondary 
                                      : AppTheme.lightTextSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Arrow
                Icon(
                  isRTL ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark 
                      ? AppTheme.darkTextSecondary.withOpacity(0.3) 
                      : AppTheme.lightTextSecondary.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeIndicator(LatestItem item, bool isDark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          _getTypeIcon(item.type),
          size: 18,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }

  IconData _getTypeIcon(LatestContentType type) {
    switch (type) {
      case LatestContentType.category:
        return Icons.category_outlined;
      case LatestContentType.subcategory:
        return Icons.folder_outlined;
      case LatestContentType.text:
        return Icons.article_outlined;
      case LatestContentType.qa:
        return Icons.help_outline_rounded;
      case LatestContentType.pdf:
        return Icons.description_outlined;
      case LatestContentType.audio:
      case LatestContentType.ayahAudio:
        return Icons.headphones_outlined;
      case LatestContentType.video:
      case LatestContentType.ayahVideo:
        return Icons.play_circle_outline_rounded;
    }
  }

  String _getTypeLabel(BuildContext context, LatestContentType type) {
    switch (type) {
      case LatestContentType.category:
        return context.l.category;
      case LatestContentType.subcategory:
        return context.l.subcategory;
      case LatestContentType.text:
        return context.l.text;
      case LatestContentType.qa:
        return 'Q&A';
      case LatestContentType.pdf:
        return 'PDF';
      case LatestContentType.audio:
        return context.l.audio;
      case LatestContentType.video:
        return context.l.video;
      case LatestContentType.ayahAudio:
        return context.l.ayahAudio;
      case LatestContentType.ayahVideo:
        return context.l.ayahVideo;
    }
  }

  void _onItemTapped(BuildContext context, LatestItem item) {
    switch (item.type) {
      case LatestContentType.category:
        // Navigate to subcategories screen
        if (item.categoryId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubcategoriesScreen(
                categoryId: item.categoryId!,
                categoryName: item.title,
                categoryColor: item.categoryColor ?? '#006653',
              ),
            ),
          );
        }
        break;
        
      case LatestContentType.subcategory:
        // Navigate to subcategories screen with parent category
        if (item.categoryId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubcategoriesScreen(
                categoryId: item.categoryId!,
                categoryName: item.categoryName ?? item.title,
                categoryColor: item.categoryColor ?? '#006653',
              ),
            ),
          );
        } else {
          _showNotification(context, item);
        }
        break;
        
      case LatestContentType.text:
      case LatestContentType.qa:
      case LatestContentType.pdf:
      case LatestContentType.audio:
      case LatestContentType.video:
        // Navigate to subcategory if available, else show notification
        if (item.categoryId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SubcategoriesScreen(
                categoryId: item.categoryId!,
                categoryName: item.categoryName ?? '',
                categoryColor: item.categoryColor ?? '#006653',
              ),
            ),
          );
        } else {
          _showNotification(context, item);
        }
        break;
        
      case LatestContentType.ayahAudio:
      case LatestContentType.ayahVideo:
        // Show notification with ayah info
        _showNotification(context, item);
        break;
    }
  }

  void _showNotification(BuildContext context, LatestItem item) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${item.title} - ${context.l.comingSoon}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        backgroundColor: AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
