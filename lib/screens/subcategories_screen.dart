import '../widgets/app_text.dart';
import 'content_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../providers/language_provider.dart';
import '../localization/app_localizations_extension.dart';
import '../services/content_api_service.dart';
import '../models/category_models.dart';
import '../themes/app_theme.dart';
import '../utils/font_manager.dart';
import '../utils/theme_extensions.dart';

class SubcategoriesScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;
  final String categoryColor;

  const SubcategoriesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
  });

  @override
  State<SubcategoriesScreen> createState() => _SubcategoriesScreenState();
}

class _SubcategoriesScreenState extends State<SubcategoriesScreen> {
  final ContentApiService _apiService = ContentApiService();
  List<Subcategory> _subcategories = [];
  bool _isLoading = true;
  String? _errorMessage;
  Color? _categoryColor;

  @override
  void initState() {
    super.initState();
    _categoryColor = _parseColor(widget.categoryColor);
    _loadSubcategories();
  }

  Future<void> _loadSubcategories() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final languageCode = context.read<LanguageProvider>().currentLanguage;
    debugPrint('🌍 Current language: $languageCode');

    // Try to load from cache first
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'subcategories_${widget.categoryId}';
    final cachedData = prefs.getString(cacheKey);
    
    if (cachedData != null) {
      try {
        final Map<String, dynamic> cached = json.decode(cachedData);
        final subcategoriesList = cached['data'] as List<dynamic>? ?? [];
        
        final subcategories = _parseSubcategories(subcategoriesList, languageCode);
        
        if (mounted) {
          setState(() {
            _subcategories = subcategories;
            _isLoading = false;
          });
          debugPrint('✅ Loaded ${subcategories.length} subcategories from cache');
        }
        return;
      } catch (e) {
        debugPrint('⚠️ Error parsing cached subcategories: $e');
      }
    }

