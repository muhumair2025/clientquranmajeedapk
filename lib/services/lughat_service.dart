import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'dart:io';

class LughatService {
  static Map<String, LughatData> _textData = {};
  static Map<String, LughatData> _audioData = {};
  static Map<String, LughatData> _videoData = {};
  static final Dio _dio = Dio();
  
  // Download management
  static final Map<String, CancelToken> _downloadTokens = {};
  static final Map<String, double> _downloadProgress = {};
  static final Map<String, DownloadStatus> _downloadStatus = {};

  static Future<void> loadLughatData() async {
    try {
      // Load text data
      final String textXml = await rootBundle.loadString('assets/quran_data/lughaat_tashreeh_text.xml');
      _textData = _parseXmlData(textXml, 'text');
      debugPrint('Loaded ${_textData.length} text entries');

      // Load audio data
      final String audioXml = await rootBundle.loadString('assets/quran_data/lughaat_tashreeh_text_audio.xml');
      _audioData = _parseXmlData(audioXml, 'audio');
      debugPrint('Loaded ${_audioData.length} audio entries');

      // Load video data
      final String videoXml = await rootBundle.loadString('assets/quran_data/lughaat_tashreeh_text_video.xml');
      _videoData = _parseXmlData(videoXml, 'video');
      debugPrint('Loaded ${_videoData.length} video entries');
      
      // Initialize download statuses
      await _initializeDownloadStatuses();
      
      // Debug: Print sample data
      debugPrint('Sample text data for 1_1: ${_textData['1_1']?.content}');
      debugPrint('Sample audio data for 1_1: ${_audioData['1_1']?.content}');
      debugPrint('Sample video data for 1_1: ${_videoData['1_1']?.content}');
      
    } catch (e) {
      // Handle error silently or use proper logging
      debugPrint('Error loading lughat data: $e');
    }
  }

  static Map<String, LughatData> _parseXmlData(String xmlString, String type) {
    Map<String, LughatData> data = {};
    final document = XmlDocument.parse(xmlString);

    for (var suraElement in document.findAllElements('sura')) {
      int surahIndex = int.parse(suraElement.getAttribute('index')!);
      
      for (var ayaElement in suraElement.findAllElements('aya')) {
        int ayahIndex = int.parse(ayaElement.getAttribute('index')!);
        String key = '${surahIndex}_$ayahIndex';
        
        switch (type) {
          case 'text':
            String? tashreeh = ayaElement.getAttribute('tashreeh');
            if (tashreeh != null) {
              data[key] = LughatData(
                surahIndex: surahIndex,
                ayahIndex: ayahIndex,
                content: tashreeh,
                type: LughatType.text,
              );
            }
            break;
          case 'audio':
            String? audioLink = ayaElement.getAttribute('audiolink');
            if (audioLink != null) {
              data[key] = LughatData(
                surahIndex: surahIndex,
                ayahIndex: ayahIndex,
                content: audioLink,
                type: LughatType.audio,
              );
            }
            break;
          case 'video':
            String? videoLink = ayaElement.getAttribute('vidoelink'); // Note: typo in XML
            if (videoLink != null) {
              data[key] = LughatData(
                surahIndex: surahIndex,
                ayahIndex: ayahIndex,
                content: videoLink,
                type: LughatType.video,
              );
            }
            break;
        }
      }
    }
    return data;
  }

  static Future<void> _initializeDownloadStatuses() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final lughatDir = Directory('${directory.path}/lughat');
      
