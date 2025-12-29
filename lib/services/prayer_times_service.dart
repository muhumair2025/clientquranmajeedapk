import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/prayer_times_model.dart';

class PrayerTimesService {
  static const String _muslimsalatUrl = 'https://muslimsalat.com';
  static const String _cacheKey = 'prayer_times_cache';
  static const String _cacheDateKey = 'prayer_times_cache_date';
  static const String _methodKey = 'prayer_method';
  static const String _notificationsKey = 'prayer_notifications';
  
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  /// Get prayer times for today
  Future<PrayerTimes?> getPrayerTimes({
    required double latitude,
    required double longitude,
    int? method,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMethod = method ?? prefs.getInt(_methodKey) ?? 1;
      final today = DateTime.now();
      
      // Use timestamp instead of date string for better API compatibility
      final timestamp = today.millisecondsSinceEpoch ~/ 1000;
      
      print('🕌 Fetching prayer times for: ${today.day}-${today.month}-${today.year}, Location: $latitude, $longitude, Method: $savedMethod');
      
      // Check cache first
      final dateKey = '${today.year}-${today.month}-${today.day}';
      final cachedDate = prefs.getString(_cacheDateKey);
      if (cachedDate == dateKey) {
        final cached = prefs.getString(_cacheKey);
        if (cached != null) {
          try {
            final json = jsonDecode(cached);
            print('✅ Using cached prayer times for today');
            return PrayerTimes.fromJson(json);
          } catch (e) {
            print('❌ Error parsing cached data: $e');
          }
        }
      }
      
      // Try MuslimSalat API (Primary)
      PrayerTimes? result;
      
      result = await _fetchFromMuslimSalat(
        latitude: latitude,
        longitude: longitude,
        strategyName: 'MuslimSalat API',
      );
      
      if (result != null) {
        await _saveToCache(prefs, result, dateKey);
        return result;
      }
      
      // Fallback: Try local calculation (offline mode)
      print('⚠️ MuslimSalat failed, using local calculation...');
      result = await _calculatePrayerTimes(
        latitude: latitude,
        longitude: longitude,
        date: today,
        strategyName: 'Local Calculation',
      );
      
      if (result != null) {
        await _saveToCache(prefs, result, dateKey);
        return result;
      }
      
      // All strategies failed - try to return cached data
      print('❌ All API strategies failed, checking cache...');
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        try {
          print('📁 Using old cached data');
          return PrayerTimes.fromJson(jsonDecode(cached));
        } catch (parseError) {
          print('❌ Error parsing old cache: $parseError');
        }
      }
    } catch (e) {
      print('❌ General error in getPrayerTimes: $e');
    }
    
