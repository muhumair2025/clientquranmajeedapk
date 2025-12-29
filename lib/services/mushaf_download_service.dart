import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive.dart';

/// Model for a mushaf script
class MushafScript {
  final String id;
  final String name;
  final String nameArabic;
  final String description;
  final String previewImage;
  final String downloadUrl;
  final int totalPages;
  final int sizeInMB;

  const MushafScript({
    required this.id,
    required this.name,
    required this.nameArabic,
    required this.description,
    required this.previewImage,
    required this.downloadUrl,
    required this.totalPages,
    required this.sizeInMB,
  });
}

/// Download status enum
enum DownloadStatus {
  notDownloaded,
  downloading,
  extracting,
  downloaded,
  error,
}

/// Service for managing Mushaf script downloads
class MushafDownloadService {
  static const String _activeScriptKey = 'active_mushaf_script';
  static const String _downloadedScriptsKey = 'downloaded_mushaf_scripts';
  
  // Available scripts
  static const List<MushafScript> availableScripts = [
    MushafScript(
      id: 'mushaf_1352',
      name: 'Mushaf Script',
      nameArabic: 'مصحف عثماني',
      description: 'Standard Uthmani Mushaf Script (1352px width)',
      previewImage: 'assets/mushafscript.png',
      downloadUrl: 'https://f003.backblazeb2.com/file/abuhassan/appbackend_data/mushaf_1352.zip',
      totalPages: 604,
      sizeInMB: 85,
    ),
    // Future scripts can be added here
    // MushafScript(
    //   id: 'indopak',
    //   name: 'Indo-Pak Script',
    //   nameArabic: 'خط هندي باكستاني',
    //   description: 'Indo-Pak Nastaliq Script',
    //   previewImage: 'assets/indopakscript.png',
    //   downloadUrl: 'https://example.com/indopak.zip',
    //   totalPages: 604,
    //   sizeInMB: 90,
    // ),
  ];
  
  static final Dio _dio = Dio(BaseOptions(
    headers: {
      'User-Agent': 'QuranMajeed/1.0',
      'Accept': '*/*',
      'Accept-Encoding': 'gzip, deflate',
    },
    followRedirects: true,
    maxRedirects: 5,
  ));
  static CancelToken? _cancelToken;
  
  // Callbacks for progress updates
  static ValueNotifier<double> downloadProgress = ValueNotifier(0.0);
  static ValueNotifier<DownloadStatus> downloadStatus = ValueNotifier(DownloadStatus.notDownloaded);
  static ValueNotifier<String> statusMessage = ValueNotifier('');
  
