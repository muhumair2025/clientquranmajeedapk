import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ReadingProgressService {
  static const String _progressKey = 'reading_progress';
  static ReadingProgress? _currentProgress;
  static bool _isLoaded = false;

  /// Initialize the reading progress service
  static Future<void> initialize() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString(_progressKey);
      
      if (progressJson != null) {
        final Map<String, dynamic> progressMap = json.decode(progressJson);
        _currentProgress = ReadingProgress.fromJson(progressMap);
        debugPrint('Loaded reading progress: ${_currentProgress?.toString()}');
      }
      
      _isLoaded = true;
    } catch (e) {
      debugPrint('Error loading reading progress: $e');
      _currentProgress = null;
      _isLoaded = true;
    }
  }

  /// Save reading progress
  static Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentProgress != null) {
        final progressJson = json.encode(_currentProgress!.toJson());
        await prefs.setString(_progressKey, progressJson);
        debugPrint('Saved reading progress: ${_currentProgress?.toString()}');
      } else {
        await prefs.remove(_progressKey);
        debugPrint('Cleared reading progress');
      }
    } catch (e) {
      debugPrint('Error saving reading progress: $e');
    }
  }

  /// Update reading progress when user is reading
  static Future<void> updateProgress({
    required int surahIndex,
    required int ayahIndex,
    required String surahName,
    int? paraIndex,
    String? paraName,
  }) async {
    await initialize();
    
    _currentProgress = ReadingProgress(
      surahIndex: surahIndex,
      ayahIndex: ayahIndex,
      surahName: surahName,
      paraIndex: paraIndex,
      paraName: paraName,
      lastReadTime: DateTime.now(),
    );
    
    await _saveProgress();
  }

  /// Get current reading progress
  static Future<ReadingProgress?> getCurrentProgress() async {
    await initialize();
    return _currentProgress;
  }

  /// Check if there's any reading progress
  static Future<bool> hasProgress() async {
    await initialize();
    return _currentProgress != null;
  }

  /// Clear reading progress
  static Future<void> clearProgress() async {
    await initialize();
    _currentProgress = null;
    await _saveProgress();
  }

  /// Get formatted progress text for display
  static Future<String?> getProgressText() async {
    final progress = await getCurrentProgress();
    if (progress == null) return null;
    
    return 'Continue reading ${progress.surahName} - Ayah ${progress.ayahIndex}';
  }

  /// Check if progress is recent (within last 24 hours)
  static Future<bool> isProgressRecent() async {
    final progress = await getCurrentProgress();
    if (progress == null) return false;
    
    final now = DateTime.now();
    final difference = now.difference(progress.lastReadTime);
    return difference.inHours < 24;
  }
}

/// Model class for reading progress
class ReadingProgress {
  final int surahIndex;
  final int ayahIndex;
  final String surahName;
  final int? paraIndex;
  final String? paraName;
  final DateTime lastReadTime;

  ReadingProgress({
    required this.surahIndex,
    required this.ayahIndex,
    required this.surahName,
    this.paraIndex,
    this.paraName,
    required this.lastReadTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'surahIndex': surahIndex,
      'ayahIndex': ayahIndex,
      'surahName': surahName,
      'paraIndex': paraIndex,
      'paraName': paraName,
      'lastReadTime': lastReadTime.toIso8601String(),
    };
  }

  factory ReadingProgress.fromJson(Map<String, dynamic> json) {
    return ReadingProgress(
      surahIndex: json['surahIndex'] ?? 1,
      ayahIndex: json['ayahIndex'] ?? 1,
      surahName: json['surahName'] ?? 'Al-Fatiha',
      paraIndex: json['paraIndex'],
      paraName: json['paraName'],
      lastReadTime: DateTime.parse(json['lastReadTime']),
    );
  }

  @override
  String toString() {
    return 'ReadingProgress(surah: $surahName($surahIndex), ayah: $ayahIndex, time: $lastReadTime)';
  }
}
