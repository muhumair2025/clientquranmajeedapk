import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'quran_api_service.dart';
import 'common_models.dart';

class FaidiService {
  static Map<String, FaidiData> _textData = {};
  static final Dio _dio = Dio();
  
  // Download management
  static final Map<String, CancelToken> _downloadTokens = {};
  static final Map<String, double> _downloadProgress = {};
  static final Map<String, DownloadStatus> _downloadStatus = {};

  static Future<void> loadFaidiData() async {
    try {
      // Load text data from XML if available (keeping XML for text content)
      try {
        final String textXml = await rootBundle.loadString('assets/quran_data/faidi_text.xml');
        _textData = _parseXmlData(textXml, 'text');
        debugPrint('Loaded ${_textData.length} faidi text entries from XML');
      } catch (e) {
        debugPrint('No faidi text XML found, will use API for all data: $e');
      }
      
      // Initialize download statuses
      await _initializeDownloadStatuses();
      
    } catch (e) {
      debugPrint('Error loading faidi data: $e');
    }
  }

  static Map<String, FaidiData> _parseXmlData(String xmlString, String type) {
    Map<String, FaidiData> data = {};
    final document = XmlDocument.parse(xmlString);

    for (var suraElement in document.findAllElements('sura')) {
      int surahIndex = int.parse(suraElement.getAttribute('index')!);
      
      for (var ayaElement in suraElement.findAllElements('aya')) {
        int ayahIndex = int.parse(ayaElement.getAttribute('index')!);
        String key = '${surahIndex}_$ayahIndex';
        
        if (type == 'text') {
          String? faidi = ayaElement.getAttribute('faidi');
          if (faidi != null) {
            data[key] = FaidiData(
              surahIndex: surahIndex,
              ayahIndex: ayahIndex,
              content: faidi,
              type: FaidiType.text,
            );
          }
        }
      }
    }
    return data;
  }

  static Future<void> _initializeDownloadStatuses() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final faidiDir = Directory('${directory.path}/faidi');
      
