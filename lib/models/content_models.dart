/// Models for Content/Material items from API
/// Supports 5 content types: text, qa, audio, video, pdf

enum ContentType { text, qa, audio, video, pdf }

/// Single content/material item
class ContentItem {
  final int id;
  final ContentType type;
  final String title;
  
  // For text type
  final String? textContent;
  
  // For Q&A type
  final String? question;
  final String? answer;
  
  // For PDF type
  final String? pdfUrl;
  
  // For Audio type
  final String? audioUrl;
  
  // For Video type
  final String? videoUrl;
  
  // Download state (for local caching)
  String? localFilePath;
  bool isDownloaded;

  ContentItem({
    required this.id,
    required this.type,
    required this.title,
    this.textContent,
    this.question,
    this.answer,
    this.pdfUrl,
    this.audioUrl,
    this.videoUrl,
    this.localFilePath,
    this.isDownloaded = false,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    ContentType type;
    switch (json['type']?.toString().toLowerCase()) {
      case 'qa':
        type = ContentType.qa;
        break;
      case 'pdf':
        type = ContentType.pdf;
        break;
      case 'audio':
        type = ContentType.audio;
        break;
      case 'video':
        type = ContentType.video;
        break;
      case 'text':
      default:
        type = ContentType.text;
    }

    return ContentItem(
      id: json['id'] ?? 0,
      type: type,
      title: json['title']?.toString() ?? '',
      textContent: json['text_content']?.toString(),
      question: json['question']?.toString(),
      answer: json['answer']?.toString(),
      pdfUrl: json['pdf_url']?.toString(),
      audioUrl: json['audio_url']?.toString(),
      videoUrl: json['video_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    String typeString;
    switch (type) {
      case ContentType.qa:
        typeString = 'qa';
        break;
      case ContentType.pdf:
        typeString = 'pdf';
        break;
      case ContentType.audio:
        typeString = 'audio';
        break;
      case ContentType.video:
        typeString = 'video';
        break;
      case ContentType.text:
      default:
        typeString = 'text';
    }

    return {
      'id': id,
      'type': typeString,
      'title': title,
      'text_content': textContent,
      'question': question,
      'answer': answer,
      'pdf_url': pdfUrl,
      'audio_url': audioUrl,
      'video_url': videoUrl,
      'local_file_path': localFilePath,
      'is_downloaded': isDownloaded,
    };
  }
  
  /// Get the media URL based on content type
  String? get mediaUrl {
    switch (type) {
      case ContentType.pdf:
        return pdfUrl;
      case ContentType.audio:
        return audioUrl;
      case ContentType.video:
        return videoUrl;
      default:
        return null;
    }
  }
  
  /// Check if this content type requires download
  bool get requiresDownload {
    return type == ContentType.pdf || 
           type == ContentType.audio || 
           type == ContentType.video;
  }
  
  /// Get file extension for download
  String get fileExtension {
    switch (type) {
      case ContentType.pdf:
        return '.pdf';
      case ContentType.audio:
        return '.mp3';
      case ContentType.video:
        return '.mp4';
      default:
        return '';
    }
  }

  ContentItem copyWith({
    int? id,
    ContentType? type,
    String? title,
    String? textContent,
    String? question,
    String? answer,
    String? pdfUrl,
    String? audioUrl,
    String? videoUrl,
    String? localFilePath,
    bool? isDownloaded,
  }) {
    return ContentItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      textContent: textContent ?? this.textContent,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}

/// Subcategory detail with contents
class SubcategoryContents {
  final int id;
  final String name;
  final String? description;
  final int categoryId;
  final String? categoryName;
  final List<ContentItem> contents;

  SubcategoryContents({
    required this.id,
    required this.name,
    this.description,
    required this.categoryId,
    this.categoryName,
    required this.contents,
  });

  factory SubcategoryContents.fromJson(Map<String, dynamic> json) {
    final contentsList = json['contents'] as List<dynamic>? ?? [];
    
    return SubcategoryContents(
      id: json['id'] ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      categoryId: json['category']?['id'] ?? json['category_id'] ?? 0,
      categoryName: json['category']?['names']?['english']?.toString() ?? 
                    json['category_name']?.toString(),
      contents: contentsList
          .map((item) => ContentItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category_id': categoryId,
      'category_name': categoryName,
      'contents': contents.map((c) => c.toJson()).toList(),
    };
  }
}

