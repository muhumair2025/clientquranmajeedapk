import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorite_ayahs';
  static List<String> _favoriteAyahs = [];
  static bool _isLoaded = false;

  /// Initialize the favorites service by loading data from SharedPreferences
  static Future<void> initialize() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoritesKey);
      
      if (favoritesJson != null) {
        debugPrint('FavoritesService: Found existing data, attempting to load...');
        
        // Try multiple approaches to handle the data
        bool dataLoaded = false;
        
        // Approach 1: Decode JSON and handle different data types
        try {
          final dynamic rawData = json.decode(favoritesJson);
          debugPrint('FavoritesService: Raw data type: ${rawData.runtimeType}');
          debugPrint('FavoritesService: Raw data content: $rawData');
          
          if (rawData is List) {
            // Handle List<dynamic> - convert to List<String>
            _favoriteAyahs = List<String>.from(rawData.map((item) => item.toString()));
            dataLoaded = true;
            debugPrint('FavoritesService: Successfully loaded as List with ${_favoriteAyahs.length} items');
          } else if (rawData is Set) {
            // Handle Set - convert to List<String>
            _favoriteAyahs = List<String>.from(rawData.map((item) => item.toString()));
            dataLoaded = true;
            debugPrint('FavoritesService: Successfully converted Set to List with ${_favoriteAyahs.length} items');
          } else if (rawData is Map) {
            // Handle Map - use values and convert to List<String>
            _favoriteAyahs = List<String>.from(rawData.values.map((item) => item.toString()));
            dataLoaded = true;
            debugPrint('FavoritesService: Successfully converted Map to List with ${_favoriteAyahs.length} items');
          } else {
            // Handle other types - try to convert to string and split if needed
            final stringData = rawData.toString();
            if (stringData.startsWith('[') && stringData.endsWith(']')) {
              // Looks like a list string representation
              final cleanString = stringData.substring(1, stringData.length - 1);
              _favoriteAyahs = cleanString.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
              dataLoaded = true;
              debugPrint('FavoritesService: Successfully parsed string representation to List with ${_favoriteAyahs.length} items');
            }
          }
        } catch (e1) {
          debugPrint('FavoritesService: Failed to decode JSON: $e1');
          debugPrint('FavoritesService: Raw JSON string: $favoritesJson');
          
          // Fallback: Try to parse as string if it looks like a simple list
          try {
            if (favoritesJson.startsWith('[') && favoritesJson.endsWith(']')) {
              final cleanString = favoritesJson.substring(1, favoritesJson.length - 1);
              _favoriteAyahs = cleanString.split(',')
                  .map((s) => s.trim().replaceAll('"', ''))
                  .where((s) => s.isNotEmpty)
                  .toList();
              dataLoaded = true;
              debugPrint('FavoritesService: Successfully parsed fallback string to List with ${_favoriteAyahs.length} items');
            }
          } catch (e2) {
            debugPrint('FavoritesService: Fallback parsing also failed: $e2');
          }
        }
        
        // If all approaches failed, reset the data
        if (!dataLoaded) {
          debugPrint('FavoritesService: All loading approaches failed, resetting data');
          _favoriteAyahs = [];
          await prefs.remove(_favoritesKey);
          debugPrint('FavoritesService: Cleared corrupted data from SharedPreferences');
        }
      } else {
        debugPrint('FavoritesService: No existing favorites data found');
        _favoriteAyahs = [];
      }
      
      _isLoaded = true;
      debugPrint('FavoritesService: Initialization complete. Final count: ${_favoriteAyahs.length} favorite ayahs');
    } catch (e) {
      debugPrint('FavoritesService: Critical error during initialization: $e');
      _favoriteAyahs = [];
      _isLoaded = true;
    }
  }

  /// Save favorites to SharedPreferences
  static Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = json.encode(_favoriteAyahs);
      await prefs.setString(_favoritesKey, favoritesJson);
      debugPrint('Saved ${_favoriteAyahs.length} favorite ayahs');
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  /// Add an ayah to favorites
  static Future<bool> addToFavorites(int surahIndex, int ayahIndex) async {
    await initialize();
    
    final key = '${surahIndex}_$ayahIndex';
    if (_favoriteAyahs.contains(key)) {
      return false; // Already in favorites
    }
    
    // Add to the beginning of the list to show newest first
    _favoriteAyahs.insert(0, key);
    await _saveFavorites();
    return true;
  }

  /// Remove an ayah from favorites
  static Future<bool> removeFromFavorites(int surahIndex, int ayahIndex) async {
    await initialize();
    
    final key = '${surahIndex}_$ayahIndex';
    if (!_favoriteAyahs.contains(key)) {
      return false; // Not in favorites
    }
    
    _favoriteAyahs.remove(key);
    await _saveFavorites();
    return true;
  }

  /// Toggle favorite status of an ayah
  static Future<bool> toggleFavorite(int surahIndex, int ayahIndex) async {
    await initialize();
    
    final key = '${surahIndex}_$ayahIndex';
    if (_favoriteAyahs.contains(key)) {
      await removeFromFavorites(surahIndex, ayahIndex);
      return false; // Removed from favorites
    } else {
      await addToFavorites(surahIndex, ayahIndex);
      return true; // Added to favorites
    }
  }

  /// Check if an ayah is in favorites
  static Future<bool> isFavorite(int surahIndex, int ayahIndex) async {
    await initialize();
    final key = '${surahIndex}_$ayahIndex';
    return _favoriteAyahs.contains(key);
  }

  /// Get all favorite ayahs
  static Future<List<FavoriteAyah>> getAllFavorites() async {
    await initialize();
    
    List<FavoriteAyah> favorites = [];
    for (String key in _favoriteAyahs) {
      final parts = key.split('_');
      if (parts.length == 2) {
        final surahIndex = int.tryParse(parts[0]);
        final ayahIndex = int.tryParse(parts[1]);
        
        if (surahIndex != null && ayahIndex != null) {
          favorites.add(FavoriteAyah(
            surahIndex: surahIndex,
            ayahIndex: ayahIndex,
          ));
        }
      }
    }
    
    // Return favorites in the order they were added (newest first)
    return favorites;
  }

  /// Get count of favorite ayahs
  static Future<int> getFavoritesCount() async {
    await initialize();
    return _favoriteAyahs.length;
  }

  /// Clear all favorites
  static Future<void> clearAllFavorites() async {
    await initialize();
    _favoriteAyahs.clear();
    await _saveFavorites();
  }

  /// Reset favorites data (useful for fixing corrupted data)
  static Future<void> resetFavoritesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
      _favoriteAyahs = [];
      _isLoaded = false;
      debugPrint('Favorites data has been reset');
    } catch (e) {
      debugPrint('Error resetting favorites data: $e');
    }
  }

  /// Force re-initialization (useful when data format changes)
  static Future<void> forceReInitialize() async {
    _isLoaded = false;
    await initialize();
  }

  /// Get favorites grouped by surah
  static Future<Map<int, List<FavoriteAyah>>> getFavoritesBySurah() async {
    final favorites = await getAllFavorites();
    Map<int, List<FavoriteAyah>> groupedFavorites = {};
    
    for (var favorite in favorites) {
      if (!groupedFavorites.containsKey(favorite.surahIndex)) {
        groupedFavorites[favorite.surahIndex] = [];
      }
      groupedFavorites[favorite.surahIndex]!.add(favorite);
    }
    
    return groupedFavorites;
  }

  /// Get favorites grouped by para
  static Future<Map<int, List<FavoriteAyah>>> getFavoritesByPara() async {
    final favorites = await getAllFavorites();
    Map<int, List<FavoriteAyah>> groupedFavorites = {};
    
    for (var favorite in favorites) {
      final paraNumber = _getParaNumberForSurah(favorite.surahIndex);
      if (!groupedFavorites.containsKey(paraNumber)) {
        groupedFavorites[paraNumber] = [];
      }
      groupedFavorites[paraNumber]!.add(favorite);
    }
    
    return groupedFavorites;
  }

  /// Helper method to get para number for a surah
  static int _getParaNumberForSurah(int surahIndex) {
    // Para mapping for surahs
    final paraMapping = {
      1: 1, 2: 1,  // Para 1: Al-Fatiha, Al-Baqarah (start)
      3: 3, 4: 4,  // Para 3: Aal-e-Imran, Para 4: An-Nisa
      5: 6, 6: 7,  // Para 6: Al-Maidah, Para 7: Al-An'am
      7: 8, 8: 9, 9: 10,  // Para 8-10
      10: 11, 11: 11,  // Para 11: Yunus, Hud
      12: 12, 13: 13, 14: 13,  // Para 12-13
      15: 14, 16: 14,  // Para 14
      17: 15, 18: 15, 19: 16, 20: 16,  // Para 15-16
      21: 17, 22: 17, 23: 18, 24: 18, 25: 18,  // Para 17-18
      26: 19, 27: 19, 28: 20, 29: 21,  // Para 19-21
      30: 21, 31: 21, 32: 21, 33: 21, 34: 22, 35: 22, 36: 22,  // Para 21-22
      37: 23, 38: 23, 39: 23, 40: 24, 41: 24,  // Para 23-24
      42: 25, 43: 25, 44: 25, 45: 25, 46: 26,  // Para 25-26
      47: 26, 48: 26, 49: 26, 50: 26, 51: 26,  // Para 26
      52: 27, 53: 27, 54: 27, 55: 27, 56: 27, 57: 27,  // Para 27
      58: 28, 59: 28, 60: 28, 61: 28, 62: 28, 63: 28, 64: 28, 65: 28, 66: 28,  // Para 28
      67: 29, 68: 29, 69: 29, 70: 29, 71: 29, 72: 29, 73: 29, 74: 29, 75: 29, 76: 29, 77: 29,  // Para 29
      78: 30, 79: 30, 80: 30, 81: 30, 82: 30, 83: 30, 84: 30, 85: 30, 86: 30, 87: 30,  // Para 30
      88: 30, 89: 30, 90: 30, 91: 30, 92: 30, 93: 30, 94: 30, 95: 30, 96: 30, 97: 30,
      98: 30, 99: 30, 100: 30, 101: 30, 102: 30, 103: 30, 104: 30, 105: 30, 106: 30,
      107: 30, 108: 30, 109: 30, 110: 30, 111: 30, 112: 30, 113: 30, 114: 30
    };
    
    return paraMapping[surahIndex] ?? 1;
  }
}

/// Model class for favorite ayah
class FavoriteAyah {
  final int surahIndex;
  final int ayahIndex;
  
  FavoriteAyah({
    required this.surahIndex,
    required this.ayahIndex,
  });

  String get key => '${surahIndex}_$ayahIndex';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteAyah &&
          runtimeType == other.runtimeType &&
          surahIndex == other.surahIndex &&
          ayahIndex == other.ayahIndex;

  @override
  int get hashCode => surahIndex.hashCode ^ ayahIndex.hashCode;

  @override
  String toString() => 'FavoriteAyah(surahIndex: $surahIndex, ayahIndex: $ayahIndex)';
}
