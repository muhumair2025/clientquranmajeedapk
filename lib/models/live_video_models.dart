import 'package:flutter/material.dart';

/// Models for Live Videos from API (matches backend API specification)
class LiveVideo {
  final int id;
  final String title;
  final String youtubeUrl;
  final String youtubeVideoId;
  final String embedUrl;
  final String thumbnailUrl;
  final DateTime? scheduledAt;
  final String status; // 'upcoming', 'live', 'ended'
  final bool isLiveNow;
  final bool isUpcoming;
  final int order;

  LiveVideo({
    required this.id,
    required this.title,
    required this.youtubeUrl,
    required this.youtubeVideoId,
    required this.embedUrl,
    required this.thumbnailUrl,
    this.scheduledAt,
    required this.status,
    required this.isLiveNow,
    required this.isUpcoming,
    required this.order,
  });

  factory LiveVideo.fromJson(Map<String, dynamic> json) {
    return LiveVideo(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? 'Live Video',
      youtubeUrl: (json['youtube_url'] as String?) ?? '',
      youtubeVideoId: (json['youtube_video_id'] as String?) ?? '',
      embedUrl: (json['embed_url'] as String?) ?? '',
      thumbnailUrl: (json['thumbnail_url'] as String?) ?? '',
      scheduledAt: json['scheduled_at'] != null 
          ? DateTime.tryParse(json['scheduled_at'].toString())
          : null,
      status: (json['status'] as String?) ?? 'upcoming',
      isLiveNow: (json['is_live_now'] as bool?) ?? false,
      isUpcoming: (json['is_upcoming'] as bool?) ?? false,
      order: (json['order'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'youtube_url': youtubeUrl,
      'youtube_video_id': youtubeVideoId,
      'embed_url': embedUrl,
      'thumbnail_url': thumbnailUrl,
      'scheduled_at': scheduledAt?.toIso8601String(),
      'status': status,
      'is_live_now': isLiveNow,
      'is_upcoming': isUpcoming,
      'order': order,
    };
  }

  /// Check if video is currently live
  bool get isLive => status.toLowerCase() == 'live' && isLiveNow;

  /// Check if video is upcoming
  bool get isUpcomingStream => status.toLowerCase() == 'upcoming' && isUpcoming;

  /// Check if video has ended
  bool get hasEnded => status.toLowerCase() == 'ended';

  /// Get status color
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'live':
        return Colors.red;
      case 'upcoming':
        return Colors.blue;
      case 'ended':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

/// Response from GET /api/live-videos
class LiveVideosResponse {
  final bool success;
  final String message;
  final List<LiveVideo> videos;

  LiveVideosResponse({
    required this.success,
    required this.message,
    required this.videos,
  });

  factory LiveVideosResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] as List<dynamic>? ?? [];
    final videos = dataList
        .map((item) => LiveVideo.fromJson(item as Map<String, dynamic>))
        .toList();

    return LiveVideosResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      videos: videos,
    );
  }
}