  /// Get the directory where mushaf scripts are stored
  static Future<Directory> _getMushafDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final mushafDir = Directory('${appDir.path}/mushaf_scripts');
    if (!await mushafDir.exists()) {
      await mushafDir.create(recursive: true);
    }
    return mushafDir;
  }
  
  /// Get the directory for a specific script
  static Future<Directory> getScriptDirectory(String scriptId) async {
    final mushafDir = await _getMushafDirectory();
    return Directory('${mushafDir.path}/$scriptId');
  }
  
  /// Check if a script is downloaded
  static Future<bool> isScriptDownloaded(String scriptId) async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getStringList(_downloadedScriptsKey) ?? [];
    if (!downloaded.contains(scriptId)) return false;
    
    // Verify files exist
    final scriptDir = await getScriptDirectory(scriptId);
    if (!await scriptDir.exists()) return false;
    
    // Check if at least page001.png exists (inside width_1352 folder from zip)
    final testFile = File('${scriptDir.path}/width_1352/page001.png');
    return await testFile.exists();
  }
  
  /// Get the currently active script ID
  static Future<String?> getActiveScript() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeScriptKey);
  }
  
  /// Set the active script
  static Future<void> setActiveScript(String scriptId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeScriptKey, scriptId);
    debugPrint('✅ Active mushaf script set to: $scriptId');
  }
  
  /// Get list of downloaded scripts
  static Future<List<String>> getDownloadedScripts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_downloadedScriptsKey) ?? [];
  }
  
  /// Get the image path for a specific page
  static Future<String?> getPageImagePath(int pageNumber) async {
    final activeScript = await getActiveScript();
    if (activeScript == null) return null;
    
    final scriptDir = await getScriptDirectory(activeScript);
    final pageFileName = 'page${pageNumber.toString().padLeft(3, '0')}.png';
    // Images are inside width_1352 folder from the zip
    final imagePath = '${scriptDir.path}/width_1352/$pageFileName';
    
    final file = File(imagePath);
    if (await file.exists()) {
      return imagePath;
    }
    return null;
  }
  
  /// Check if we should use downloaded images or bundled assets
  static Future<bool> shouldUseDownloadedImages() async {
    final activeScript = await getActiveScript();
    if (activeScript == null) return false;
    return await isScriptDownloaded(activeScript);
  }
  
  /// Download a mushaf script
  static Future<bool> downloadScript(MushafScript script) async {
    try {
      downloadStatus.value = DownloadStatus.downloading;
      downloadProgress.value = 0.0;
      statusMessage.value = 'Starting download...';
      
      final mushafDir = await _getMushafDirectory();
      final zipPath = '${mushafDir.path}/${script.id}.zip';
      final scriptDir = await getScriptDirectory(script.id);
      
      // Cancel any previous download
      _cancelToken?.cancel();
      _cancelToken = CancelToken();
      
      debugPrint('📥 Downloading ${script.name} from ${script.downloadUrl}');
      debugPrint('📁 Saving to: $zipPath');
      
      // Download the zip file
      final response = await _dio.download(
        script.downloadUrl,
        zipPath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            downloadProgress.value = received / total;
            final receivedMB = (received / 1024 / 1024).toStringAsFixed(1);
            final totalMB = (total / 1024 / 1024).toStringAsFixed(1);
            statusMessage.value = 'Downloading: $receivedMB / $totalMB MB';
          } else {
            final receivedMB = (received / 1024 / 1024).toStringAsFixed(1);
            statusMessage.value = 'Downloading: $receivedMB MB';
          }
        },
        options: Options(
          receiveTimeout: const Duration(minutes: 30),
          sendTimeout: const Duration(minutes: 5),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      // Check for HTTP errors
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Server returned ${response.statusCode}. Please check if the file is accessible.',
        );
      }
      
      debugPrint('✅ Download complete, extracting...');
      downloadStatus.value = DownloadStatus.extracting;
      statusMessage.value = 'Extracting files...';
      downloadProgress.value = 0.0;
      
      // Extract in isolate to avoid UI freeze
      await compute(_extractZip, _ExtractParams(zipPath, scriptDir.path));
      
      // Delete zip file after extraction
      final zipFile = File(zipPath);
      if (await zipFile.exists()) {
        await zipFile.delete();
        debugPrint('🗑️ Deleted zip file');
      }
      
      // Mark as downloaded
      final prefs = await SharedPreferences.getInstance();
      final downloaded = prefs.getStringList(_downloadedScriptsKey) ?? [];
      if (!downloaded.contains(script.id)) {
        downloaded.add(script.id);
        await prefs.setStringList(_downloadedScriptsKey, downloaded);
      }
      
      // Set as active script
      await setActiveScript(script.id);
      
      downloadStatus.value = DownloadStatus.downloaded;
      statusMessage.value = 'Download complete!';
      downloadProgress.value = 1.0;
      
      debugPrint('✅ Script ${script.name} installed successfully');
      return true;
      
    } on DioException catch (e) {
      debugPrint('❌ DioException downloading script: $e');
      downloadStatus.value = DownloadStatus.error;
      
      String errorMsg;
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMsg = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMsg = 'Download timeout. Please try again.';
      } else if (e.type == DioExceptionType.cancel) {
        errorMsg = 'Download cancelled';
        downloadStatus.value = DownloadStatus.notDownloaded;
      } else if (e.response?.statusCode == 403) {
        errorMsg = 'Access denied. File may not be available.';
      } else if (e.response?.statusCode == 404) {
        errorMsg = 'File not found on server.';
      } else {
        errorMsg = 'Download failed. Please try again.';
      }
      statusMessage.value = errorMsg;
      return false;
    } catch (e) {
      debugPrint('❌ Error downloading script: $e');
      downloadStatus.value = DownloadStatus.error;
      statusMessage.value = 'Download failed. Please try again.';
      return false;
    }
  }
  
  /// Cancel ongoing download
  static void cancelDownload() {
    _cancelToken?.cancel('Download cancelled by user');
    downloadStatus.value = DownloadStatus.notDownloaded;
    statusMessage.value = 'Download cancelled';
    downloadProgress.value = 0.0;
  }
  
  /// Delete a downloaded script
  static Future<bool> deleteScript(String scriptId) async {
    try {
      final scriptDir = await getScriptDirectory(scriptId);
      if (await scriptDir.exists()) {
        await scriptDir.delete(recursive: true);
      }
      
      final prefs = await SharedPreferences.getInstance();
      final downloaded = prefs.getStringList(_downloadedScriptsKey) ?? [];
      downloaded.remove(scriptId);
      await prefs.setStringList(_downloadedScriptsKey, downloaded);
      
      // If this was the active script, clear it
      final activeScript = await getActiveScript();
      if (activeScript == scriptId) {
        await prefs.remove(_activeScriptKey);
      }
      
      debugPrint('✅ Script $scriptId deleted');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting script: $e');
      return false;
    }
  }
  
  /// Get total size of downloaded scripts
  static Future<int> getTotalDownloadedSize() async {
    try {
      final mushafDir = await _getMushafDirectory();
      if (!await mushafDir.exists()) return 0;
      
      int totalSize = 0;
      await for (final entity in mushafDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      return totalSize;
    } catch (e) {
      return 0;
    }
  }
  
  /// Reset download state
  static void resetState() {
    downloadProgress.value = 0.0;
    downloadStatus.value = DownloadStatus.notDownloaded;
    statusMessage.value = '';
  }
}

/// Parameters for zip extraction
class _ExtractParams {
  final String zipPath;
  final String outputPath;
  
  _ExtractParams(this.zipPath, this.outputPath);
}

/// Extract zip file in isolate
Future<void> _extractZip(_ExtractParams params) async {
  final zipFile = File(params.zipPath);
  final bytes = await zipFile.readAsBytes();
  final archive = ZipDecoder().decodeBytes(bytes);
  
  final outputDir = Directory(params.outputPath);
  if (!await outputDir.exists()) {
    await outputDir.create(recursive: true);
  }
  
  for (final file in archive) {
    final filename = file.name;
    if (file.isFile) {
      final data = file.content as List<int>;
      final outFile = File('${params.outputPath}/$filename');
      await outFile.create(recursive: true);
      await outFile.writeAsBytes(data);
    }
  }
}

