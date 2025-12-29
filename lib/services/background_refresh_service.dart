import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'content_api_service.dart';
import '../models/category_models.dart';

/// Background Smart Refresh Service
/// Automatically refreshes categories, subcategories, and content data
/// when the app has internet connectivity
class BackgroundRefreshService {
  // Singleton pattern
  static final BackgroundRefreshService _instance = BackgroundRefreshService._internal();
  factory BackgroundRefreshService() => _instance;
  BackgroundRefreshService._internal();

  // Services
  final ContentApiService _apiService = ContentApiService();

  // Configuration
  static const Duration _refreshInterval = Duration(minutes: 15);
  static const Duration _minTimeBetweenRefreshes = Duration(minutes: 5);
  static const String _lastRefreshKey = 'background_last_refresh_time';
  static const String _refreshedSubcategoriesKey = 'background_refreshed_subcategories';

  // State
  Timer? _refreshTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isRefreshing = false;
  bool _isInitialized = false;

  // Callbacks for UI notification
  VoidCallback? onRefreshStarted;
  VoidCallback? onRefreshCompleted;
  Function(String)? onRefreshError;

  /// Initialize the background refresh service
  /// Call this from main.dart after app initialization
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    debugPrint('🔄 BackgroundRefreshService: Initializing...');

    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Start periodic refresh timer
    _startPeriodicRefresh();

    // Do initial check
    final hasNetwork = await _hasNetworkConnection();
    if (hasNetwork) {
      _scheduleRefreshIfNeeded();
    }

    debugPrint('✅ BackgroundRefreshService: Initialized');
  }

  /// Dispose the service
  void dispose() {
    _refreshTimer?.cancel();
    _connectivitySubscription?.cancel();
    _isInitialized = false;
    debugPrint('🔄 BackgroundRefreshService: Disposed');
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    final hasNetwork = !results.contains(ConnectivityResult.none);
    
    if (hasNetwork) {
      debugPrint('🌐 Network available - checking if refresh needed');
      _scheduleRefreshIfNeeded();
    } else {
      debugPrint('📵 Network unavailable - skipping refresh');
    }
  }

  /// Start the periodic refresh timer
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      _scheduleRefreshIfNeeded();
    });
  }

  /// Check if we should refresh and schedule it
  Future<void> _scheduleRefreshIfNeeded() async {
    if (_isRefreshing) {
      debugPrint('🔄 Already refreshing, skipping...');
      return;
    }

    // Check if enough time has passed since last refresh
    final shouldRefresh = await _shouldRefresh();
    if (!shouldRefresh) {
      debugPrint('⏰ Too soon to refresh, skipping...');
      return;
    }

    // Check network
    final hasNetwork = await _hasNetworkConnection();
    if (!hasNetwork) {
      debugPrint('📵 No network for background refresh');
      return;
    }

    // Perform refresh
    _performBackgroundRefresh();
  }

  /// Check if enough time has passed since last refresh
  Future<bool> _shouldRefresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRefreshMs = prefs.getInt(_lastRefreshKey) ?? 0;
      final lastRefresh = DateTime.fromMillisecondsSinceEpoch(lastRefreshMs);
      final timeSinceLastRefresh = DateTime.now().difference(lastRefresh);
      
      return timeSinceLastRefresh >= _minTimeBetweenRefreshes;
    } catch (e) {
      return true;
    }
  }

  /// Save the last refresh time
  Future<void> _saveLastRefreshTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastRefreshKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('❌ Error saving refresh time: $e');
    }
  }

  /// Check if device has network connectivity
  Future<bool> _hasNetworkConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return false;
      }
      // Additional check - try to reach a server
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Perform the background refresh
  Future<void> _performBackgroundRefresh() async {
    if (_isRefreshing) return;
    
    _isRefreshing = true;
    onRefreshStarted?.call();
    debugPrint('🔄 Starting background refresh...');

    try {
      // 1. Refresh categories
      debugPrint('📂 Refreshing categories...');
      final categories = await _apiService.getCategories(forceRefresh: true);
      debugPrint('✅ Refreshed ${categories.length} categories');

      // 2. Refresh each category detail (which includes subcategories)
      for (final category in categories) {
        try {
          debugPrint('📁 Refreshing category detail for ${category.getName('english')}...');
          final categoryDetail = await _apiService.getCategoryDetail(category.id);
          
          // 3. Refresh contents for each subcategory
          await _refreshSubcategoryContents(categoryDetail);
          
          // Small delay to avoid overwhelming the server
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint('⚠️ Error refreshing category ${category.id}: $e');
          // Continue with next category
        }
      }

      // Save refresh time
      await _saveLastRefreshTime();
      
      debugPrint('✅ Background refresh completed');
      onRefreshCompleted?.call();
    } catch (e) {
      debugPrint('❌ Background refresh error: $e');
      onRefreshError?.call(e.toString());
    } finally {
      _isRefreshing = false;
    }
  }

  /// Refresh contents for all subcategories of a category
  Future<void> _refreshSubcategoryContents(dynamic categoryDetail) async {
    try {
      // Extract subcategories from category detail response
      final subcategoriesList = categoryDetail['subcategories'] as List<dynamic>? ?? [];
      
      for (final subcategoryData in subcategoriesList) {
        try {
          final subcategoryId = subcategoryData['id'] as int?;
          if (subcategoryId != null) {
            debugPrint('📄 Refreshing contents for subcategory $subcategoryId...');
            await _apiService.getSubcategoryContents(
              subcategoryId,
              forceRefresh: true,
            );
            
            // Small delay
            await Future.delayed(const Duration(milliseconds: 200));
          }
        } catch (e) {
          debugPrint('⚠️ Error refreshing subcategory: $e');
          // Continue with next subcategory
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error getting subcategories: $e');
    }
  }

  /// Force an immediate refresh (can be called from UI)
  Future<void> forceRefresh() async {
    final hasNetwork = await _hasNetworkConnection();
    if (!hasNetwork) {
      debugPrint('📵 No network for forced refresh');
      onRefreshError?.call('No internet connection');
      return;
    }
    
    await _performBackgroundRefresh();
  }

  /// Check if currently refreshing
  bool get isRefreshing => _isRefreshing;

  /// Get the last refresh time
  Future<DateTime?> getLastRefreshTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastRefreshMs = prefs.getInt(_lastRefreshKey);
      if (lastRefreshMs != null) {
        return DateTime.fromMillisecondsSinceEpoch(lastRefreshMs);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

