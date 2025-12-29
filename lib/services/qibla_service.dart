import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

class QiblaService {
  // Kaaba coordinates
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;

  /// Calculate Qibla direction from given location
  /// Returns bearing in degrees (0-360)
  static double calculateQiblaDirection(double latitude, double longitude) {
    // Convert to radians
    final lat1 = _toRadians(latitude);
    final lon1 = _toRadians(longitude);
    final lat2 = _toRadians(kaabaLatitude);
    final lon2 = _toRadians(kaabaLongitude);

    // Calculate difference in longitude
    final dLon = lon2 - lon1;

    // Calculate bearing using spherical trigonometry
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    var bearing = math.atan2(y, x);
    
    // Convert to degrees
    bearing = _toDegrees(bearing);
    
    // Normalize to 0-360
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  /// Calculate distance to Kaaba in kilometers
  static double calculateDistanceToKaaba(double latitude, double longitude) {
    const earthRadius = 6371.0; // km

    final lat1 = _toRadians(latitude);
    final lon1 = _toRadians(longitude);
    final lat2 = _toRadians(kaabaLatitude);
    final lon2 = _toRadians(kaabaLongitude);

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Get current location
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Check permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  static double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  static double _toDegrees(double radians) {
    return radians * 180 / math.pi;
  }

  /// Get compass direction name
  static String getDirectionName(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) % 360 / 45).floor();
    return directions[index];
  }
}

