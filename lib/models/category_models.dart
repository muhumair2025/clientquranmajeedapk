/// Models for Content Management API Categories

class CategoryNames {
  final String english;
  final String urdu;
  final String arabic;
  final String pashto;

  CategoryNames({
    required this.english,
    required this.urdu,
    required this.arabic,
    required this.pashto,
  });

  factory CategoryNames.fromJson(Map<String, dynamic> json) {
    return CategoryNames(
      english: json['english'] ?? '',
      urdu: json['urdu'] ?? '',
      arabic: json['arabic'] ?? '',
      pashto: json['pashto'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'english': english,
      'urdu': urdu,
      'arabic': arabic,
      'pashto': pashto,
    };
  }

  /// Get name based on language code (en, ur, ar, ps)
  String getName(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'ur':
        return urdu;
      case 'ar':
        return arabic;
      case 'ps':
        return pashto;
      case 'en':
      default:
        return english;
    }
  }
}

class ContentCategory {
  final int id;
  final CategoryNames names;
  final String? description;
  final String iconUrl;
  final String localIconPath; // Local cached icon path
  final String color;
  final int subcategoriesCount;

  ContentCategory({
    required this.id,
    required this.names,
    this.description,
    required this.iconUrl,
    required this.localIconPath,
    required this.color,
    required this.subcategoriesCount,
  });

  factory ContentCategory.fromJson(Map<String, dynamic> json) {
    return ContentCategory(
      id: json['id'] ?? 0,
      names: CategoryNames.fromJson(json['names'] ?? {}),
      description: json['description'],
      iconUrl: json['icon_url'] ?? '',
      localIconPath: (json['local_icon_path'] as String?) ?? '', // Load cached path, default to empty
      color: json['color'] ?? '#10b981',
      subcategoriesCount: json['subcategories_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'names': names.toJson(),
      'description': description,
      'icon_url': iconUrl,
      'local_icon_path': localIconPath, // Save cached path
      'color': color,
      'subcategories_count': subcategoriesCount,
    };
  }

  /// Get name for current language
  String getName(String languageCode) {
    return names.getName(languageCode);
  }
}

class CategoriesResponse {
  final bool success;
  final String message;
  final List<ContentCategory> categories;

  CategoriesResponse({
    required this.success,
    required this.message,
    required this.categories,
  });

  factory CategoriesResponse.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    final categories = dataList
        .map((item) => ContentCategory.fromJson(item as Map<String, dynamic>))
        .toList();

    return CategoriesResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      categories: categories,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': categories.map((cat) => cat.toJson()).toList(),
    };
  }
}

