import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import '../models/content_models.dart';

/// Service for downloading and managing content files (PDF, Audio, Video)
/// Files are stored in app's internal storage (not user-visible)
class ContentStorageService {
  // Singleton pattern
  static final ContentStorageService _instance = ContentStorageService._internal();
  factory ContentStorageService() => _instance;
  ContentStorageService._internal();

  // Dio instance for downloads
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );

  // Cache keys
  static const String _downloadedContentKey = 'downloaded_content_files';
  
  // Active downloads tracking
  final Map<int, CancelToken> _activeDownloads = {};
  final Map<int, double> _downloadProgress = {};

  /// Get app's internal storage directory for content
  Future<Directory> _getContentDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final contentDir = Directory('${appDir.path}/content_downloads');
    
    if (!await contentDir.exists()) {
      await contentDir.create(recursive: true);
    }
    
    return contentDir;
  }

  /// Get subdirectory for specific content type
  Future<Directory> _getTypeDirectory(ContentType type) async {
    final contentDir = await _getContentDirectory();
    String subDir;
    
    switch (type) {
      case ContentType.pdf:
        subDir = 'pdfs';
        break;
      case ContentType.audio:
        subDir = 'audio';
        break;
      case ContentType.video:
        subDir = 'video';
        break;
      default:
        subDir = 'other';
    }
    
    final typeDir = Directory('${contentDir.path}/$subDir');
    if (!await typeDir.exists()) {
      await typeDir.create(recursive: true);
    }
    
    return typeDir;
  }

  /// Generate unique filename for content
  String _generateFilename(int contentId, String url, ContentType type) {
    final urlHash = md5.convert(utf8.encode(url)).toString().substring(0, 8);
    String extension;
    
    switch (type) {
      case ContentType.pdf:
        extension = '.pdf';
        break;
      case ContentType.audio:
        // Extract extension from URL or default to mp3
        if (url.contains('.m4a')) {
          extension = '.m4a';
        } else if (url.contains('.wav')) {
          extension = '.wav';
        } else {
          extension = '.mp3';
        }
        break;
      case ContentType.video:
        // Extract extension from URL or default to mp4
        if (url.contains('.m3u8')) {
          extension = '.m3u8';
        } else if (url.contains('.webm')) {
          extension = '.webm';
        } else {
          extension = '.mp4';
        }
        break;
      default:
        extension = '';
    }
    
    return 'content_${contentId}_$urlHash$extension';
  }

  /// Download content file and save to app storage
  /// Returns local file path on success
  Future<String> downloadContent(
    ContentItem content, {
    Function(double)? onProgress,
    Function(String)? onError,
  }) async {
    final url = content.mediaUrl;
    if (url == null || url.isEmpty) {
      throw Exception('No download URL available');
    }

    try {
      debugPrint('⬇️ Starting download for content ${content.id}: ${content.title}');
      
      // Get directory for this content type
      final typeDir = await _getTypeDirectory(content.type);
      final filename = _generateFilename(content.id, url, content.type);
      final localPath = '${typeDir.path}/$filename';
      final file = File(localPath);
      
      // Check if already downloaded
      if (await file.exists()) {
        debugPrint('📁 Content already downloaded: $localPath');
        return localPath;
      }
      
      // Create cancel token for this download
      final cancelToken = CancelToken();
      _activeDownloads[content.id] = cancelToken;
      _downloadProgress[content.id] = 0.0;
      
      // Download file
      await _dio.download(
        url,
        localPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            _downloadProgress[content.id] = progress;
            onProgress?.call(progress);
          }
        },
      );
      
      // Remove from active downloads
      _activeDownloads.remove(content.id);
      _downloadProgress.remove(content.id);
      
      // Save to downloaded content registry
      await _saveDownloadedContent(content.id, localPath);
      
      debugPrint('✅ Download complete: $localPath');
      return localPath;
      
    } on DioException catch (e) {
      _activeDownloads.remove(content.id);
      _downloadProgress.remove(content.id);
      
      if (e.type == DioExceptionType.cancel) {
        debugPrint('⚠️ Download cancelled for content ${content.id}');
        onError?.call('Download cancelled');
        throw Exception('Download cancelled');
      }
      
      debugPrint('❌ Download error: ${e.message}');
      onError?.call(e.message ?? 'Download failed');
      throw Exception('Download failed: ${e.message}');
      
    } catch (e) {
      _activeDownloads.remove(content.id);
      _downloadProgress.remove(content.id);
      debugPrint('❌ Download error: $e');
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Cancel an active download
  void cancelDownload(int contentId) {
    final cancelToken = _activeDownloads[contentId];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('User cancelled');
      _activeDownloads.remove(contentId);
      _downloadProgress.remove(contentId);
      debugPrint('🚫 Download cancelled for content $contentId');
    }
  }

  /// Get download progress for content (0.0 - 1.0)
  double getDownloadProgress(int contentId) {
    return _downloadProgress[contentId] ?? 0.0;
  }

  /// Check if download is in progress
  bool isDownloading(int contentId) {
    return _activeDownloads.containsKey(contentId);
  }

  /// Check if content is downloaded
  Future<bool> isContentDownloaded(int contentId) async {
    final localPath = await getLocalPath(contentId);
    if (localPath == null) return false;
    
    final file = File(localPath);
    return await file.exists();
  }

  /// Get local file path for downloaded content
  Future<String?> getLocalPath(int contentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadedJson = prefs.getString(_downloadedContentKey);
      
      if (downloadedJson != null) {
        final Map<String, dynamic> downloaded = json.decode(downloadedJson);
        return downloaded[contentId.toString()] as String?;
      }
    } catch (e) {
      debugPrint('⚠️ Error reading downloaded content: $e');
    }
    return null;
  }

  /// Save downloaded content path to registry
  Future<void> _saveDownloadedContent(int contentId, String localPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadedJson = prefs.getString(_downloadedContentKey);
      
      Map<String, dynamic> downloaded = {};
      if (downloadedJson != null) {
        downloaded = json.decode(downloadedJson);
      }
      
      downloaded[contentId.toString()] = localPath;
      await prefs.setString(_downloadedContentKey, json.encode(downloaded));
      
      debugPrint('💾 Saved download record for content $contentId');
    } catch (e) {
      debugPrint('⚠️ Error saving download record: $e');
    }
  }

  /// Delete downloaded content
  Future<bool> deleteContent(int contentId) async {
    try {
      final localPath = await getLocalPath(contentId);
      
      if (localPath != null) {
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
          debugPrint('🗑️ Deleted content file: $localPath');
        }
      }
      
      // Remove from registry
      final prefs = await SharedPreferences.getInstance();
      final downloadedJson = prefs.getString(_downloadedContentKey);
      
      if (downloadedJson != null) {
        final Map<String, dynamic> downloaded = json.decode(downloadedJson);
        downloaded.remove(contentId.toString());
        await prefs.setString(_downloadedContentKey, json.encode(downloaded));
      }
      
      return true;
    } catch (e) {
      debugPrint('⚠️ Error deleting content: $e');
      return false;
    }
  }

  /// Get all downloaded content IDs
  Future<List<int>> getDownloadedContentIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadedJson = prefs.getString(_downloadedContentKey);
      
      if (downloadedJson != null) {
        final Map<String, dynamic> downloaded = json.decode(downloadedJson);
        return downloaded.keys.map((k) => int.parse(k)).toList();
      }
    } catch (e) {
      debugPrint('⚠️ Error reading downloaded content IDs: $e');
    }
    return [];
  }

  /// Get total size of downloaded content
  Future<int> getTotalDownloadedSize() async {
    int totalSize = 0;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadedJson = prefs.getString(_downloadedContentKey);
      
      if (downloadedJson != null) {
        final Map<String, dynamic> downloaded = json.decode(downloadedJson);
        
        for (final path in downloaded.values) {
          final file = File(path as String);
          if (await file.exists()) {
            totalSize += await file.length();
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error calculating download size: $e');
    }
    
    return totalSize;
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Clear all downloaded content
  Future<void> clearAllDownloads() async {
    try {
      final contentDir = await _getContentDirectory();
      if (await contentDir.exists()) {
        await contentDir.delete(recursive: true);
        debugPrint('🗑️ Cleared all downloaded content');
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_downloadedContentKey);
    } catch (e) {
      debugPrint('⚠️ Error clearing downloads: $e');
    }
  }
}