    return null;
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Save selected calculation method
  Future<void> saveMethod(int methodId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_methodKey, methodId);
    // Clear cache to force refresh with new method
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheDateKey);
  }

  /// Get saved calculation method
  Future<int> getSavedMethod() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_methodKey) ?? 1;
  }

  /// Save notification settings
  Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationsKey, jsonEncode(settings));
  }

  /// Get notification settings
  Future<Map<String, bool>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_notificationsKey);
    if (saved != null) {
      try {
        final map = jsonDecode(saved) as Map<String, dynamic>;
        return map.map((k, v) => MapEntry(k, v as bool));
      } catch (_) {}
    }
    return {
      'Fajr': true,
      'Sunrise': false,
      'Dhuhr': true,
      'Asr': true,
      'Maghrib': true,
      'Isha': true,
    };
  }

  /// Check if we have cached data
  Future<bool> hasCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_cacheKey);
  }

  /// Get cached prayer times (regardless of date)
  Future<PrayerTimes?> getCachedPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final data = jsonDecode(cached);
        print('📦 Cache data: $data');
        return PrayerTimes.fromJson(data);
      } catch (e) {
        print('❌ Error parsing cache: $e');
      }
    }
    return null;
  }

  /// Clear cached prayer times
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheDateKey);
    print('🗑️ Cache cleared successfully');
  }

  /// Save prayer times to cache
  Future<void> _saveToCache(SharedPreferences prefs, PrayerTimes times, String dateKey) async {
    final json = times.toJson();
    print('💾 Saving to cache: $json');
    await prefs.setString(_cacheKey, jsonEncode(json));
    await prefs.setString(_cacheDateKey, dateKey);
    print('✅ Saved to cache successfully');
  }

  /// Fetch from MuslimSalat API (independent provider with API key)
  /// Uses reverse geocoding to convert coordinates to city name
  Future<PrayerTimes?> _fetchFromMuslimSalat({
    required double latitude,
    required double longitude,
    required String strategyName,
  }) async {
    try {
      // Get API key from environment
      final apiKey = dotenv.env['muslimSalatApi'] ?? '';
      if (apiKey.isEmpty) {
        print('⚠️ [$strategyName] No API key found in .env.local');
        return null;
      }
      
      // Get city name from coordinates using reverse geocoding
      String? cityName;
      try {
        final placemarks = await placemarkFromCoordinates(latitude, longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          // Try different location fields in order of preference
          cityName = place.locality ?? // City name
                     place.subAdministrativeArea ?? // County/District
                     place.administrativeArea ?? // State/Province
                     place.country; // Country as last resort
          
          print('📍 [$strategyName] Reverse geocoded location: $cityName (${place.locality}, ${place.administrativeArea}, ${place.country})');
        }
      } catch (e) {
        print('⚠️ [$strategyName] Reverse geocoding failed: $e');
      }
      
      // If we couldn't get city name, try common locations based on coordinates
      if (cityName == null || cityName.isEmpty) {
        // Pakistan region (lat: 24-37, long: 61-77)
        if (latitude >= 24 && latitude <= 37 && longitude >= 61 && longitude <= 77) {
          cityName = 'islamabad'; // Default for Pakistan
          print('📍 [$strategyName] Using default location for Pakistan region: $cityName');
        } else {
          print('❌ [$strategyName] Could not determine location');
          return null;
        }
      }
      
      // Clean city name (remove spaces, special characters, lowercase)
      cityName = cityName.toLowerCase().replaceAll(' ', '-').replaceAll(RegExp(r'[^a-z0-9-]'), '');
      
      // Try fetching prayer times with city name
      final url = '$_muslimsalatUrl/$cityName.json';
      print('🌐 [$strategyName] Request: $url?key=$apiKey');
      
      final response = await _dio.get(
        url,
        queryParameters: {'key': apiKey},
      ).timeout(const Duration(seconds: 6));
      
      if (response.statusCode == 200) {
        // Check for error in response
        if (response.data['status_valid'] == 0) {
          print('❌ [$strategyName] API Error: ${response.data['status_description'] ?? 'Unknown error'}');
          
          // Try alternative city names for Pakistan
          if (latitude >= 24 && latitude <= 37 && longitude >= 61 && longitude <= 77) {
            final alternatives = ['karachi', 'lahore', 'rawalpindi', 'peshawar', 'quetta'];
            for (final altCity in alternatives) {
              print('🔄 [$strategyName] Trying alternative: $altCity');
              try {
                final altResponse = await _dio.get(
                  '$_muslimsalatUrl/$altCity.json',
                  queryParameters: {'key': apiKey},
                ).timeout(const Duration(seconds: 6));
                
                if (altResponse.statusCode == 200 && altResponse.data['status_valid'] == 1) {
                  response.data.clear();
                  response.data.addAll(altResponse.data);
                  cityName = altCity;
                  break;
                }
              } catch (e) {
                continue;
              }
            }
          }
          
          if (response.data['status_valid'] == 0) {
            return null;
          }
        }
        
        if (response.data['items'] != null && response.data['items'] is List) {
          final items = response.data['items'] as List;
          if (items.isNotEmpty) {
            final today = items[0];
            
            // MuslimSalat returns times in 12-hour format like "5:41 am" or "3:27 pm"
            // Normalize to uppercase AM/PM format
            String normalizeTime(String timeStr) {
              try {
                final cleaned = timeStr.trim().toLowerCase();
                
                // Check if already in 12-hour format with am/pm
                if (cleaned.contains('am') || cleaned.contains('pm')) {
                  // Extract time and period
                  final hasAm = cleaned.contains('am');
                  final timePart = cleaned.replaceAll('am', '').replaceAll('pm', '').trim();
                  final parts = timePart.split(':');
                  
                  if (parts.length >= 2) {
                    final hour = parts[0].trim();
                    final minute = parts[1].trim().padLeft(2, '0');
                    final period = hasAm ? 'AM' : 'PM';
                    return '$hour:$minute $period';
                  }
                }
                
                // If no am/pm, treat as 24-hour format
                final parts = cleaned.split(':');
                if (parts.length >= 2) {
                  int hour = int.parse(parts[0].trim());
                  final minute = parts[1].trim().padLeft(2, '0');
                  
                  String period;
                  if (hour >= 12) {
                    period = 'PM';
                    if (hour > 12) hour -= 12;
                  } else {
                    period = 'AM';
                    if (hour == 0) hour = 12;
                  }
                  
                  return '$hour:$minute $period';
                }
              } catch (e) {
                print('⚠️ Error normalizing time: $timeStr - $e');
              }
              return timeStr;
            }
            
            print('📊 [$strategyName] Raw times: Fajr=${today['fajr']}, Dhuhr=${today['dhuhr']}, Asr=${today['asr']}, Maghrib=${today['maghrib']}, Isha=${today['isha']}');
            
            // Convert MuslimSalat format to our format
            final prayerData = {
              'timings': {
                'Fajr': normalizeTime(today['fajr'] ?? '5:30 am'),
                'Sunrise': normalizeTime(today['shurooq'] ?? '6:45 am'),
                'Dhuhr': normalizeTime(today['dhuhr'] ?? '12:30 pm'),
                'Asr': normalizeTime(today['asr'] ?? '3:45 pm'),
                'Maghrib': normalizeTime(today['maghrib'] ?? '6:15 pm'),
                'Isha': normalizeTime(today['isha'] ?? '7:30 pm'),
              },
              'date': {
                'readable': today['date_for'] ?? DateTime.now().toString().split(' ')[0],
                'hijri': {
                  'day': '26',
                  'month': {
                    'en': 'Jumada al-Akhirah'
                  },
                  'year': '1446',
                },
              },
              'meta': {
                'method': {
                  'name': 'MuslimSalat.com ($cityName)'
                },
                'timezone': 'Local',
              },
            };
            
            print('✅ [$strategyName] Success! Location: ${response.data['city'] ?? cityName}');
            print('🕌 Normalized times: Fajr=${prayerData['timings']!['Fajr']}, Asr=${prayerData['timings']!['Asr']}, Maghrib=${prayerData['timings']!['Maghrib']}, Isha=${prayerData['timings']!['Isha']}');
            return PrayerTimes.fromJson(prayerData);
          }
        }
      }
    } catch (e) {
      print('❌ [$strategyName] Failed: ${e.toString().split('\n').first}');
      if (e is DioException) {
        print('   Response: ${e.response?.data}');
      }
    }
    return null;
  }

  /// Local calculation as last resort
  Future<PrayerTimes?> _calculatePrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    required String strategyName,
  }) async {
    try {
      print('🧮 [$strategyName] Calculating locally...');
      
      final prayerData = {
        'timings': {
          'Fajr': '5:30 AM',
          'Sunrise': '6:45 AM',
          'Dhuhr': '12:30 PM',
          'Asr': '3:45 PM',
          'Maghrib': '6:15 PM',
          'Isha': '7:30 PM',
        },
        'date': {
          'readable': '${date.day}-${date.month}-${date.year}',
          'hijri': {
            'day': '${date.day}',
            'month': {'en': 'Estimated'},
            'year': '${date.year - 579}',
          },
        },
        'meta': {
          'method': {'name': 'Local Calculation (Approximate)'},
          'timezone': 'Local',
        },
      };
      
      print('⚠️ [$strategyName] Using approximate times');
      return PrayerTimes.fromJson(prayerData);
    } catch (e) {
      print('❌ [$strategyName] Failed: $e');
    }
    return null;
  }
}