      if (await lughatDir.exists()) {
        // Check which files are already downloaded
        for (var entry in _audioData.entries) {
          final localPath = await _getLocalFilePath(entry.key, LughatType.audio);
          if (await File(localPath).exists()) {
            _downloadStatus['${entry.key}_audio'] = DownloadStatus.completed;
          }
        }
        
        for (var entry in _videoData.entries) {
          final localPath = await _getLocalFilePath(entry.key, LughatType.video);
          if (await File(localPath).exists()) {
            _downloadStatus['${entry.key}_video'] = DownloadStatus.completed;
          }
        }
      }
    } catch (e) {
      debugPrint('Error initializing download statuses: $e');
    }
  }

  static Future<String> _getLocalFilePath(String key, LughatType type) async {
    final directory = await getApplicationDocumentsDirectory();
    final lughatDir = Directory('${directory.path}/lughat');
    
    if (!await lughatDir.exists()) {
      await lughatDir.create(recursive: true);
    }
    
    final extension = type == LughatType.audio ? 'mp3' : 'mp4';
    return '${lughatDir.path}/${key}_${type.name}.$extension';
  }

  static Future<String> downloadFile(
    int surahIndex, 
    int ayahIndex, 
    LughatType type,
    Function(double) onProgress,
    Function(String) onError,
  ) async {
    final key = '${surahIndex}_$ayahIndex';
    final downloadKey = '${key}_${type.name}';
    
    try {
      // Check if already downloaded
      final localPath = await _getLocalFilePath(key, type);
      if (await File(localPath).exists()) {
        _downloadStatus[downloadKey] = DownloadStatus.completed;
        return localPath;
      }
      
      // Get the remote URL
      String? remoteUrl;
      if (type == LughatType.audio) {
        remoteUrl = _audioData[key]?.content;
      } else if (type == LughatType.video) {
        remoteUrl = _videoData[key]?.content;
      }
      
      if (remoteUrl == null) {
        throw Exception('URL not found for $downloadKey');
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
      
      // Ensure 100% progress is reported
      _downloadProgress[downloadKey] = 1.0;
      onProgress(1.0);
      
      _downloadStatus[downloadKey] = DownloadStatus.completed;
      _downloadTokens.remove(downloadKey);
      
      // Keep progress at 1.0 for completed downloads instead of removing
      _downloadProgress[downloadKey] = 1.0;
      
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

  static void pauseDownload(int surahIndex, int ayahIndex, LughatType type) {
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
    LughatType type,
    Function(double) onProgress,
    Function(String) onError,
  ) async {
    await downloadFile(surahIndex, ayahIndex, type, onProgress, onError);
  }

  static Future<void> deleteDownload(int surahIndex, int ayahIndex, LughatType type) async {
    final key = '${surahIndex}_$ayahIndex';
    final downloadKey = '${key}_${type.name}';
    
    try {
      final localPath = await _getLocalFilePath(key, type);
      final file = File(localPath);
      
      if (await file.exists()) {
        await file.delete();
      }
      
      _downloadStatus[downloadKey] = DownloadStatus.notStarted;
      _downloadProgress.remove(downloadKey);
      _downloadTokens.remove(downloadKey);
    } catch (e) {
      debugPrint('Error deleting download: $e');
    }
  }

  static Future<String?> getLocalFilePath(int surahIndex, int ayahIndex, LughatType type) async {
    final downloadKey = '${surahIndex}_${ayahIndex}_${type.name}';
    final key = '${surahIndex}_$ayahIndex';
    
    // First check if status is completed
    if (_downloadStatus[downloadKey] == DownloadStatus.completed) {
      return await _getLocalFilePath(key, type);
    }
    
    // Fallback: Check if file actually exists even if status is not completed
    // This handles cases where status might not be properly restored
    try {
      final localPath = await _getLocalFilePath(key, type);
      if (await File(localPath).exists()) {
        // Update status to completed since file exists
        _downloadStatus[downloadKey] = DownloadStatus.completed;
        return localPath;
      }
    } catch (e) {
      debugPrint('Error checking local file existence: $e');
    }
    
    return null;
  }

  static DownloadStatus getDownloadStatus(int surahIndex, int ayahIndex, LughatType type) {
    final downloadKey = '${surahIndex}_${ayahIndex}_${type.name}';
    return _downloadStatus[downloadKey] ?? DownloadStatus.notStarted;
  }

  static double getDownloadProgress(int surahIndex, int ayahIndex, LughatType type) {
    final downloadKey = '${surahIndex}_${ayahIndex}_${type.name}';
    final status = _downloadStatus[downloadKey] ?? DownloadStatus.notStarted;
    
    // Always return 1.0 for completed downloads
    if (status == DownloadStatus.completed) {
      return 1.0;
    }
    
    return _downloadProgress[downloadKey] ?? 0.0;
  }

  static bool isDownloaded(int surahIndex, int ayahIndex, LughatType type) {
    return getDownloadStatus(surahIndex, ayahIndex, type) == DownloadStatus.completed;
  }

  static LughatData? getTextData(int surahIndex, int ayahIndex) {
    return _textData['${surahIndex}_$ayahIndex'];
  }

  static LughatData? getAudioData(int surahIndex, int ayahIndex) {
    return _audioData['${surahIndex}_$ayahIndex'];
  }

  static LughatData? getVideoData(int surahIndex, int ayahIndex) {
    return _videoData['${surahIndex}_$ayahIndex'];
  }

  static bool hasTextData(int surahIndex, int ayahIndex) {
    final key = '${surahIndex}_$ayahIndex';
    final hasData = _textData.containsKey(key);
    debugPrint('hasTextData for $key: $hasData');
    return hasData;
  }

  static bool hasAudioData(int surahIndex, int ayahIndex) {
    final key = '${surahIndex}_$ayahIndex';
    final hasData = _audioData.containsKey(key);
    debugPrint('hasAudioData for $key: $hasData');
    return hasData;
  }

  static bool hasVideoData(int surahIndex, int ayahIndex) {
    final key = '${surahIndex}_$ayahIndex';
    final hasData = _videoData.containsKey(key);
    debugPrint('hasVideoData for $key: $hasData');
    return hasData;
  }
}

class LughatData {
  final int surahIndex;
  final int ayahIndex;
  final String content;
  final LughatType type;

  LughatData({
    required this.surahIndex,
    required this.ayahIndex,
    required this.content,
    required this.type,
  });
}

enum LughatType {
  text,
  audio,
  video,
}

enum DownloadStatus {
  notStarted,
  downloading,
  paused,
  completed,
  failed,
} 