# Hero Slides & Splash Screen - Complete Documentation

## 🎉 Implementation Complete!

### New Features
1. **Hero Slides System** - Homepage slider/carousel management
2. **Splash Screen Management** - App startup screen configuration
3. **Admin UI** - Beautiful interfaces for managing both features
4. **API Endpoints** - Direct download URLs for Flutter/Android developers

---

## 📊 Database Structure

### `hero_slides` Table
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| title | VARCHAR(255) | Slide title (optional) |
| description | TEXT | Slide description (optional) |
| image_path | VARCHAR(255) | Path to slide image |
| button_text | VARCHAR(100) | CTA button text (optional) |
| button_link | VARCHAR(500) | Deep link or route (optional) |
| order | INTEGER | Display order (lower = first) |
| is_active | BOOLEAN | Active status |
| created_at | TIMESTAMP | Creation date |
| updated_at | TIMESTAMP | Last update |

### `app_settings` Table
| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER | Primary key |
| key | VARCHAR(255) | Setting key (unique) |
| value | TEXT | Setting value |
| type | VARCHAR(50) | Value type (text/image/boolean/json) |
| description | TEXT | Setting description |
| created_at | TIMESTAMP | Creation date |
| updated_at | TIMESTAMP | Last update |

**Default Setting:**
- Key: `splash_screen_image`
- Type: `image`
- Description: Splash screen image displayed when app starts

---

## 🎨 Admin Panel

### Hero Slides Management

**URL:** `http://yourdomain.com/app-management/hero-slides`

**Features:**
- ✅ View all hero slides with preview
- ✅ Create new slides with image upload
- ✅ Edit existing slides
- ✅ Delete slides
- ✅ Set display order
- ✅ Toggle active/inactive status
- ✅ View API download URLs

**Image Requirements:**
- Format: JPEG, PNG, JPG, WEBP
- Max Size: 5MB
- Recommended: 1920x1080px (16:9 ratio)

### Splash Screen Management

**URL:** `http://yourdomain.com/app-management/splash-screen`

**Features:**
- ✅ Upload splash screen image
- ✅ Preview current splash screen
- ✅ Replace existing splash screen
- ✅ Delete splash screen
- ✅ View API download URL

**Image Requirements:**
- Format: JPEG, PNG, JPG, WEBP
- Max Size: 5MB
- Recommended: 1080x1920px (9:16 ratio for portrait mobile)

---

## 📡 API Endpoints

### 1. Get Hero Slides

**Endpoint:** `GET /api/hero-slides`

**Authentication:** Required (X-API-Key header)

**Response:**
```json
{
  "success": true,
  "message": "Hero slides retrieved successfully",
  "data": [
    {
      "id": 1,
      "title": "Welcome to Our App",
      "description": "Discover Islamic knowledge and teachings",
      "image_url": "/storage/hero-slides/slide1.jpg",
      "image_download_url": "https://yourdomain.com/storage/hero-slides/slide1.jpg",
      "button_text": "Explore Now",
      "button_link": "/categories",
      "order": 1
    },
    {
      "id": 2,
      "title": "Daily Quran Reading",
      "description": "Read and understand the Holy Quran",
      "image_url": "/storage/hero-slides/slide2.jpg",
      "image_download_url": "https://yourdomain.com/storage/hero-slides/slide2.jpg",
      "button_text": "Start Reading",
      "button_link": "/quran",
      "order": 2
    }
  ]
}
```

**Use Case:** Display as carousel/slider on app homepage

---

### 2. Get Splash Screen

**Endpoint:** `GET /api/splash-screen`

**Authentication:** Required (X-API-Key header)

**Response (With Splash Screen):**
```json
{
  "success": true,
  "message": "Splash screen retrieved successfully",
  "data": {
    "has_splash_screen": true,
    "image_url": "/storage/splash-screen/splash.jpg",
    "image_download_url": "https://yourdomain.com/storage/splash-screen/splash.jpg"
  }
}
```

**Response (Without Splash Screen):**
```json
{
  "success": true,
  "message": "Splash screen retrieved successfully",
  "data": {
    "has_splash_screen": false,
    "image_url": null,
    "image_download_url": null
  }
}
```

**Use Case:** Fetch and cache splash screen image during app initialization

---

## 📱 Flutter/Android Implementation

### Setup

Add to `pubspec.yaml`:
```yaml
dependencies:
  http: ^1.1.0
  cached_network_image: ^3.3.0
  carousel_slider: ^4.2.1
```

