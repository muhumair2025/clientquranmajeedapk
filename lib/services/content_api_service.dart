import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../models/category_models.dart';
import '../models/latest_content_models.dart';

/// Service for fetching categories and content from Content Management API
/// Implements local storage caching to support offline viewing
class ContentApiService {
  // Singleton pattern
  static final ContentApiService _instance = ContentApiService._internal();
  factory ContentApiService() => _instance;
  ContentApiService._internal();

  // Dio instance for HTTP requests
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  // Cache keys for SharedPreferences
  static const String _categoriesCacheKey = 'cached_categories';
  static const String _categoriesCacheTimeKey = 'cached_categories_time';
  static const String _latestContentCacheKey = 'cached_latest_content';
  static const String _latestContentCacheTimeKey = 'cached_latest_content_time';

  // Get API configuration from .env.local
  static String get _baseUrl {
    return dotenv.env['BaseUrl'] ?? 'http://localhost:8000/api';
  }

  static String get _apiKey {
    return dotenv.env['HeaderApiKey'] ?? '';
  }

  // HTTP headers with authentication
  Map<String, String> get _headers => {
        'X-API-Key': _apiKey,
        'Content-Type': 'application/json',
      };

  /// Get all categories from API or cache
  /// First tries to load from cache for instant display
  /// Then fetches from API in background and updates cache
  Future<List<ContentCategory>> getCategories({bool forceRefresh = false}) async {
    try {
      // If not forcing refresh, try to get cached data first
      if (!forceRefresh) {
        final cachedCategories = await _getCachedCategories();
        if (cachedCategories != null && cachedCategories.isNotEmpty) {
          debugPrint('✅ Loaded ${cachedCategories.length} categories from cache');
          
          // Fetch fresh data in background to update cache
          _fetchAndCacheCategories().then((freshCategories) {
            if (freshCategories != null && freshCategories.isNotEmpty) {
              debugPrint('✅ Background refresh: Updated cache with ${freshCategories.length} categories');
            }
          }).catchError((e) {
            debugPrint('⚠️ Background refresh failed: $e');
          });
          
          return cachedCategories;
        }
      }

      // No cache or force refresh - fetch from API
      debugPrint('📡 Fetching categories from API...');
      final categories = await _fetchAndCacheCategories();
      
      if (categories != null && categories.isNotEmpty) {
        debugPrint('✅ Fetched ${categories.length} categories from API');
        return categories;
      }

      // If API fails, try cache as fallback
      final cachedCategories = await _getCachedCategories();
      if (cachedCategories != null && cachedCategories.isNotEmpty) {
        debugPrint('⚠️ API failed, using cached data (${cachedCategories.length} categories)');
        return cachedCategories;
      }

      debugPrint('❌ No categories available (API failed and no cache)');
      return [];
    } catch (e) {
      debugPrint('❌ Error in getCategories: $e');
      
      // Try to return cached data as last resort
      final cachedCategories = await _getCachedCategories();
      return cachedCategories ?? [];
    }
  }

  /// Fetch categories from API and update cache
  Future<List<ContentCategory>?> _fetchAndCacheCategories() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/categories',
        options: Options(
          headers: _headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized: Invalid API key');
        return null;
      }

      if (response.statusCode == 200 && response.data != null) {
        final categoriesResponse = CategoriesResponse.fromJson(
          response.data as Map<String, dynamic>,
        );

        if (categoriesResponse.success && categoriesResponse.categories.isNotEmpty) {
          // Download and cache all category icons
          final categoriesWithLocalIcons = <ContentCategory>[];
          for (var category in categoriesResponse.categories) {
            // Construct full icon URL
            final fullIconUrl = _getFullIconUrl(category.iconUrl);
            
            // Download and cache the icon
            final localPath = await _downloadAndCacheIcon(
              fullIconUrl,
              'category_icon_${category.id}',
            );
            
            if (localPath != null) {
              // Create new category with local icon path
              categoriesWithLocalIcons.add(ContentCategory(
                id: category.id,
                names: category.names,
                description: category.description,
                iconUrl: category.iconUrl,
                localIconPath: localPath, // Use local path
                color: category.color,
                subcategoriesCount: category.subcategoriesCount,
              ));
            } else {
              // Keep original URL if download failed (will be empty string)
              categoriesWithLocalIcons.add(ContentCategory(
                id: category.id,
                names: category.names,
                description: category.description,
                iconUrl: category.iconUrl,
                localIconPath: '', // Empty - will trigger fallback behavior
                color: category.color,
                subcategoriesCount: category.subcategoriesCount,
              ));
            }
          }
          
          // Cache the categories with local icon paths
          await _cacheCategories(categoriesWithLocalIcons);
          return categoriesWithLocalIcons;
        } else {
          debugPrint('⚠️ API returned success=false or empty categories');
          return null;
        }
      } else {
        debugPrint('⚠️ API returned status ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          debugPrint('⏱️ Timeout while fetching categories');
          break;
        case DioExceptionType.connectionError:
          debugPrint('🔌 Connection error while fetching categories');
          break;
        default:
          debugPrint('❌ Dio error: ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error fetching categories: $e');
      return null;
    }
  }

