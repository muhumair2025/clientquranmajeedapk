/// Models for Hero Slides and Splash Screen content from API
class HeroSlide {
  final int id;
  final String? title;
  final String? description;
  final String imageUrl;
  final String imageDownloadUrl;
  final String? buttonText;
  final String? buttonLink;
  final int order;

  HeroSlide({
    required this.id,
    this.title,
    this.description,
    required this.imageUrl,
    required this.imageDownloadUrl,
    this.buttonText,
    this.buttonLink,
    required this.order,
  });

  factory HeroSlide.fromJson(Map<String, dynamic> json) {
    return HeroSlide(
      id: json['id'] as int,
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String,
      imageDownloadUrl: json['image_download_url'] as String,
      buttonText: json['button_text'] as String?,
      buttonLink: json['button_link'] as String?,
      order: json['order'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'image_download_url': imageDownloadUrl,
      'button_text': buttonText,
      'button_link': buttonLink,
      'order': order,
    };
  }
}

/// Response from GET /api/hero-slides
class HeroSlidesResponse {
  final bool success;
  final String message;
  final List<HeroSlide> slides;

  HeroSlidesResponse({
    required this.success,
    required this.message,
    required this.slides,
  });

  factory HeroSlidesResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] as List<dynamic>? ?? [];
    final slides = dataList
        .map((item) => HeroSlide.fromJson(item as Map<String, dynamic>))
        .toList();

    return HeroSlidesResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      slides: slides,
    );
  }
}

/// Splash Screen data
class SplashScreenData {
  final bool hasSplashScreen;
  final String? imageUrl;
  final String? imageDownloadUrl;

  SplashScreenData({
    required this.hasSplashScreen,
    this.imageUrl,
    this.imageDownloadUrl,
  });

  factory SplashScreenData.fromJson(Map<String, dynamic> json) {
    return SplashScreenData(
      hasSplashScreen: json['has_splash_screen'] as bool? ?? false,
      imageUrl: json['image_url'] as String?,
      imageDownloadUrl: json['image_download_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'has_splash_screen': hasSplashScreen,
      'image_url': imageUrl,
      'image_download_url': imageDownloadUrl,
    };
  }
}

/// Response from GET /api/splash-screen
class SplashScreenResponse {
  final bool success;
  final String message;
  final SplashScreenData data;

  SplashScreenResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SplashScreenResponse.fromJson(Map<String, dynamic> json) {
    return SplashScreenResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: SplashScreenData.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