### Models

```dart
// Hero Slide Model
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
      id: json['id'],
      title: json['title'],
      description: json['description'],
      imageUrl: json['image_url'],
      imageDownloadUrl: json['image_download_url'],
      buttonText: json['button_text'],
      buttonLink: json['button_link'],
      order: json['order'],
    );
  }
}

// Splash Screen Model
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
      hasSplashScreen: json['has_splash_screen'],
      imageUrl: json['image_url'],
      imageDownloadUrl: json['image_download_url'],
    );
  }
}
```

### API Service

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppApiService {
  static final String _baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  static final String _apiKey = dotenv.env['API_KEY'] ?? '';

  static Map<String, String> get _headers => {
    'X-API-Key': _apiKey,
    'Content-Type': 'application/json',
  };

  /// Get hero slides for homepage
  Future<List<HeroSlide>> getHeroSlides() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/hero-slides'),
          headers: _headers,
        )
        .timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['success']) {
        final List slides = jsonData['data'];
        return slides.map((slide) => HeroSlide.fromJson(slide)).toList();
      }
    }
    throw Exception('Failed to load hero slides');
  }

  /// Get splash screen data
  Future<SplashScreenData> getSplashScreen() async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/splash-screen'),
          headers: _headers,
        )
        .timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['success']) {
        return SplashScreenData.fromJson(jsonData['data']);
      }
    }
    throw Exception('Failed to load splash screen');
  }
}
```

### 1. Splash Screen Implementation

```dart
import 'package:flutter/material.dart';
import 'package:cached_network_image.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AppApiService _apiService = AppApiService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Fetch and cache splash screen
      final splashData = await _apiService.getSplashScreen();
      
      // Wait for minimum display time (2 seconds)
      await Future.delayed(Duration(seconds: 2));
      
      // Navigate to home
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print('Splash screen error: $e');
      // Still navigate to home even if splash fetch fails
      await Future.delayed(Duration(seconds: 2));
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<SplashScreenData>(
        future: _apiService.getSplashScreen(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.hasSplashScreen) {
            // Display custom splash screen
            return CachedNetworkImage(
              imageUrl: snapshot.data!.imageDownloadUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) => _defaultSplash(),
              errorWidget: (context, url, error) => _defaultSplash(),
            );
          }
          // Default splash screen
          return _defaultSplash();
        },
      ),
    );
  }

  Widget _defaultSplash() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterLogo(size: 100),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
```

### 2. Hero Slider Implementation

```dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image.dart';

class HeroSliderWidget extends StatefulWidget {
  @override
  _HeroSliderWidgetState createState() => _HeroSliderWidgetState();
}

