/// Models for Latest Content API
/// Shows newest content from categories, subcategories, materials, and ayah audio/video

/// Type of latest content item
enum LatestContentType {
  category,
  subcategory,
  text,
  qa,
  pdf,
  audio,
  video,
  ayahAudio,
  ayahVideo,
}

/// A single latest content item
class LatestItem {
  final int id;
  final LatestContentType type;
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final String? contentUrl; // For audio/video/pdf
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Parent info for navigation
  final int? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final int? subcategoryId;
  final String? subcategoryName;
  
  // Ayah-specific fields
  final int? surahNumber;
  final int? ayahNumber;
  final String? surahName;
  final String? sectionType; // lughat, tafseer, faidi

  LatestItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
    this.contentUrl,
    required this.createdAt,
    this.updatedAt,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.subcategoryId,
    this.subcategoryName,
    this.surahNumber,
    this.ayahNumber,
    this.surahName,
    this.sectionType,
  });

  factory LatestItem.fromJson(Map<String, dynamic> json) {
    return LatestItem(
      id: json['id'] as int? ?? 0,
      type: _parseContentType(json['type'] as String? ?? 'text'),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      contentUrl: json['content_url'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      categoryId: json['category_id'] as int?,
      categoryName: json['category_name'] as String?,
      categoryColor: json['category_color'] as String?,
      subcategoryId: json['subcategory_id'] as int?,
      subcategoryName: json['subcategory_name'] as String?,
      surahNumber: json['surah_number'] as int?,
      ayahNumber: json['ayah_number'] as int?,
      surahName: json['surah_name'] as String?,
      sectionType: json['section_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'image_url': imageUrl,
      'content_url': contentUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'category_id': categoryId,
      'category_name': categoryName,
      'category_color': categoryColor,
      'subcategory_id': subcategoryId,
      'subcategory_name': subcategoryName,
      'surah_number': surahNumber,
      'ayah_number': ayahNumber,
      'surah_name': surahName,
      'section_type': sectionType,
    };
  }

  static LatestContentType _parseContentType(String type) {
    switch (type.toLowerCase()) {
      case 'category':
        return LatestContentType.category;
      case 'subcategory':
        return LatestContentType.subcategory;
      case 'text':
        return LatestContentType.text;
      case 'qa':
        return LatestContentType.qa;
      case 'pdf':
        return LatestContentType.pdf;
      case 'audio':
        return LatestContentType.audio;
      case 'video':
        return LatestContentType.video;
      case 'ayah_audio':
        return LatestContentType.ayahAudio;
      case 'ayah_video':
        return LatestContentType.ayahVideo;
      default:
        return LatestContentType.text;
    }
  }

  /// Get time ago string for display
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'min' : 'mins'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Check if this is a new item (added within last 24 hours)
  bool get isNew => DateTime.now().difference(createdAt).inHours < 24;

  /// Check if this is ayah-related content
  bool get isAyahContent => 
      type == LatestContentType.ayahAudio || 
      type == LatestContentType.ayahVideo;

  /// Get breadcrumb path for display
  String get breadcrumb {
    final parts = <String>[];
    if (categoryName != null) parts.add(categoryName!);
    if (subcategoryName != null) parts.add(subcategoryName!);
    if (surahName != null && ayahNumber != null) {
      parts.add('$surahName:$ayahNumber');
    }
    return parts.join(' › ');
  }
}

/// Response from GET /api/latest
class LatestContentResponse {
  final bool success;
  final String message;
  final List<LatestItem> items;
  final int totalCount;
  final DateTime? lastUpdated;

  LatestContentResponse({
    required this.success,
    required this.message,
    required this.items,
    required this.totalCount,
    this.lastUpdated,
  });

  factory LatestContentResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] as List<dynamic>? ?? [];
    final items = dataList
        .map((item) => LatestItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return LatestContentResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      items: items,
      totalCount: json['total_count'] as int? ?? items.length,
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': items.map((item) => item.toJson()).toList(),
      'total_count': totalCount,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }
}

/// Filter options for latest content
class LatestContentFilter {
  final Set<LatestContentType> types;
  final int? limit;
  final int? offset;

  LatestContentFilter({
    Set<LatestContentType>? types,
    this.limit,
    this.offset,
  }) : types = types ?? {};

  /// Get query parameters for API request
  Map<String, String> toQueryParams() {
    final params = <String, String>{};
    
    if (types.isNotEmpty) {
      params['types'] = types.map((t) => t.name).join(',');
    }
    if (limit != null) params['limit'] = limit.toString();
    if (offset != null) params['offset'] = offset.toString();
    
    return params;
  }
}

