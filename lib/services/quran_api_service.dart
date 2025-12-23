import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class QuranApiService {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  static const String baseUrl = 'https://quranxmlmaker.ssatechs.com/api';
  
  // Cache for API responses to avoid repeated calls (nullable for 404s)
  static final Map<String, Map<String, dynamic>?> _cache = {};
  
  /// Get specific section data for an ayah
  /// Returns null if API call fails or data is not available
  static Future<SectionData?> getSectionData(int surah, int ayah, String section) async {
    final cacheKey = '${surah}_${ayah}_$section';
    
    // Return cached data if available (including null for 404s)
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey];
      return cached != null ? SectionData.fromJson(cached) : null;
    }
    
    try {
      final response = await _dio.get(
        '$baseUrl/ayah/$surah/$ayah/$section',
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        // Validate response structure
        if (data['success'] == true) {
          // Cache the response
          _cache[cacheKey] = data;
          return SectionData.fromJson(data);
        } else {
          // Cache negative result to prevent repeated checks
          _cache[cacheKey] = null;
          debugPrint('API returned success=false for $surah:$ayah:$section');
        }
      } else if (response.statusCode == 404) {
        // Cache 404 as null to prevent repeated failed requests
        _cache[cacheKey] = null;
        // debugPrint('No data found for $surah:$ayah:$section (404) - cached');
      } else {
        debugPrint('API returned status ${response.statusCode} for $surah:$ayah:$section');
      }
    } catch (e) {
      // Cache failures to prevent repeated attempts for the same ayah
      _cache[cacheKey] = null;
      
      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
          case DioExceptionType.receiveTimeout:
            debugPrint('Timeout for $surah:$ayah:$section - cached as unavailable');
            break;
          case DioExceptionType.connectionError:
            debugPrint('Connection error for $surah:$ayah:$section - cached as unavailable');
            break;
          default:
            debugPrint('Dio error for $surah:$ayah:$section - ${e.message}');
        }
      } else {
        debugPrint('Error for $surah:$ayah:$section - $e');
      }
    }
    
    return null;
  }
  
  /// Get all sections data for an ayah
  /// Returns a map with lughat, tafseer, and faidi data
  static Future<Map<String, SectionData?>> getAllSectionsData(int surah, int ayah) async {
    final cacheKey = '${surah}_${ayah}_all';
    
    try {
      final response = await _dio.get('$baseUrl/ayah/$surah/$ayah');
      
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        
        Map<String, SectionData?> result = {};
        
        // Parse each section
        for (String section in ['lughat', 'tafseer', 'faidi']) {
          if (data.containsKey(section) && data[section] != null) {
            final sectionData = data[section] as Map<String, dynamic>;
            result[section] = SectionData.fromJson(sectionData);
            
            // Cache individual sections too
            _cache['${surah}_${ayah}_$section'] = sectionData;
          } else {
            result[section] = null;
          }
        }
        
        return result;
      }
    } catch (e) {
      debugPrint('Error fetching all sections data for $surah:$ayah - $e');
    }
    
    return {
      'lughat': null,
      'tafseer': null,
      'faidi': null,
    };
  }
  
  /// Check if a specific section has audio data available
  static Future<bool> hasAudioData(int surah, int ayah, String section) async {
    final sectionData = await getSectionData(surah, ayah, section);
    return sectionData?.audioUrl != null;
  }
  
  /// Check if a specific section has video data available
  static Future<bool> hasVideoData(int surah, int ayah, String section) async {
    final sectionData = await getSectionData(surah, ayah, section);
    return sectionData?.videoUrl != null;
  }
  
  /// Get audio URL for a specific section
  static Future<String?> getAudioUrl(int surah, int ayah, String section) async {
    final sectionData = await getSectionData(surah, ayah, section);
    return sectionData?.audioUrl;
  }
  
  /// Get video URL for a specific section
  static Future<String?> getVideoUrl(int surah, int ayah, String section) async {
    final sectionData = await getSectionData(surah, ayah, section);
    return sectionData?.videoUrl;
  }
  
  /// Clear cache for a specific ayah (useful for refreshing data)
  static void clearCacheForAyah(int surah, int ayah) {
    final keysToRemove = _cache.keys.where((key) => key.startsWith('${surah}_$ayah')).toList();
    for (String key in keysToRemove) {
      _cache.remove(key);
    }
  }
  
  /// Clear all cache
  static void clearAllCache() {
    _cache.clear();
  }
  
  /// Refresh data for a specific ayah (clears cache and fetches fresh data)
  static Future<Map<String, SectionData?>> refreshAyahData(int surah, int ayah) async {
    clearCacheForAyah(surah, ayah);
    return await getAllSectionsData(surah, ayah);
  }
  
  /// Check if we have cached data for an ayah
  static bool hasCachedData(int surah, int ayah, String section) {
    final cacheKey = '${surah}_${ayah}_$section';
    return _cache.containsKey(cacheKey);
  }
}

class SectionData {
  final bool success;
  final String sectionName;
  final String sectionKey;
  final String surah;
  final String ayah;
  final SurahInfo surahInfo;
  final String? audioUrl;
  final String? videoUrl;
  
  SectionData({
    required this.success,
    required this.sectionName,
    required this.sectionKey,
    required this.surah,
    required this.ayah,
    required this.surahInfo,
    this.audioUrl,
    this.videoUrl,
  });
  
  factory SectionData.fromJson(Map<String, dynamic> json) {
    return SectionData(
      success: json['success'] ?? false,
      sectionName: json['section_name'] ?? '',
      sectionKey: json['section_key'] ?? '',
      surah: json['surah']?.toString() ?? '',
      ayah: json['ayah']?.toString() ?? '',
      surahInfo: SurahInfo.fromJson(json['surah_info'] ?? {}),
      audioUrl: json['audio_url'],
      videoUrl: json['video_url'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'section_name': sectionName,
      'section_key': sectionKey,
      'surah': surah,
      'ayah': ayah,
      'surah_info': surahInfo.toJson(),
      'audio_url': audioUrl,
      'video_url': videoUrl,
    };
  }
}

class SurahInfo {
  final String nameArabic;
  final String namePashto;
  final int totalAyahs;
  
  SurahInfo({
    required this.nameArabic,
    required this.namePashto,
    required this.totalAyahs,
  });
  
  factory SurahInfo.fromJson(Map<String, dynamic> json) {
    return SurahInfo(
      nameArabic: json['name_arabic'] ?? '',
      namePashto: json['name_pashto'] ?? '',
      totalAyahs: json['total_ayahs'] ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name_arabic': nameArabic,
      'name_pashto': namePashto,
      'total_ayahs': totalAyahs,
    };
  }
}
