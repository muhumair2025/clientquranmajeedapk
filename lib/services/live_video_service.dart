import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/live_video_models.dart';

/// Service for fetching Live Videos from API
/// Implements local storage caching - keeps cache, only refreshes with internet
class LiveVideoService {
  // Singleton pattern
  static final LiveVideoService _instance = LiveVideoService._internal();
  factory LiveVideoService() => _instance;
  LiveVideoService._internal();

  // Dio instance for HTTP requests
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  // Cache keys for SharedPreferences
  static const String _liveVideosCacheKey = 'cached_live_videos';
  static const String _liveVideosCacheTimeKey = 'cached_live_videos_time';

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

  /// Get live videos with smart caching
  /// - Always returns cached data first (instant load)
  /// - Fetches fresh data in background if internet available
  /// - NEVER clears cache on refresh failure
  Future<List<LiveVideo>> getLiveVideos({bool forceRefresh = false}) async {
    try {
      // Always try to get cached data first for instant display
      if (!forceRefresh) {
        final cachedVideos = await _getCachedLiveVideos();
        if (cachedVideos != null && cachedVideos.isNotEmpty) {
          debugPrint('✅ Loaded ${cachedVideos.length} live videos from cache');

          // Fetch fresh data in background (don't wait)
          _fetchAndCacheLiveVideos().then((freshVideos) {
            if (freshVideos != null && freshVideos.isNotEmpty) {
              debugPrint(
                  '✅ Background refresh: Updated cache with ${freshVideos.length} live videos');
            }
          }).catchError((e) {
            debugPrint('⚠️ Background refresh failed (keeping cache): $e');
          });

          return cachedVideos;
        }
      }

      // No cache or force refresh - fetch from API
      debugPrint('📡 Fetching live videos from API...');
      final videos = await _fetchAndCacheLiveVideos();

      if (videos != null && videos.isNotEmpty) {
        debugPrint('✅ Fetched ${videos.length} live videos from API');
        return videos;
      }

      // If API fails, try cache as fallback
      final cachedVideos = await _getCachedLiveVideos();
      if (cachedVideos != null && cachedVideos.isNotEmpty) {
        debugPrint(
            '⚠️ API failed, using cached data (${cachedVideos.length} videos)');
        return cachedVideos;
      }

      debugPrint('❌ No live videos available (API failed and no cache)');
      return [];
    } catch (e) {
      debugPrint('❌ Error in getLiveVideos: $e');

      // Always try to return cached data as last resort
      final cachedVideos = await _getCachedLiveVideos();
      return cachedVideos ?? [];
    }
  }

  /// Fetch live videos from API and cache them
  Future<List<LiveVideo>?> _fetchAndCacheLiveVideos() async {
    try {
      final response = await _dio.get(
        '$_baseUrl/live-videos',
        options: Options(
          headers: _headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 401) {
        debugPrint('❌ Unauthorized: Invalid API key for live videos');
        return null;
      }

      if (response.statusCode == 200 && response.data != null) {
        final videosResponse = LiveVideosResponse.fromJson(
          response.data as Map<String, dynamic>,
        );

        if (videosResponse.success) {
          // Sort by order (API already filters active videos)
          final sortedVideos = videosResponse.videos.toList()
            ..sort((a, b) => a.order.compareTo(b.order));

          // Cache the videos (even if empty, to avoid repeated failed API calls)
          await _cacheLiveVideos(sortedVideos);
          return sortedVideos;
        } else {
          debugPrint('⚠️ API returned success=false');
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
          debugPrint('⏱️ Timeout while fetching live videos');
          break;
        case DioExceptionType.connectionError:
          debugPrint('🔌 Connection error while fetching live videos');
          break;
        default:
          debugPrint('❌ Dio error: ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('❌ Unexpected error fetching live videos: $e');
      return null;
    }
  }

  /// Get live videos from local cache
  Future<List<LiveVideo>?> _getCachedLiveVideos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_liveVideosCacheKey);

      if (cachedJson != null) {
        final List<dynamic> jsonList = json.decode(cachedJson);
        final videos = jsonList
            .map((item) => LiveVideo.fromJson(item as Map<String, dynamic>))
            .toList();
        return videos;
      }
    } catch (e) {
      debugPrint('⚠️ Error reading live videos cache: $e');
    }
    return null;
  }

  /// Save live videos to local cache
  Future<void> _cacheLiveVideos(List<LiveVideo> videos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = videos.map((video) => video.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await prefs.setString(_liveVideosCacheKey, jsonString);
      await prefs.setInt(
        _liveVideosCacheTimeKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      debugPrint('💾 Cached ${videos.length} live videos');
    } catch (e) {
      debugPrint('⚠️ Error caching live videos: $e');
    }
  }

  /// Check if live videos are cached
  Future<bool> hasLiveVideosCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_liveVideosCacheKey);
    } catch (e) {
      return false;
    }
  }

  /// Get cache update time
  Future<DateTime?> getCacheUpdateTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_liveVideosCacheTimeKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      debugPrint('⚠️ Error reading cache time: $e');
    }
    return null;
  }

  /// Clear live videos cache (use sparingly)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_liveVideosCacheKey);
      await prefs.remove(_liveVideosCacheTimeKey);
      debugPrint('🗑️ Live videos cache cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing cache: $e');
    }
  }

  /// Initialize and pre-fetch live videos at app startup
  static Future<void> initialize() async {
    try {
      debugPrint('🚀 Initializing LiveVideoService...');
      final service = LiveVideoService();

      // Pre-fetch live videos in background
      service.getLiveVideos().then((_) {
        debugPrint('✅ Live videos pre-fetched');
      }).catchError((e) {
        debugPrint('⚠️ Live videos pre-fetch failed: $e');
      });

      debugPrint('✅ LiveVideoService initialized');
    } catch (e) {
      debugPrint('⚠️ LiveVideoService initialization error: $e');
    }
  }
}