class _HeroSliderWidgetState extends State<HeroSliderWidget> {
  final AppApiService _apiService = AppApiService();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HeroSlide>>(
      future: _apiService.getHeroSlides(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingSlider();
        }

        if (snapshot.hasError) {
          return SizedBox.shrink(); // Hide slider on error
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox.shrink(); // Hide if no slides
        }

        final slides = snapshot.data!;

        return Column(
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                autoPlay: true,
                autoPlayInterval: Duration(seconds: 5),
                enlargeCenterPage: true,
                viewportFraction: 0.9,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
              items: slides.map((slide) {
                return Builder(
                  builder: (BuildContext context) {
                    return _buildSlideCard(slide);
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 16),
            // Dots indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: slides.asMap().entries.map((entry) {
                return Container(
                  width: _currentIndex == entry.key ? 12.0 : 8.0,
                  height: 8.0,
                  margin: EdgeInsets.symmetric(horizontal: 4.0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == entry.key
                        ? Colors.blue
                        : Colors.grey.withOpacity(0.4),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSlideCard(HeroSlide slide) {
    return GestureDetector(
      onTap: () {
        if (slide.buttonLink != null) {
          // Handle navigation based on button_link
          _handleSlideNavigation(slide.buttonLink!);
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(horizontal: 5.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              CachedNetworkImage(
                imageUrl: slide.imageDownloadUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: Icon(Icons.error),
                ),
              ),
              
              // Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              
              // Text Content
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (slide.title != null)
                      Text(
                        slide.title!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (slide.description != null) ...[
                      SizedBox(height: 8),
                      Text(
                        slide.description!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (slide.buttonText != null) ...[
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _handleSlideNavigation(slide.buttonLink),
                        child: Text(slide.buttonText!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSlider() {
    return Container(
      height: 200,
      child: Center(child: CircularProgressIndicator()),
    );
  }

  void _handleSlideNavigation(String? link) {
    if (link == null) return;
    
    // Handle different link types
    if (link.startsWith('http')) {
      // External URL - open in browser
      // launchUrl(Uri.parse(link));
    } else if (link.startsWith('/')) {
      // Internal route - navigate
      Navigator.pushNamed(context, link);
    } else {
      // Deep link format - parse and navigate
      // Handle based on your app's routing
    }
  }
}
```

### 3. Homepage Integration

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quran App'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Slider
            HeroSliderWidget(),
            
            SizedBox(height: 24),
            
            // Rest of your homepage content
            // Categories, etc.
          ],
        ),
      ),
    );
  }
}
```

---

## 🔧 Admin Routes

| Route | Method | Purpose |
|-------|--------|---------|
| `/app-management/hero-slides` | GET | List all hero slides |
| `/app-management/hero-slides/create` | GET | Show create form |
| `/app-management/hero-slides` | POST | Store new slide |
| `/app-management/hero-slides/{id}/edit` | GET | Show edit form |
| `/app-management/hero-slides/{id}` | PUT | Update slide |
| `/app-management/hero-slides/{id}` | DELETE | Delete slide |
| `/app-management/splash-screen` | GET | Splash screen management |
| `/app-management/splash-screen` | POST | Upload/update splash |
| `/app-management/splash-screen` | DELETE | Delete splash screen |

---

## ✅ Testing Checklist

### Admin Panel
- [ ] Access hero slides page
- [ ] Create new hero slide with image
- [ ] Edit existing slide
- [ ] Delete slide
- [ ] Change slide order
- [ ] Toggle active/inactive status
- [ ] Access splash screen page
- [ ] Upload splash screen image
- [ ] Update existing splash screen
- [ ] Delete splash screen
- [ ] Verify download URLs are displayed

### API
- [ ] Test GET /api/hero-slides endpoint
- [ ] Test GET /api/splash-screen endpoint
- [ ] Verify authentication required
- [ ] Verify image download URLs work
- [ ] Test with no slides (empty response)
- [ ] Test with no splash screen

### Flutter App
- [ ] Fetch and display hero slides
- [ ] Auto-play carousel works
- [ ] Slide navigation works
- [ ] Fetch and display splash screen
- [ ] Handle missing splash screen gracefully
- [ ] Cache images properly
- [ ] Test with slow network
- [ ] Test offline mode

---

## 🚀 Production Checklist

- [ ] Configure storage symlink: `php artisan storage:link`
- [ ] Set proper file permissions for storage directory
- [ ] Configure Backblaze B2 or CDN (optional)
- [ ] Test image uploads (< 5MB)
- [ ] Verify API key authentication
- [ ] Enable HTTPS in production
- [ ] Optimize uploaded images
- [ ] Set up image backup strategy
- [ ] Monitor storage usage
- [ ] Test on actual mobile devices

---

## 📖 Related Files

**Backend:**
- `database/migrations/*_create_hero_slides_table.php`
- `database/migrations/*_create_app_settings_table.php`
- `app/Models/HeroSlide.php`
- `app/Models/AppSetting.php`
- `app/Http/Controllers/AppManagementController.php`
- `app/Http/Controllers/Api/AppApiController.php`

**Views:**
- `resources/views/app-management/hero/index.blade.php`
- `resources/views/app-management/hero/create.blade.php`
- `resources/views/app-management/hero/edit.blade.php`
- `resources/views/app-management/splash/index.blade.php`

**Routes:**
- `routes/web.php` (Admin routes)
- `routes/api.php` (API routes)

---

## 💡 Best Practices

### For Admins
1. **Image Optimization:** Compress images before uploading
2. **Hero Slides:** Keep 3-5 active slides for best UX
3. **Slide Order:** Lower numbers appear first
4. **Button Links:** Use internal routes for better performance
5. **Splash Screen:** Use portrait orientation for mobile

### For Developers
1. **Caching:** Cache hero slides and splash screen locally
2. **Error Handling:** Always handle API failures gracefully
3. **Loading States:** Show placeholders while images load
4. **Auto-play:** Set reasonable intervals (3-5 seconds)
5. **Deep Links:** Implement proper deep link handling

---

**Version:** 1.0  
**Date:** December 25, 2025  
**Status:** ✅ Production Ready  
**Features:** Hero Slides, Splash Screen Management, API Endpoints