      if (await faidiDir.exists()) {
        // Scan all files in faidi directory and update status based on existing files
        final files = await faidiDir.list().toList();
        for (var file in files) {
          if (file is File) {
            final fileName = file.path.split('/').last;
            // Extract key and type from filename pattern: surahIndex_ayahIndex_type_urlhash.extension
            final match = RegExp(r'^(\d+_\d+)_(audio|video)_[a-f0-9]{8}\.(mp3|mp4)$').firstMatch(fileName);
            if (match != null) {
              final key = match.group(1)!;
              final type = match.group(2)!;
              final downloadKey = '${key}_$type';
              _downloadStatus[downloadKey] = DownloadStatus.completed;
              _downloadProgress[downloadKey] = 1.0;
            }
          }
        }
        
        debugPrint('Initialized ${_downloadStatus.length} faidi download statuses from existing files');
      }
    } catch (e) {
      debugPrint('Error initializing faidi download statuses: $e');
    }
  }

  static Future<String> _getLocalFilePath(String key, FaidiType type, [String? url]) async {
    final directory = await getApplicationDocumentsDirectory();
    final faidiDir = Directory('${directory.path}/faidi');
    
    if (!await faidiDir.exists()) {
      await faidiDir.create(recursive: true);
    }
    
    final extension = type == FaidiType.audio ? 'mp3' : 'mp4';
    
    // Create unique filename including URL hash to avoid conflicts
    String filename = '${key}_${type.name}';
    if (url != null) {
      final urlHash = md5.convert(utf8.encode(url)).toString().substring(0, 8);
      filename = '${key}_${type.name}_$urlHash';
    }
    
    return '${faidiDir.path}/$filename.$extension';
  }

  static Future<String> downloadFile(
    int surahIndex, 
    int ayahIndex, 
    FaidiType type,
    Function(double) onProgress,
    Function(String) onError,
  ) async {
    final key = '${surahIndex}_$ayahIndex';
    final downloadKey = '${key}_${type.name}';
    
    try {
      // Get the remote URL from API first
      String? remoteUrl;
      if (type == FaidiType.audio) {
        remoteUrl = await QuranApiService.getAudioUrl(surahIndex, ayahIndex, 'faidi');
      } else if (type == FaidiType.video) {
        remoteUrl = await QuranApiService.getVideoUrl(surahIndex, ayahIndex, 'faidi');
      }
      
      if (remoteUrl == null) {
        throw Exception('URL not found for $downloadKey');
      }
      
      // Check if already downloaded with URL-specific path
      final localPath = await _getLocalFilePath(key, type, remoteUrl);
      if (await File(localPath).exists()) {
        _downloadStatus[downloadKey] = DownloadStatus.completed;
        return localPath;
      }
      
      // Create cancel token
      final cancelToken = CancelToken();
      _downloadTokens[downloadKey] = cancelToken;
      _downloadStatus[downloadKey] = DownloadStatus.downloading;
      
      // Start download
      await _dio.download(
        remoteUrl,
        localPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final progress = received / total;
            _downloadProgress[downloadKey] = progress;
            onProgress(progress);
          }
        },
      );
      
      _downloadProgress[downloadKey] = 1.0;
      onProgress(1.0);
      _downloadStatus[downloadKey] = DownloadStatus.completed;
      _downloadTokens.remove(downloadKey);
      
      return localPath;
      
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        _downloadStatus[downloadKey] = DownloadStatus.paused;
      } else {
        _downloadStatus[downloadKey] = DownloadStatus.failed;
        _downloadTokens.remove(downloadKey);
        _downloadProgress.remove(downloadKey);
        onError(e.toString());
      }
      rethrow;
    }
  }

  static void pauseDownload(int surahIndex, int ayahIndex, FaidiType type) {
    final downloadKey = '${surahIndex}_${ayahIndex}_${type.name}';
    final token = _downloadTokens[downloadKey];
    if (token != null && !token.isCancelled) {
      token.cancel();
      _downloadStatus[downloadKey] = DownloadStatus.paused;
    }
  }

  static Future<void> resumeDownload(
    int surahIndex, 
    int ayahIndex, 
    FaidiType type,
    Function(double) onProgress,
    Function(String) onError,
  ) async {
    await downloadFile(surahIndex, ayahIndex, type, onProgress, onError);
  }

  static Future<void> deleteDownload(int surahIndex, int ayahIndex, FaidiType type) async {
    final key = '${surahIndex}_$ayahIndex';
    final downloadKey = '${key}_${type.name}';
    
    try {
      // Get the URL to generate correct file path
      String? remoteUrl;
      if (type == FaidiType.audio) {
        final audioData = await getAudioData(surahIndex, ayahIndex);
        remoteUrl = audioData?.content;
      } else if (type == FaidiType.video) {
        final videoData = await getVideoData(surahIndex, ayahIndex);
        remoteUrl = videoData?.content;
      }
      
      if (remoteUrl != null) {
        final localPath = await _getLocalFilePath(key, type, remoteUrl);
        final file = File(localPath);
        
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      _downloadStatus[downloadKey] = DownloadStatus.notStarted;
      _downloadProgress.remove(downloadKey);
      _downloadTokens.remove(downloadKey);
    } catch (e) {
      debugPrint('Error deleting faidi download: $e');
    }
  }

  static Future<String?> getLocalFilePath(int surahIndex, int ayahIndex, FaidiType type) async {
    final downloadKey = '${surahIndex}_${ayahIndex}_${type.name}';
    final key = '${surahIndex}_$ayahIndex';
    
    // Get the URL to generate correct file path
    String? remoteUrl;
    if (type == FaidiType.audio) {
      final audioData = await getAudioData(surahIndex, ayahIndex);
      remoteUrl = audioData?.content;
    } else if (type == FaidiType.video) {
      final videoData = await getVideoData(surahIndex, ayahIndex);
      remoteUrl = videoData?.content;
    }
    
    if (remoteUrl == null) {
      return null;
    }
    
    if (_downloadStatus[downloadKey] == DownloadStatus.completed) {
      return await _getLocalFilePath(key, type, remoteUrl);
    }
    
    try {
      final localPath = await _getLocalFilePath(key, type, remoteUrl);
      if (await File(localPath).exists()) {
        _downloadStatus[downloadKey] = DownloadStatus.completed;
        return localPath;
      }
    } catch (e) {
      debugPrint('Error checking faidi local file existence: $e');
    }
    
    return null;
  }

  static DownloadStatus getDownloadStatus(int surahIndex, int ayahIndex, FaidiType type) {
    final downloadKey = '${surahIndex}_${ayahIndex}_${type.name}';
    return _downloadStatus[downloadKey] ?? DownloadStatus.notStarted;
  }

  static double getDownloadProgress(int surahIndex, int ayahIndex, FaidiType type) {
    final downloadKey = '${surahIndex}_${ayahIndex}_${type.name}';
    final status = _downloadStatus[downloadKey] ?? DownloadStatus.notStarted;
    
    if (status == DownloadStatus.completed) {
      return 1.0;
    }
    
    return _downloadProgress[downloadKey] ?? 0.0;
  }

  static bool isDownloaded(int surahIndex, int ayahIndex, FaidiType type) {
    return getDownloadStatus(surahIndex, ayahIndex, type) == DownloadStatus.completed;
  }

  static FaidiData? getTextData(int surahIndex, int ayahIndex) {
    return _textData['${surahIndex}_$ayahIndex'];
  }

  static Future<FaidiData?> getAudioData(int surahIndex, int ayahIndex) async {
    // Try to get from API
    try {
      final audioUrl = await QuranApiService.getAudioUrl(surahIndex, ayahIndex, 'faidi');
      if (audioUrl != null) {
        return FaidiData(
          surahIndex: surahIndex,
          ayahIndex: ayahIndex,
          content: audioUrl,
          type: FaidiType.audio,
        );
      }
    } catch (e) {
      debugPrint('Error getting faidi audio from API: $e');
    }
    
    return null;
  }

  static Future<FaidiData?> getVideoData(int surahIndex, int ayahIndex) async {
    // Try to get from API
    try {
      final videoUrl = await QuranApiService.getVideoUrl(surahIndex, ayahIndex, 'faidi');
      if (videoUrl != null) {
        return FaidiData(
          surahIndex: surahIndex,
          ayahIndex: ayahIndex,
          content: videoUrl,
          type: FaidiType.video,
        );
      }
    } catch (e) {
      debugPrint('Error getting faidi video from API: $e');
    }
    
    return null;
  }

  static bool hasTextData(int surahIndex, int ayahIndex) {
    final key = '${surahIndex}_$ayahIndex';
    final hasData = _textData.containsKey(key);
    debugPrint('hasFaidiTextData for $key: $hasData');
    return hasData;
  }

  static Future<bool> hasAudioData(int surahIndex, int ayahIndex) async {
    try {
      final hasApiData = await QuranApiService.hasAudioData(surahIndex, ayahIndex, 'faidi');
      debugPrint('hasFaidiAudioData for ${surahIndex}_$ayahIndex: $hasApiData (from API)');
      return hasApiData;
    } catch (e) {
      debugPrint('Error checking faidi audio data from API: $e');
      return false;
    }
  }

  static Future<bool> hasVideoData(int surahIndex, int ayahIndex) async {
    try {
      final hasApiData = await QuranApiService.hasVideoData(surahIndex, ayahIndex, 'faidi');
      debugPrint('hasFaidiVideoData for ${surahIndex}_$ayahIndex: $hasApiData (from API)');
      return hasApiData;
    } catch (e) {
      debugPrint('Error checking faidi video data from API: $e');
      return false;
    }
  }
}

class FaidiData {
  final int surahIndex;
  final int ayahIndex;
  final String content;
  final FaidiType type;

  FaidiData({
    required this.surahIndex,
    required this.ayahIndex,
    required this.content,
    required this.type,
  });
}

enum FaidiType {
  text,
  audio,
  video,
}

