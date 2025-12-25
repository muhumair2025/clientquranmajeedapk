# Flutter Android Developer Guide
## Content Management API Integration

---

## 📋 Table of Contents
1. [Quick Start](#quick-start)
2. [API Overview](#api-overview)
3. [Setup & Configuration](#setup--configuration)
4. [Models](#models)
5. [API Service Class](#api-service-class)
6. [Complete Implementation Examples](#complete-implementation-examples)
7. [Error Handling](#error-handling)
8. [Best Practices](#best-practices)

---

## 🚀 Quick Start

### API Base URL
```dart
// Development
const String API_BASE_URL = 'http://localhost:8000/api';

// Production - Replace with your actual domain
const String API_BASE_URL = 'https://yourdomain.com/api';
```

### API Authentication
**All requests require API key authentication:**

```dart
final headers = {
  'X-API-Key': 'YOUR_API_KEY_HERE',
  'Content-Type': 'application/json',
};
```

### Required Packages
Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  flutter_dotenv: ^5.1.0  # For secure API key storage
```

---

## 📊 API Overview

### Content Structure
```
Categories (Main Cards)
    └── Subcategories
        └── Contents/Materials (Text / Q&A / PDF)
```

### Available Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/categories` | GET | Get all categories |
| `/api/categories/{id}` | GET | Get category with subcategories |
| `/api/subcategories/{id}` | GET | Get subcategory with materials |
| `/api/contents/{id}` | GET | Get single material/content |
| `/api/search?q={query}` | GET | Search across all materials |

---

## ⚙️ Setup & Configuration

### 1. Create `.env` file in project root
```env
API_KEY=de9cc0578682fe54e2b7fc4702947a5080b57ce69bb002f45f18f688d283e4a4
API_BASE_URL=https://yourdomain.com/api
```

### 2. Load environment variables
```dart
// main.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

### 3. Add `.env` to `.gitignore`
```
.env
```

---

## 📦 Models

### Category Model
```dart
class Category {
  final int id;
  final CategoryNames names;
  final String? description;
  final String iconUrl;
  final String color;
  final int subcategoriesCount;

  Category({
    required this.id,
    required this.names,
    this.description,
    required this.iconUrl,
    required this.color,
    required this.subcategoriesCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      names: CategoryNames.fromJson(json['names']),
      description: json['description'],
      iconUrl: json['icon_url'],
      color: json['color'],
      subcategoriesCount: json['subcategories_count'],
    );
  }

  // Get name based on user's language preference
  String getName(String language) {
    switch (language) {
      case 'urdu':
        return names.urdu;
      case 'arabic':
        return names.arabic;
      case 'pashto':
        return names.pashto;
      default:
        return names.english;
    }
  }
}

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
      english: json['english'],
      urdu: json['urdu'],
      arabic: json['arabic'],
      pashto: json['pashto'],
    );
  }
}
```

### Subcategory Model
```dart
class Subcategory {
  final int id;
  final String name;
  final String? description;
  final int contentsCount;

  Subcategory({
    required this.id,
    required this.name,
    this.description,
    required this.contentsCount,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      contentsCount: json['contents_count'],
    );
  }
}
```

### Subcategory Detail Model (with parent category and contents)
```dart
class SubcategoryDetail {
  final int id;
  final String name;
  final String? description;
  final CategoryInfo category;
  final List<Content> contents;

  SubcategoryDetail({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.contents,
  });

  factory SubcategoryDetail.fromJson(Map<String, dynamic> json) {
    return SubcategoryDetail(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      category: CategoryInfo.fromJson(json['category']),
      contents: (json['contents'] as List)
          .map((content) => Content.fromJson(content))
          .toList(),
    );
  }
}

class CategoryInfo {
  final int id;
  final CategoryNames names;
  final String iconUrl;
  final String color;

  CategoryInfo({
    required this.id,
    required this.names,
    required this.iconUrl,
    required this.color,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['id'],
      names: CategoryNames.fromJson(json['names']),
      iconUrl: json['icon_url'],
      color: json['color'],
    );
  }
}
```

### Content/Material Model
```dart
enum ContentType { text, qa, pdf }

class Content {
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

  Content({
    required this.id,
    required this.type,
    required this.title,
    this.textContent,
    this.question,
    this.answer,
    this.pdfUrl,
  });

  factory Content.fromJson(Map<String, dynamic> json) {
    ContentType type;
    switch (json['type']) {
      case 'qa':
        type = ContentType.qa;
        break;
      case 'pdf':
        type = ContentType.pdf;
        break;
      default:
        type = ContentType.text;
    }

    return Content(
      id: json['id'],
      type: type,
      title: json['title'],
      textContent: json['text_content'],
      question: json['question'],
      answer: json['answer'],
      pdfUrl: json['pdf_url'],
    );
  }
}
```

### API Response Model
```dart
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? fromJsonT(json['data']) : null,
    );
  }
}
```

---

## 🔌 API Service Class

### Complete API Service Implementation

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  // Get API configuration from environment
  static final String _baseUrl = dotenv.env['API_BASE_URL'] ?? '';
  static final String _apiKey = dotenv.env['API_KEY'] ?? '';

  // HTTP headers with authentication
  static Map<String, String> get _headers => {
    'X-API-Key': _apiKey,
    'Content-Type': 'application/json',
  };

  // Timeout duration
  static const Duration _timeout = Duration(seconds: 30);

  /// Get all categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/categories'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 401) {
        throw ApiException('Unauthorized: Invalid API key');
      }

      if (response.statusCode != 200) {
        throw ApiException('Failed to load categories: ${response.statusCode}');
      }

      final jsonData = json.decode(response.body);
      
      if (!jsonData['success']) {
        throw ApiException(jsonData['message'] ?? 'Unknown error');
      }

      final List categoriesJson = jsonData['data'];
      return categoriesJson
          .map((categoryJson) => Category.fromJson(categoryJson))
          .toList();
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Get single category with its subcategories
  Future<CategoryDetail> getCategory(int categoryId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/categories/$categoryId'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 404) {
        throw ApiException('Category not found');
      }

      if (response.statusCode == 401) {
        throw ApiException('Unauthorized: Invalid API key');
      }

      if (response.statusCode != 200) {
        throw ApiException('Failed to load category: ${response.statusCode}');
      }

      final jsonData = json.decode(response.body);
      
      if (!jsonData['success']) {
        throw ApiException(jsonData['message'] ?? 'Unknown error');
      }

      return CategoryDetail.fromJson(jsonData['data']);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Get subcategory with its materials/contents
  Future<SubcategoryDetail> getSubcategory(int subcategoryId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/subcategories/$subcategoryId'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 404) {
        throw ApiException('Subcategory not found');
      }

      if (response.statusCode == 401) {
        throw ApiException('Unauthorized: Invalid API key');
      }

      if (response.statusCode != 200) {
        throw ApiException('Failed to load subcategory: ${response.statusCode}');
      }

      final jsonData = json.decode(response.body);
      
      if (!jsonData['success']) {
        throw ApiException(jsonData['message'] ?? 'Unknown error');
      }

      return SubcategoryDetail.fromJson(jsonData['data']);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Get single content/material item
  Future<ContentDetail> getContent(int contentId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/contents/$contentId'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 404) {
        throw ApiException('Content not found');
      }

      if (response.statusCode == 401) {
        throw ApiException('Unauthorized: Invalid API key');
      }

      if (response.statusCode != 200) {
        throw ApiException('Failed to load content: ${response.statusCode}');
      }

      final jsonData = json.decode(response.body);
      
      if (!jsonData['success']) {
        throw ApiException(jsonData['message'] ?? 'Unknown error');
      }

      return ContentDetail.fromJson(jsonData['data']);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }

  /// Search content across all materials
  Future<SearchResult> search(String query) async {
    if (query.trim().isEmpty) {
      throw ApiException('Search query cannot be empty');
    }

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/search?q=${Uri.encodeComponent(query)}'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 401) {
        throw ApiException('Unauthorized: Invalid API key');
      }

      if (response.statusCode != 200) {
        throw ApiException('Failed to search: ${response.statusCode}');
      }

      final jsonData = json.decode(response.body);
      
      if (!jsonData['success']) {
        throw ApiException(jsonData['message'] ?? 'Unknown error');
      }

      return SearchResult.fromJson(jsonData);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: $e');
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
```

### Additional Models for API Service

```dart
class CategoryDetail {
  final int id;
  final CategoryNames names;
  final String? description;
  final String iconUrl;
  final String color;
  final List<Subcategory> subcategories;

  CategoryDetail({
    required this.id,
    required this.names,
    this.description,
    required this.iconUrl,
    required this.color,
    required this.subcategories,
  });

  factory CategoryDetail.fromJson(Map<String, dynamic> json) {
    return CategoryDetail(
      id: json['id'],
      names: CategoryNames.fromJson(json['names']),
      description: json['description'],
      iconUrl: json['icon_url'],
      color: json['color'],
      subcategories: (json['subcategories'] as List)
          .map((sub) => Subcategory.fromJson(sub))
          .toList(),
    );
  }
}

class ContentDetail {
  final int id;
  final ContentType type;
  final String title;
  final String? textContent;
  final String? question;
  final String? answer;
  final String? pdfUrl;
  final SubcategoryInfo subcategory;
  final CategoryInfo category;

  ContentDetail({
    required this.id,
    required this.type,
    required this.title,
    this.textContent,
    this.question,
    this.answer,
    this.pdfUrl,
    required this.subcategory,
    required this.category,
  });

  factory ContentDetail.fromJson(Map<String, dynamic> json) {
    ContentType type;
    switch (json['type']) {
      case 'qa':
        type = ContentType.qa;
        break;
      case 'pdf':
        type = ContentType.pdf;
        break;
      default:
        type = ContentType.text;
    }

    return ContentDetail(
      id: json['id'],
      type: type,
      title: json['title'],
      textContent: json['text_content'],
      question: json['question'],
      answer: json['answer'],
      pdfUrl: json['pdf_url'],
      subcategory: SubcategoryInfo.fromJson(json['subcategory']),
      category: CategoryInfo.fromJson(json['category']),
    );
  }
}

class SubcategoryInfo {
  final int id;
  final String name;

  SubcategoryInfo({
    required this.id,
    required this.name,
  });

  factory SubcategoryInfo.fromJson(Map<String, dynamic> json) {
    return SubcategoryInfo(
      id: json['id'],
      name: json['name'],
    );
  }
}

class SearchResult {
  final String query;
  final int resultsCount;
  final List<SearchItem> results;

  SearchResult({
    required this.query,
    required this.resultsCount,
    required this.results,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      query: json['query'],
      resultsCount: json['results_count'],
      results: (json['data'] as List)
          .map((item) => SearchItem.fromJson(item))
          .toList(),
    );
  }
}

class SearchItem {
  final int id;
  final ContentType type;
  final String title;
  final String preview;
  final SubcategoryInfo subcategory;
  final CategoryInfo category;

  SearchItem({
    required this.id,
    required this.type,
    required this.title,
    required this.preview,
    required this.subcategory,
    required this.category,
  });

  factory SearchItem.fromJson(Map<String, dynamic> json) {
    ContentType type;
    switch (json['type']) {
      case 'qa':
        type = ContentType.qa;
        break;
      case 'pdf':
        type = ContentType.pdf;
        break;
      default:
        type = ContentType.text;
    }

    return SearchItem(
      id: json['id'],
      type: type,
      title: json['title'],
      preview: json['preview'] ?? '',
      subcategory: SubcategoryInfo.fromJson(json['subcategory']),
      category: CategoryInfo.fromJson(json['category']),
    );
  }
}
```

---

## 💻 Complete Implementation Examples

### 1. Categories Screen (Home Screen)

```dart
import 'package:flutter/material.dart';

class CategoriesScreen extends StatefulWidget {
  @override
  _CategoriesScreenState createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final ApiService _apiService = ApiService();
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;
  String _selectedLanguage = 'english';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categories = await _apiService.getCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Categories'),
        actions: [
          // Language selector
          PopupMenuButton<String>(
            initialValue: _selectedLanguage,
            onSelected: (String language) {
              setState(() {
                _selectedLanguage = language;
              });
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem(value: 'english', child: Text('English')),
              PopupMenuItem(value: 'urdu', child: Text('اردو')),
              PopupMenuItem(value: 'arabic', child: Text('العربية')),
              PopupMenuItem(value: 'pashto', child: Text('پښتو')),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCategories,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return Center(child: Text('No categories available'));
    }

    return RefreshIndicator(
      onRefresh: _loadCategories,
      child: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          return CategoryCard(
            category: _categories[index],
            language: _selectedLanguage,
            onTap: () => _navigateToCategory(_categories[index]),
          );
        },
      ),
    );
  }

  void _navigateToCategory(Category category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubcategoriesScreen(
          categoryId: category.id,
          language: _selectedLanguage,
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  final Category category;
  final String language;
  final VoidCallback onTap;

  const CategoryCard({
    Key? key,
    required this.category,
    required this.language,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categoryName = category.getName(language);
    final color = _parseColor(category.color);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Category Icon
            Image.network(
              category.iconUrl,
              width: 64,
              height: 64,
              errorBuilder: (context, error, stackTrace) {
                return Icon(Icons.category, size: 64, color: color);
              },
            ),
            SizedBox(height: 12),
            // Category Name
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                categoryName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 4),
            // Subcategories count
            Text(
              '${category.subcategoriesCount} topics',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.blue;
    }
  }
}
```

### 2. Subcategories Screen

```dart
class SubcategoriesScreen extends StatefulWidget {
  final int categoryId;
  final String language;

  const SubcategoriesScreen({
    Key? key,
    required this.categoryId,
    required this.language,
  }) : super(key: key);

  @override
  _SubcategoriesScreenState createState() => _SubcategoriesScreenState();
}

class _SubcategoriesScreenState extends State<SubcategoriesScreen> {
  final ApiService _apiService = ApiService();
  CategoryDetail? _categoryDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategoryDetail();
  }

  Future<void> _loadCategoryDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categoryDetail = await _apiService.getCategory(widget.categoryId);
      setState(() {
        _categoryDetail = categoryDetail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_categoryDetail != null
            ? _getCategoryName(_categoryDetail!)
            : 'Subcategories'),
      ),
      body: _buildBody(),
    );
  }

  String _getCategoryName(CategoryDetail category) {
    switch (widget.language) {
      case 'urdu':
        return category.names.urdu;
      case 'arabic':
        return category.names.arabic;
      case 'pashto':
        return category.names.pashto;
      default:
        return category.names.english;
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCategoryDetail,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_categoryDetail == null || _categoryDetail!.subcategories.isEmpty) {
      return Center(child: Text('No subcategories available'));
    }

    return RefreshIndicator(
      onRefresh: _loadCategoryDetail,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _categoryDetail!.subcategories.length,
        itemBuilder: (context, index) {
          final subcategory = _categoryDetail!.subcategories[index];
          return SubcategoryListItem(
            subcategory: subcategory,
            onTap: () => _navigateToMaterials(subcategory),
          );
        },
      ),
    );
  }

  void _navigateToMaterials(Subcategory subcategory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialsScreen(
          subcategoryId: subcategory.id,
          subcategoryName: subcategory.name,
        ),
      ),
    );
  }
}

class SubcategoryListItem extends StatelessWidget {
  final Subcategory subcategory;
  final VoidCallback onTap;

  const SubcategoryListItem({
    Key? key,
    required this.subcategory,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.folder, color: Colors.white),
        ),
        title: Text(
          subcategory.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: subcategory.description != null
            ? Text(subcategory.description!)
            : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article, color: Colors.grey),
            SizedBox(height: 4),
            Text(
              '${subcategory.contentsCount}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
```

### 3. Materials/Contents Screen

```dart
class MaterialsScreen extends StatefulWidget {
  final int subcategoryId;
  final String subcategoryName;

  const MaterialsScreen({
    Key? key,
    required this.subcategoryId,
    required this.subcategoryName,
  }) : super(key: key);

  @override
  _MaterialsScreenState createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final ApiService _apiService = ApiService();
  SubcategoryDetail? _subcategoryDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subcategoryDetail = await _apiService.getSubcategory(widget.subcategoryId);
      setState(() {
        _subcategoryDetail = subcategoryDetail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subcategoryName),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMaterials,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_subcategoryDetail == null || _subcategoryDetail!.contents.isEmpty) {
      return Center(child: Text('No materials available'));
    }

    return RefreshIndicator(
      onRefresh: _loadMaterials,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _subcategoryDetail!.contents.length,
        itemBuilder: (context, index) {
          final content = _subcategoryDetail!.contents[index];
          return MaterialListItem(
            content: content,
            onTap: () => _navigateToContentDetail(content),
          );
        },
      ),
    );
  }

  void _navigateToContentDetail(Content content) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(contentId: content.id),
      ),
    );
  }
}

class MaterialListItem extends StatelessWidget {
  final Content content;
  final VoidCallback onTap;

  const MaterialListItem({
    Key? key,
    required this.content,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: _getIconForContentType(content.type),
        title: Text(
          content.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(_getSubtitleForContentType(content.type)),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _getIconForContentType(ContentType type) {
    IconData icon;
    Color color;

    switch (type) {
      case ContentType.text:
        icon = Icons.article;
        color = Colors.blue;
        break;
      case ContentType.qa:
        icon = Icons.question_answer;
        color = Colors.green;
        break;
      case ContentType.pdf:
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color),
    );
  }

  String _getSubtitleForContentType(ContentType type) {
    switch (type) {
      case ContentType.text:
        return 'Text Article';
      case ContentType.qa:
        return 'Question & Answer';
      case ContentType.pdf:
        return 'PDF Document';
    }
  }
}
```

### 4. Content Detail Screen

```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContentDetailScreen extends StatefulWidget {
  final int contentId;

  const ContentDetailScreen({
    Key? key,
    required this.contentId,
  }) : super(key: key);

  @override
  _ContentDetailScreenState createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  final ApiService _apiService = ApiService();
  ContentDetail? _contentDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContentDetail();
  }

  Future<void> _loadContentDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final contentDetail = await _apiService.getContent(widget.contentId);
      setState(() {
        _contentDetail = contentDetail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_contentDetail?.title ?? 'Loading...'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContentDetail,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_contentDetail == null) {
      return Center(child: Text('Content not available'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          _buildBreadcrumb(),
          SizedBox(height: 24),
          
          // Content based on type
          _buildContentWidget(),
        ],
      ),
    );
  }

  Widget _buildBreadcrumb() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_contentDetail!.category.names.english} > ${_contentDetail!.subcategory.name}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentWidget() {
    switch (_contentDetail!.type) {
      case ContentType.text:
        return _buildTextContent();
      case ContentType.qa:
        return _buildQAContent();
      case ContentType.pdf:
        return _buildPDFContent();
    }
  }

  Widget _buildTextContent() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.article, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _contentDetail!.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            Divider(height: 32),
            Text(
              _contentDetail!.textContent ?? '',
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQAContent() {
    return Column(
      children: [
        // Question Card
        Card(
          color: Colors.blue[50],
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Question',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  _contentDetail!.question ?? '',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        
        // Answer Card
        Card(
          color: Colors.green[50],
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Answer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  _contentDetail!.answer ?? '',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPDFContent() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.picture_as_pdf, size: 80, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _contentDetail!.title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _openPDF(_contentDetail!.pdfUrl!),
              icon: Icon(Icons.open_in_new),
              label: Text('Open PDF Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPDF(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open PDF')),
      );
    }
  }
}
```

### 5. Search Screen

```dart
class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<SearchItem> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final searchResult = await _apiService.search(query);
      setState(() {
        _searchResults = searchResult.results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search materials...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: TextStyle(color: Colors.white),
          onSubmitted: _performSearch,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search for materials',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return SearchResultCard(
          item: item,
          onTap: () => _navigateToContent(item.id),
        );
      },
    );
  }

  void _navigateToContent(int contentId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContentDetailScreen(contentId: contentId),
      ),
    );
  }
}

class SearchResultCard extends StatelessWidget {
  final SearchItem item;
  final VoidCallback onTap;

  const SearchResultCard({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with icon
              Row(
                children: [
                  _getIconForContentType(item.type),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              
              // Preview
              Text(
                item.preview,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              
              // Breadcrumb
              Text(
                '${item.category.names.english} > ${item.subcategory.name}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getIconForContentType(ContentType type) {
    IconData icon;
    Color color;

    switch (type) {
      case ContentType.text:
        icon = Icons.article;
        color = Colors.blue;
        break;
      case ContentType.qa:
        icon = Icons.question_answer;
        color = Colors.green;
        break;
      case ContentType.pdf:
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
    }

    return Icon(icon, color: color, size: 20);
  }
}
```

---

## ⚠️ Error Handling

### Common Errors and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| 401 Unauthorized | Invalid/missing API key | Check API key in `.env` file |
| 404 Not Found | Resource doesn't exist | Verify ID is correct |
| Timeout Exception | Slow network/server down | Implement retry logic |
| Format Exception | Invalid JSON response | Check API response format |

### Error Handling Best Practices

```dart
// 1. Use try-catch blocks
try {
  final categories = await apiService.getCategories();
  // Process data
} on ApiException catch (e) {
  // Handle API-specific errors
  showError(e.message);
} on TimeoutException catch (e) {
  // Handle timeout
  showError('Request timed out. Please try again.');
} catch (e) {
  // Handle unexpected errors
  showError('An unexpected error occurred');
}

// 2. Show user-friendly error messages
void showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      action: SnackBarAction(
        label: 'Retry',
        textColor: Colors.white,
        onPressed: () => retryOperation(),
      ),
    ),
  );
}

// 3. Implement offline detection
Future<bool> isConnected() async {
  var connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

// 4. Add loading states
bool _isLoading = false;
String? _error;
List<Category>? _data;
```

---

## ✅ Best Practices

### 1. Security
- ✅ Store API key in `.env` file (NEVER in code)
- ✅ Add `.env` to `.gitignore`
- ✅ Use HTTPS in production
- ✅ Validate all API responses
- ✅ Handle 401 errors properly

### 2. Performance
- ✅ Implement caching for frequently accessed data
- ✅ Use pagination for large lists
- ✅ Lazy load images
- ✅ Implement pull-to-refresh
- ✅ Set reasonable timeouts (30 seconds)

### 3. User Experience
- ✅ Show loading indicators
- ✅ Display helpful error messages
- ✅ Implement retry functionality
- ✅ Add empty state screens
- ✅ Support offline mode (cached data)

### 4. Code Organization
- ✅ Separate models, services, and UI
- ✅ Use constants for API URLs and keys
- ✅ Create reusable widgets
- ✅ Follow Flutter naming conventions

### 5. Multilingual Support
- ✅ Detect device language
- ✅ Allow manual language selection
- ✅ Support RTL languages (Urdu, Arabic, Pashto)
- ✅ Fallback to English if translation missing

```dart
// RTL Language Detection
bool isRTL(String language) {
  return ['urdu', 'arabic', 'pashto'].contains(language);
}

// Apply RTL in MaterialApp
MaterialApp(
  builder: (context, child) {
    return Directionality(
      textDirection: isRTL(selectedLanguage) 
          ? TextDirection.rtl 
          : TextDirection.ltr,
      child: child!,
    );
  },
  // ... rest of app
);
```

### 6. Testing
```dart
// Example unit test for API service
test('getCategories returns list of categories', () async {
  final apiService = ApiService();
  final categories = await apiService.getCategories();
  
  expect(categories, isA<List<Category>>());
  expect(categories.isNotEmpty, true);
});
```

---

## 📝 API Quick Reference

### All Endpoints

```dart
// 1. Get all categories
final categories = await apiService.getCategories();

// 2. Get category with subcategories
final category = await apiService.getCategory(categoryId);

// 3. Get subcategory with materials
final subcategory = await apiService.getSubcategory(subcategoryId);

// 4. Get single content/material
final content = await apiService.getContent(contentId);

// 5. Search
final searchResult = await apiService.search('query');
```

### Response Structure

All successful responses follow this format:
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { /* your data here */ }
}
```

---

## 🎯 Complete Project Structure

```
lib/
├── main.dart
├── models/
│   ├── category.dart
│   ├── subcategory.dart
│   ├── content.dart
│   └── api_response.dart
├── services/
│   └── api_service.dart
├── screens/
│   ├── categories_screen.dart
│   ├── subcategories_screen.dart
│   ├── materials_screen.dart
│   ├── content_detail_screen.dart
│   └── search_screen.dart
└── widgets/
    ├── category_card.dart
    ├── subcategory_list_item.dart
    ├── material_list_item.dart
    └── error_widget.dart
```

---

## 🚀 Production Checklist

Before deploying to production:

- [ ] Replace API_BASE_URL with production URL
- [ ] Verify API key is correct
- [ ] Enable HTTPS
- [ ] Test all endpoints
- [ ] Implement proper error handling
- [ ] Add loading states
- [ ] Test with slow network
- [ ] Test offline mode
- [ ] Verify RTL language support
- [ ] Test on multiple devices
- [ ] Optimize image loading
- [ ] Add analytics (optional)
- [ ] Setup crash reporting (optional)

---

## 📞 Support

For API issues or questions:
1. Check error messages carefully
2. Verify API key is correct
3. Test endpoints in Postman/cURL first
4. Check server logs
5. Review this documentation

---

**Version:** 1.0  
**Last Updated:** December 2025  
**Framework:** Flutter 3.x  
**Minimum SDK:** Android 21 (Lollipop)  
**Status:** ✅ Production Ready

---

## 🎉 You're All Set!

Your Flutter app is now ready to fetch and display:
- ✅ Categories
- ✅ Subcategories
- ✅ Materials/Contents (Text, Q&A, PDF)
- ✅ Search functionality
- ✅ Multilingual support

Happy coding! 🚀

