import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../models/app_content_models.dart';

/// Service for fetching Hero Slides and Splash Screen from API
/// Implements local storage caching for images to avoid repeated downloads
class AppContentService {
  // Singleton pattern
  static final AppContentService _instance = AppContentService._internal();
  factory AppContentService() => _instance;
  AppContentService._internal();

  // Dio instance for HTTP requests
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  // Cache keys for SharedPreferences
  static const String _heroSlidesCacheKey = 'cached_hero_slides';
  static const String _heroSlidesCacheTimeKey = 'cached_hero_slides_time';
  static const String _splashScreenCacheKey = 'cached_splash_screen';
  static const String _splashScreenCacheTimeKey = 'cached_splash_screen_time';

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

  // ==================== HERO SLIDES ====================

  /// Get hero slides with cached images
  /// Returns list of slides with local image paths
  Future<List<HeroSlide>> getHeroSlides({bool forceRefresh = false}) async {
    try {
      // If not forcing refresh, try to get cached data first
      if (!forceRefresh) {
        final cachedSlides = await _getCachedHeroSlides();
        if (cachedSlides != null && cachedSlides.isNotEmpty) {
          debugPrint('✅ Loaded ${cachedSlides.length} hero slides from cache');

          // Fetch fresh data in background to update cache
          _fetchAndCacheHeroSlides().then((freshSlides) {
            if (freshSlides != null && freshSlides.isNotEmpty) {
              debugPrint(
                  '✅ Background refresh: Updated cache with ${freshSlides.length} hero slides');
            }
          }).catchError((e) {
            debugPrint('⚠️ Background refresh failed: $e');
          });

          return cachedSlides;
        }
      }

      // No cache or force refresh - fetch from API
      debugPrint('📡 Fetching hero slides from API...');
      final slides = await _fetchAndCacheHeroSlides();

      if (slides != null && slides.isNotEmpty) {
        debugPrint('✅ Fetched ${slides.length} hero slides from API');
        return slides;
      }

      // If API fails, try cache as fallback
      final cachedSlides = await _getCachedHeroSlides();
      if (cachedSlides != null && cachedSlides.isNotEmpty) {
        debugPrint(
            '⚠️ API failed, using cached data (${cachedSlides.length} slides)');
        return cachedSlides;
      }

      debugPrint('❌ No hero slides available (API failed and no cache)');
      return [];
    } catch (e) {
      debugPrint('❌ Error in getHeroSlides: $e');

      // Try to return cached data as last resort
      final cachedSlides = await _getCachedHeroSlides();
      return cachedSlides ?? [];
    }
  }

  /// Fetch hero slides from API and cache images locally
  Future<List<HeroSlide>?> _fetchAndCacheHeroSlides() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/hero-slides',
        options: Options(
          headers: _headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized: Invalid API key for hero slides');
        return null;
      }

      if (response.statusCode == 200 && response.data != null) {
        final slidesResponse = HeroSlidesResponse.fromJson(
          response.data as Map<String, dynamic>,
        );

        if (slidesResponse.success && slidesResponse.slides.isNotEmpty) {
          // Download and cache all images
          final slidesWithLocalImages = <HeroSlide>[];
          for (var slide in slidesResponse.slides) {
            final localPath = await _downloadAndCacheImage(
              slide.imageDownloadUrl,
              'hero_slide_${slide.id}',
            );
            if (localPath != null) {
              // Create new slide with local image path
              slidesWithLocalImages.add(HeroSlide(
                id: slide.id,
                title: slide.title,
                description: slide.description,
                imageUrl: slide.imageUrl,
                imageDownloadUrl: localPath, // Use local path instead
                buttonText: slide.buttonText,
                buttonLink: slide.buttonLink,
                order: slide.order,
              ));
            } else {
              // Keep original URL if download failed
              slidesWithLocalImages.add(slide);
            }
          }

          // Cache the slides metadata
          await _cacheHeroSlides(slidesWithLocalImages);
          return slidesWithLocalImages;
        } else {
          debugPrint('⚠️ API returned success=false or empty hero slides');
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
          debugPrint('⏱️ Timeout while fetching hero slides');
          break;
        case DioExceptionType.connectionError:
          debugPrint('🔌 Connection error while fetching hero slides');
          break;
        default:
          debugPrint('❌ Dio error: ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error fetching hero slides: $e');
      return null;
    }
  }