    // Fetch from API if no cache
    await _fetchFromApi();
  }

  Future<void> _fetchFromApi() async {
    if (!mounted) return;
    
    try {
      final response = await _apiService.getCategoryDetail(widget.categoryId);
      debugPrint('📡 API Response: $response');
      
      if (mounted) {
        final subcategoriesList = response['subcategories'] as List<dynamic>? ?? [];
        debugPrint('📋 Subcategories list length: ${subcategoriesList.length}');
        
        final languageCode = context.read<LanguageProvider>().currentLanguage;
        
        final subcategories = _parseSubcategories(subcategoriesList, languageCode);
        
        // Cache the response
        final prefs = await SharedPreferences.getInstance();
        final cacheKey = 'subcategories_${widget.categoryId}';
        await prefs.setString(cacheKey, json.encode({
          'data': subcategoriesList,
          'timestamp': DateTime.now().toIso8601String(),
        }));
        debugPrint('💾 Cached ${subcategories.length} subcategories');
        
        setState(() {
          _subcategories = subcategories;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error loading subcategories: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load subcategories';
          _isLoading = false;
        });
      }
    }
  }

  List<Subcategory> _parseSubcategories(List<dynamic> subcategoriesList, String languageCode) {
    return subcategoriesList.map((item) {
      // API returns 'name' as a direct string, not a 'names' object
      String name = item['name']?.toString() ?? '';
      
      // Remove bullet points and extra spaces from the name
      name = name.replaceAll('•', '').trim();
      
      debugPrint('✅ Parsed subcategory: "$name"');
      
      return Subcategory(
        id: item['id'] ?? 0,
        name: name,
        description: item['description']?.toString(),
        contentsCount: item['contents_count'] ?? 0,
      );
    }).toList();
  }

  Future<void> _refreshSubcategories() async {
    // Smart refresh: only update cache if internet is available
    try {
      await _fetchFromApi();
    } catch (e) {
      debugPrint('⚠️ Refresh failed, keeping cached data: $e');
      // Keep existing data if refresh fails
    }
  }

  Color? _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        final hexColor = colorString.substring(1);
        return Color(int.parse('FF$hexColor', radix: 16));
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = _categoryColor ?? context.primaryColor;

    return Scaffold(
      backgroundColor: isDark ? context.backgroundColor : context.backgroundColor,
      appBar: AppBar(
        title: AppText(
          widget.categoryName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: context.primaryColor, // Use theme color
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(context, languageProvider, isDark, primaryColor),
    );
  }

  Widget _buildBody(BuildContext context, LanguageProvider languageProvider, bool isDark, Color primaryColor) {
    // Loading state
    if (_isLoading && _subcategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: primaryColor,
            ),
            const SizedBox(height: 16),
            AppText(
              'Loading...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    // Error state
    if (_errorMessage != null && _subcategories.isEmpty) {
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
            AppText(
              _errorMessage!,
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadSubcategories,
              icon: const Icon(Icons.refresh),
              label: const AppText('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Empty state
    if (_subcategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            AppText(
              'No subcategories available',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    // Subcategories list
    return RefreshIndicator(
      onRefresh: _refreshSubcategories,
      color: primaryColor,
      child: ListView.builder(
        key: ValueKey(languageProvider.currentLanguage),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), // Extra bottom padding
        itemCount: _subcategories.length,
        itemBuilder: (context, index) {
          return _buildSubcategoryItem(
            context,
            _subcategories[index],
            isDark,
            primaryColor,
          );
        },
      ),
    );
  }

  Widget _buildSubcategoryItem(
    BuildContext context,
    Subcategory subcategory,
    bool isDark,
    Color primaryColor,
  ) {
    final languageProvider = context.watch<LanguageProvider>();
    final languageCode = languageProvider.currentLanguage;
    final isRTL = FontManager.isRTL(languageCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 8), // More compact spacing
      decoration: BoxDecoration(
        color: isDark ? context.cardColor : context.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.primaryColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to content list screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContentListScreen(
                  subcategoryId: subcategory.id,
                  subcategoryName: subcategory.name,
                  categoryColor: widget.categoryColor,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), // More compact padding
            child: Row(
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              crossAxisAlignment: CrossAxisAlignment.center, // Better alignment
              children: [
                // Islamic pattern bullet point
                Image.asset(
                  'assets/images/islamic-pattern.png',
                  width: 20,
                  height: 20,
                  color: context.primaryColor,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.circle,
                      size: 8,
                      color: context.primaryColor,
                    );
                  },
                ),
                SizedBox(width: isRTL ? 10 : 10), // Consistent spacing
                
                // Subcategory info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch, // Force full width
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                        child: AppText(
                          subcategory.name,
                          style: FontManager.getTextStyle(
                            languageCode,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? context.textColor : context.textColor,
                            height: 1.4,
                          ),
                          textAlign: isRTL ? TextAlign.right : TextAlign.left,
                          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                        ),
                      ),
                      if (subcategory.description != null && subcategory.description!.isNotEmpty) ...[
                        const SizedBox(height: 4), // More compact spacing
                        Align(
                          alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                          child: AppText(
                            subcategory.description!,
                            style: FontManager.getTextStyle(
                              languageCode,
                              fontSize: 12.5,
                              color: isDark ? context.secondaryTextColor : context.secondaryTextColor,
                              height: 1.3,
                            ),
                            textAlign: isRTL ? TextAlign.right : TextAlign.left,
                            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (subcategory.contentsCount > 0) ...[
                        const SizedBox(height: 6), // More compact spacing
                        Align(
                          alignment: isRTL ? Alignment.centerRight : Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                            children: [
                              Icon(
                                Icons.article_outlined,
                                size: 13,
                                color: context.primaryColor.withOpacity(0.8),
                              ),
                              const SizedBox(width: 4),
                              AppText(
                                '${subcategory.contentsCount} items',
                                style: FontManager.getTextStyle(
                                  languageCode,
                                  fontSize: 11.5,
                                  color: context.primaryColor.withOpacity(0.8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Subcategory model
class Subcategory {
  final int id;
  final String name;
  final String? description;
  final int contentsCount;

  Subcategory({
    required this.id,
    required this.name,
    this.description,
    required this.contentsCount,
  });
}

