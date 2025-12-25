import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage pinned live videos (max 4 videos)
class VideoPinService {
  // Singleton pattern
  static final VideoPinService _instance = VideoPinService._internal();
  factory VideoPinService() => _instance;
  VideoPinService._internal();

  static const String _pinnedVideosKey = 'pinned_live_video_ids';
  static const int maxPinnedVideos = 4;

  /// Get list of pinned video IDs
  Future<List<int>> getPinnedVideoIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinnedIds = prefs.getStringList(_pinnedVideosKey);
      
      if (pinnedIds != null) {
        return pinnedIds.map((id) => int.parse(id)).toList();
      }
    } catch (e) {
      debugPrint('⚠️ Error reading pinned videos: $e');
    }
    return [];
  }

  /// Check if a video is pinned
  Future<bool> isVideoPinned(int videoId) async {
    final pinnedIds = await getPinnedVideoIds();
    return pinnedIds.contains(videoId);
  }

  /// Pin a video (max 4 videos can be pinned)
  Future<bool> pinVideo(int videoId) async {
    try {
      final pinnedIds = await getPinnedVideoIds();
      
      // Check if already pinned
      if (pinnedIds.contains(videoId)) {
        return true;
      }
      
      // Check max limit
      if (pinnedIds.length >= maxPinnedVideos) {
        debugPrint('⚠️ Maximum $maxPinnedVideos videos can be pinned');
        return false;
      }
      
      // Add to pinned list
      pinnedIds.add(videoId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _pinnedVideosKey,
        pinnedIds.map((id) => id.toString()).toList(),
      );
      
      debugPrint('📌 Video $videoId pinned (${pinnedIds.length}/$maxPinnedVideos)');
      return true;
    } catch (e) {
      debugPrint('❌ Error pinning video: $e');
      return false;
    }
  }

  /// Unpin a video
  Future<bool> unpinVideo(int videoId) async {
    try {
      final pinnedIds = await getPinnedVideoIds();
      
      if (pinnedIds.remove(videoId)) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          _pinnedVideosKey,
          pinnedIds.map((id) => id.toString()).toList(),
        );
        
        debugPrint('📌 Video $videoId unpinned (${pinnedIds.length}/$maxPinnedVideos)');
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('❌ Error unpinning video: $e');
      return false;
    }
  }

  /// Toggle pin status of a video
  Future<bool> togglePin(int videoId) async {
    final isPinned = await isVideoPinned(videoId);
    
    if (isPinned) {
      return await unpinVideo(videoId);
    } else {
      return await pinVideo(videoId);
    }
  }

  /// Get count of pinned videos
  Future<int> getPinnedCount() async {
    final pinnedIds = await getPinnedVideoIds();
    return pinnedIds.length;
  }

  /// Check if more videos can be pinned
  Future<bool> canPinMore() async {
    final count = await getPinnedCount();
    return count < maxPinnedVideos;
  }

  /// Clear all pinned videos
  Future<void> clearAllPins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pinnedVideosKey);
      debugPrint('🗑️ All pinned videos cleared');
    } catch (e) {
      debugPrint('⚠️ Error clearing pinned videos: $e');
    }
  }
}