  /// Get hero slides from local cache
  Future<List<HeroSlide>?> _getCachedHeroSlides() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_heroSlidesCacheKey);

      if (cachedJson != null) {
        final List<dynamic> jsonList = json.decode(cachedJson);
        final slides = jsonList
            .map((item) => HeroSlide.fromJson(item as Map<String, dynamic>))
            .toList();

        // Verify cached images still exist
        final validSlides = <HeroSlide>[];
        for (var slide in slides) {
          if (slide.imageDownloadUrl.startsWith('/')) {
            // It's a local path
            final file = File(slide.imageDownloadUrl);
            if (await file.exists()) {
              validSlides.add(slide);
            }
          } else {
            validSlides.add(slide);
          }
        }
        return validSlides;
      }
    } catch (e) {
      debugPrint('⚠️ Error reading hero slides cache: $e');
    }
    return null;
  }

  /// Save hero slides metadata to local cache
  Future<void> _cacheHeroSlides(List<HeroSlide> slides) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = slides.map((slide) => slide.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await prefs.setString(_heroSlidesCacheKey, jsonString);
      await prefs.setInt(
        _heroSlidesCacheTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint('💾 Cached ${slides.length} hero slides');
    } catch (e) {
      debugPrint('⚠️ Error caching hero slides: $e');
    }
  }

  // ==================== SPLASH SCREEN ====================

  /// Get splash screen data with cached image
  /// Returns splash data with local image path
  Future<SplashScreenData?> getSplashScreen({bool forceRefresh = false}) async {
    try {
      // If not forcing refresh, try to get cached data first
      if (!forceRefresh) {
        final cachedSplash = await _getCachedSplashScreen();
        if (cachedSplash != null && cachedSplash.hasSplashScreen) {
          debugPrint('✅ Loaded splash screen from cache');

          // Fetch fresh data in background to update cache
          _fetchAndCacheSplashScreen().catchError((e) {
            debugPrint('⚠️ Background splash refresh failed: $e');
          });

          return cachedSplash;
        }
      }

      // No cache or force refresh - fetch from API
      debugPrint('📡 Fetching splash screen from API...');
      final splash = await _fetchAndCacheSplashScreen();

      if (splash != null) {
        debugPrint('✅ Fetched splash screen from API');
        return splash;
      }

      // If API fails, try cache as fallback
      final cachedSplash = await _getCachedSplashScreen();
      if (cachedSplash != null) {
        debugPrint('⚠️ API failed, using cached splash screen');
        return cachedSplash;
      }

      debugPrint('❌ No splash screen available');
      return null;
    } catch (e) {
      debugPrint('❌ Error in getSplashScreen: $e');
      return await _getCachedSplashScreen();
    }
  }

  /// Fetch splash screen from API and cache image locally
  Future<SplashScreenData?> _fetchAndCacheSplashScreen() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/splash-screen',
        options: Options(
          headers: _headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized: Invalid API key for splash screen');
        return null;
      }

      if (response.statusCode == 200 && response.data != null) {
        final splashResponse = SplashScreenResponse.fromJson(
          response.data as Map<String, dynamic>,
        );

        if (splashResponse.success) {
          final splashData = splashResponse.data;

          if (splashData.hasSplashScreen &&
              splashData.imageDownloadUrl != null) {
            // Download and cache the splash image
            final localPath = await _downloadAndCacheImage(
              splashData.imageDownloadUrl!,
              'splash_screen',
            );

            final cachedSplash = SplashScreenData(
              hasSplashScreen: true,
              imageUrl: splashData.imageUrl,
              imageDownloadUrl: localPath ?? splashData.imageDownloadUrl,
            );

            // Cache the splash data
            await _cacheSplashScreen(cachedSplash);
            return cachedSplash;
          } else {
            // No splash screen set
            final noSplash = SplashScreenData(
              hasSplashScreen: false,
              imageUrl: null,
              imageDownloadUrl: null,
            );
            await _cacheSplashScreen(noSplash);
            return noSplash;
          }
        }
      }
      return null;
    } on DioException catch (e) {
      debugPrint('❌ Dio error fetching splash: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching splash screen: $e');
      return null;
    }
  }

  /// Get splash screen from local cache
  Future<SplashScreenData?> _getCachedSplashScreen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_splashScreenCacheKey);

      if (cachedJson != null) {
        final jsonData = json.decode(cachedJson) as Map<String, dynamic>;
        final splash = SplashScreenData.fromJson(jsonData);

        // Verify cached image still exists
        if (splash.hasSplashScreen && splash.imageDownloadUrl != null) {
          if (splash.imageDownloadUrl!.startsWith('/')) {
            final file = File(splash.imageDownloadUrl!);
            if (await file.exists()) {
              return splash;
            } else {
              return null; // Image deleted, need to re-fetch
            }
          }
        }
        return splash;
      }
    } catch (e) {
      debugPrint('⚠️ Error reading splash screen cache: $e');
    }
    return null;
  }

  /// Save splash screen data to local cache
  Future<void> _cacheSplashScreen(SplashScreenData splash) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(splash.toJson());

      await prefs.setString(_splashScreenCacheKey, jsonString);
      await prefs.setInt(
        _splashScreenCacheTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint('💾 Cached splash screen');
    } catch (e) {
      debugPrint('⚠️ Error caching splash screen: $e');
    }
  }

  // ==================== IMAGE CACHING ====================

  /// Download image and save to local storage
  /// Returns local file path or null if failed
  Future<String?> _downloadAndCacheImage(
      String imageUrl, String fileName) async {
    try {
      // Get app's local directory
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/cached_images');

      // Create directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Generate unique filename using URL hash
      final urlHash = md5.convert(utf8.encode(imageUrl)).toString();
      final extension = _getImageExtension(imageUrl);
      final localPath = '${imagesDir.path}/${fileName}_$urlHash$extension';

      final file = File(localPath);

      // Check if file already exists
      if (await file.exists()) {
        debugPrint('📁 Image already cached: $fileName');
        return localPath;
      }

      // Download the image
      debugPrint('⬇️ Downloading image: $fileName');
      final response = await _dio.get(
        imageUrl,
        options: Options(
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        await file.writeAsBytes(response.data);
        debugPrint('✅ Image cached: $fileName');
        return localPath;
      } else {
        debugPrint('❌ Failed to download image: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error caching image: $e');
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

    return '.jpg'; // Default
  }

  /// Get local image path if cached, otherwise return network URL
  Future<String> getImagePath(String imageUrl, String cacheKey) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final urlHash = md5.convert(utf8.encode(imageUrl)).toString();
      final extension = _getImageExtension(imageUrl);
      final localPath =
          '${directory.path}/cached_images/${cacheKey}_$urlHash$extension';

      final file = File(localPath);
      if (await file.exists()) {
        return localPath;
      }
    } catch (e) {
      debugPrint('⚠️ Error checking cached image: $e');
    }
    return imageUrl;
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Check if hero slides are cached
  Future<bool> hasHeroSlidesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_heroSlidesCacheKey);
    } catch (e) {
      return false;
    }
  }

  /// Check if splash screen is cached
  Future<bool> hasSplashScreenCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_splashScreenCacheKey);
    } catch (e) {
      return false;
    }
  }

  /// Clear all cached content
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_heroSlidesCacheKey);
      await prefs.remove(_heroSlidesCacheTimeKey);
      await prefs.remove(_splashScreenCacheKey);
      await prefs.remove(_splashScreenCacheTimeKey);

      // Delete cached images
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/cached_images');
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }

      debugPrint('🗑️ All app content cache cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing cache: $e');
    }
  }

  /// Initialize and pre-fetch content at app startup
  static Future<void> initialize() async {
    try {
      debugPrint('🚀 Initializing AppContentService...');
      final service = AppContentService();

      // Pre-fetch splash screen (important for first launch experience)
      await service.getSplashScreen();

      // Pre-fetch hero slides in background
      service.getHeroSlides().then((_) {
        debugPrint('✅ Hero slides pre-fetched');
      }).catchError((e) {
        debugPrint('⚠️ Hero slides pre-fetch failed: $e');
      });

      debugPrint('✅ AppContentService initialized');
    } catch (e) {
      debugPrint('⚠️ AppContentService initialization error: $e');
    }
  }
}