  /// Get categories from local cache
  Future<List<ContentCategory>?> _getCachedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_categoriesCacheKey);

      if (cachedJson != null) {
        final List<dynamic> jsonList = json.decode(cachedJson);
        final categories = jsonList
            .map((item) => ContentCategory.fromJson(item as Map<String, dynamic>))
            .toList();
        
        // Verify cached icons still exist
        final validCategories = <ContentCategory>[];
        for (var category in categories) {
          if (category.localIconPath.isNotEmpty && category.localIconPath.startsWith('/')) {
            // It's a local path - verify it exists
            final file = File(category.localIconPath);
            if (await file.exists()) {
              validCategories.add(category);
            } else {
              // Icon file deleted - add with empty local path
              validCategories.add(ContentCategory(
                id: category.id,
                names: category.names,
                description: category.description,
                iconUrl: category.iconUrl,
                localIconPath: '', // Will trigger re-download
                color: category.color,
                subcategoriesCount: category.subcategoriesCount,
              ));
            }
          } else {
            validCategories.add(category);
          }
        }
        return validCategories;
      }
    } catch (e) {
      debugPrint('⚠️ Error reading cache: $e');
    }
    return null;
  }

  /// Save categories to local cache
  Future<void> _cacheCategories(List<ContentCategory> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = categories.map((cat) => cat.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await prefs.setString(_categoriesCacheKey, jsonString);
      await prefs.setInt(
        _categoriesCacheTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint('💾 Cached ${categories.length} categories');
    } catch (e) {
      debugPrint('⚠️ Error caching categories: $e');
    }
  }

  /// Get the last cache update time
  Future<DateTime?> getCacheUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_categoriesCacheTimeKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      debugPrint('⚠️ Error reading cache time: $e');
    }
    return null;
  }

  /// Check if cache exists
  Future<bool> hasCachedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_categoriesCacheKey);
    } catch (e) {
      return false;
    }
  }

  /// Clear categories cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_categoriesCacheKey);
      await prefs.remove(_categoriesCacheTimeKey);

      // Delete cached category icons
      final directory = await getApplicationDocumentsDirectory();
      final iconsDir = Directory('${directory.path}/cached_category_icons');
      if (await iconsDir.exists()) {
        await iconsDir.delete(recursive: true);
        debugPrint('🗑️ Deleted cached category icons');
      }

      debugPrint('🗑️ Categories cache cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing cache: $e');
    }
  }

  /// Refresh categories from API
  /// Only clears cache if we can successfully fetch new data (smart refresh)
  Future<List<ContentCategory>> refreshCategories() async {
    try {
      // Try to fetch fresh data first
      final freshCategories = await _fetchAndCacheCategories();
      
      if (freshCategories != null && freshCategories.isNotEmpty) {
        // Successfully got fresh data - cache is already updated by _fetchAndCacheCategories
        debugPrint('✅ Refresh successful, cache updated with ${freshCategories.length} categories');
        return freshCategories;
      } else {
        // API failed - keep existing cache
        debugPrint('⚠️ Refresh failed, keeping existing cache');
        final cachedCategories = await _getCachedCategories();
        return cachedCategories ?? [];
      }
    } catch (e) {
      // Error occurred - return cached data
      debugPrint('⚠️ Refresh error, keeping existing cache: $e');
      final cachedCategories = await _getCachedCategories();
      return cachedCategories ?? [];
    }
  }

  /// Get category detail with subcategories
  Future<dynamic> getCategoryDetail(int categoryId) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/categories/$categoryId',
        options: Options(
          headers: _headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized: Invalid API key for category $categoryId');
        throw ContentApiException('Unauthorized: Invalid API key', 401);
      }

      if (response.statusCode == 404) {
        debugPrint('❌ Category $categoryId not found');
        throw ContentApiException('Category not found', 404);
      }

      if (response.statusCode == 200 && response.data != null) {
        final jsonData = response.data as Map<String, dynamic>;
        
        if (jsonData['success'] == true && jsonData['data'] != null) {
          debugPrint('✅ Fetched category $categoryId with subcategories');
          return jsonData['data'];
        } else {
          throw ContentApiException('Invalid response format');
        }
      } else {
        throw ContentApiException('Failed to load category: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw ContentApiException('Unauthorized: Check API key', 401);
      } else if (e.response?.statusCode == 404) {
        throw ContentApiException('Category not found', 404);
      } else {
        throw ContentApiException('Network error: ${e.message}');
      }
    } catch (e) {
      if (e is ContentApiException) rethrow;
      throw ContentApiException('Error loading category: $e');
    }
  }

  // ==================== LATEST CONTENT ====================

  /// Get latest content from API or cache
  /// Shows newest categories, subcategories, materials, and ayah audio/video
  Future<List<LatestItem>> getLatestContent({
    bool forceRefresh = false,
    LatestContentFilter? filter,
  }) async {
    try {
      // If not forcing refresh, try to get cached data first
      if (!forceRefresh) {
        final cachedItems = await _getCachedLatestContent();
        if (cachedItems != null && cachedItems.isNotEmpty) {
          debugPrint('✅ Loaded ${cachedItems.length} latest items from cache');
          
          // Fetch fresh data in background to update cache
          _fetchAndCacheLatestContent(filter: filter).then((freshItems) {
            if (freshItems != null && freshItems.isNotEmpty) {
              debugPrint('✅ Background refresh: Updated cache with ${freshItems.length} latest items');
            }
          }).catchError((e) {
            debugPrint('⚠️ Background refresh failed: $e');
          });
          
          return _applyFilter(cachedItems, filter);
        }
      }

      // No cache or force refresh - fetch from API
      debugPrint('📡 Fetching latest content from API...');
      final items = await _fetchAndCacheLatestContent(filter: filter);
      
      if (items != null && items.isNotEmpty) {
        debugPrint('✅ Fetched ${items.length} latest items from API');
        return items;
      }

      // If API fails, try cache as fallback
      final cachedItems = await _getCachedLatestContent();
      if (cachedItems != null && cachedItems.isNotEmpty) {
        debugPrint('⚠️ API failed, using cached data (${cachedItems.length} items)');
        return _applyFilter(cachedItems, filter);
      }

      debugPrint('❌ No latest content available (API failed and no cache)');
      return [];
    } catch (e) {
      debugPrint('❌ Error in getLatestContent: $e');
      
      // Try to return cached data as last resort
      final cachedItems = await _getCachedLatestContent();
      return cachedItems ?? [];
    }
  }

  /// Fetch latest content from API and update cache
  Future<List<LatestItem>?> _fetchAndCacheLatestContent({
    LatestContentFilter? filter,
  }) async {
    try {
      // Build query parameters
      final queryParams = filter?.toQueryParams() ?? {};
      String url = '$_baseUrl/latest';
      if (queryParams.isNotEmpty) {
        final queryString = queryParams.entries
            .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
            .join('&');
        url = '$url?$queryString';
      }

      final response = await _dio.get(
        url,
        options: Options(
          headers: _headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized: Invalid API key for latest content');
        return null;
      }

      if (response.statusCode == 200 && response.data != null) {
        final latestResponse = LatestContentResponse.fromJson(
          response.data as Map<String, dynamic>,
        );

        if (latestResponse.success && latestResponse.items.isNotEmpty) {
          // Sort by created_at descending (newest first)
          final sortedItems = List<LatestItem>.from(latestResponse.items)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          // Cache all items (without filter)
          await _cacheLatestContent(sortedItems);
          return sortedItems;
        } else {
          debugPrint('⚠️ API returned success=false or empty latest items');
          return null;
        }
      } else {
        debugPrint('⚠️ API returned status ${response.statusCode}');
        return null;
      }
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          debugPrint('⏱️ Timeout while fetching latest content');
          break;
        case DioExceptionType.connectionError:
          debugPrint('🔌 Connection error while fetching latest content');
          break;
        default:
          debugPrint('❌ Dio error: ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error fetching latest content: $e');
      return null;
    }
  }

  /// Get latest content from local cache
  Future<List<LatestItem>?> _getCachedLatestContent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_latestContentCacheKey);

      if (cachedJson != null) {
        final List<dynamic> jsonList = json.decode(cachedJson);
        final items = jsonList
            .map((item) => LatestItem.fromJson(item as Map<String, dynamic>))
            .toList();
        return items;
      }
    } catch (e) {
      debugPrint('⚠️ Error reading latest content cache: $e');
    }
    return null;
  }

  /// Save latest content to local cache
  Future<void> _cacheLatestContent(List<LatestItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((item) => item.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await prefs.setString(_latestContentCacheKey, jsonString);
      await prefs.setInt(
        _latestContentCacheTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint('💾 Cached ${items.length} latest content items');
    } catch (e) {
      debugPrint('⚠️ Error caching latest content: $e');
    }
  }

  /// Apply filter to latest items
  List<LatestItem> _applyFilter(List<LatestItem> items, LatestContentFilter? filter) {
    if (filter == null) return items;
    
    var filtered = items.toList();
    
    // Filter by types
    if (filter.types.isNotEmpty) {
      filtered = filtered.where((item) => filter.types.contains(item.type)).toList();
    }
    
    // Apply limit
    if (filter.limit != null && filter.limit! > 0) {
      final offset = filter.offset ?? 0;
      final end = (offset + filter.limit!).clamp(0, filtered.length);
      filtered = filtered.sublist(offset.clamp(0, filtered.length), end);
    }
    
    return filtered;
  }

  /// Refresh latest content from API
  Future<List<LatestItem>> refreshLatestContent({LatestContentFilter? filter}) async {
    try {
      final freshItems = await _fetchAndCacheLatestContent(filter: filter);
      
      if (freshItems != null && freshItems.isNotEmpty) {
        debugPrint('✅ Refresh successful, cache updated with ${freshItems.length} latest items');
        return freshItems;
      } else {
        debugPrint('⚠️ Refresh failed, keeping existing cache');
        final cachedItems = await _getCachedLatestContent();
        return _applyFilter(cachedItems ?? [], filter);
      }
    } catch (e) {
      debugPrint('⚠️ Refresh error, keeping existing cache: $e');
      final cachedItems = await _getCachedLatestContent();
      return _applyFilter(cachedItems ?? [], filter);
    }
  }

  /// Clear latest content cache
  Future<void> clearLatestContentCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_latestContentCacheKey);
      await prefs.remove(_latestContentCacheTimeKey);
      debugPrint('🗑️ Latest content cache cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing latest content cache: $e');
    }
  }

  /// Get the last cache update time for latest content
  Future<DateTime?> getLatestContentCacheTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_latestContentCacheTimeKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      debugPrint('⚠️ Error reading latest content cache time: $e');
    }
    return null;
  }

  // ==================== ICON CACHING ====================

  /// Download category icon and save to local storage
  /// Returns local file path or null if failed
  Future<String?> _downloadAndCacheIcon(String iconUrl, String fileName) async {
    try {
      if (iconUrl.isEmpty) {
        debugPrint('⚠️ Empty icon URL for $fileName');
        return null;
      }

      // Get app's local directory
      final directory = await getApplicationDocumentsDirectory();
      final iconsDir = Directory('${directory.path}/cached_category_icons');

      // Create directory if it doesn't exist
      if (!await iconsDir.exists()) {
        await iconsDir.create(recursive: true);
      }

      // Generate unique filename using URL hash
      final urlHash = md5.convert(utf8.encode(iconUrl)).toString();
      final extension = _getImageExtension(iconUrl);
      final localPath = '${iconsDir.path}/${fileName}_$urlHash$extension';

      final file = File(localPath);

      // Check if file already exists
      if (await file.exists()) {
        debugPrint('📁 Icon already cached: $fileName');
        return localPath;
      }

      // Download the icon
      debugPrint('⬇️ Downloading icon: $fileName from $iconUrl');
      final response = await _dio.get(
        iconUrl,
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        await file.writeAsBytes(response.data);
        debugPrint('✅ Icon cached: $fileName');
        return localPath;
      } else {
        debugPrint('❌ Failed to download icon: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error caching icon $fileName: $e');
      return null;
    }
  }

  /// Extract image extension from URL
  String _getImageExtension(String url) {
    final uri = Uri.parse(url);
    final path = uri.path.toLowerCase();

    if (path.endsWith('.png')) return '.png';
    if (path.endsWith('.jpg')) return '.jpg';
    if (path.endsWith('.jpeg')) return '.jpeg';
    if (path.endsWith('.webp')) return '.webp';
    if (path.endsWith('.gif')) return '.gif';
    if (path.endsWith('.svg')) return '.svg';

    return '.png'; // Default to PNG
  }

  /// Construct full icon URL from relative path
  /// API returns: "/storage/icons/filename.png"
  /// We need: "https://quranxmlmaker.ssatechs.com/storage/icons/filename.png"
  String _getFullIconUrl(String iconPath) {
    if (iconPath.isEmpty) return '';
    
    // If already a full URL, return as is
    if (iconPath.startsWith('http://') || iconPath.startsWith('https://')) {
      return iconPath;
    }
    
    // Remove leading slash if present
    final cleanPath = iconPath.startsWith('/') ? iconPath.substring(1) : iconPath;
    
    // Construct full URL
    return 'https://quranxmlmaker.ssatechs.com/$cleanPath';
  }
}

/// Custom exception for API errors
class ContentApiException implements Exception {
  final String message;
  final int? statusCode;

  ContentApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

