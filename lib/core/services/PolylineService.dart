import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:indicab/core/config/Config.dart';
import 'package:url_launcher/url_launcher.dart';

/// Cached directions result with polyline points, distance, and duration.
class DirectionsResult {
  const DirectionsResult({
    required this.points,
    required this.distanceText,
    required this.durationText,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final String distanceText;
  final String durationText;
  final int distanceMeters;
  final int durationSeconds;

  static const empty = DirectionsResult(
    points: [],
    distanceText: '',
    durationText: '',
    distanceMeters: 0,
    durationSeconds: 0,
  );
}

/// Wraps Google Directions API with smart caching.
///
/// - Caches the last fetched polyline to avoid redundant requests.
/// - Only re-fetches when origin or destination moves significantly (>200m).
/// - Exposes distance and duration for ETA display.
class PolylineService {
  PolylineService();

  final Dio _dio = Dio();

  /// Last fetched result cache.
  DirectionsResult? _cachedResult;
  LatLng? _cachedOrigin;
  LatLng? _cachedDestination;

  /// Minimum distance change (in meters) to trigger a re-fetch.
  static const double _refreshThresholdMeters = 200;

  /// Fetch a route between [origin] and [destination].
  ///
  /// Returns the cached result if positions haven't moved significantly.
  /// Falls back to a straight line if the API key is missing or request fails.
  Future<DirectionsResult> fetchRoute(
    LatLng origin,
    LatLng destination, {
    bool forceRefresh = false,
  }) async {
    // Return cache if positions haven't changed significantly
    if (!forceRefresh &&
        _cachedResult != null &&
        _cachedOrigin != null &&
        _cachedDestination != null &&
        _distanceBetween(_cachedOrigin!, origin) < _refreshThresholdMeters &&
        _distanceBetween(_cachedDestination!, destination) <
            _refreshThresholdMeters) {
      return _cachedResult!;
    }

    final key = AppEnv.googleMapsApiKey;
    if (key.isEmpty) {
      final fallback = DirectionsResult(
        points: [origin, destination],
        distanceText: '',
        durationText: '',
        distanceMeters: 0,
        durationSeconds: 0,
      );
      _updateCache(origin, destination, fallback);
      return fallback;
    }

    try {
      final url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$key';

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final routes = response.data['routes'] as List;
        if (routes.isNotEmpty) {
          final route = routes[0];
          final points =
              route['overview_polyline']['points'] as String;
          final leg = route['legs'][0];
          final distance = leg['distance'];
          final duration = leg['duration'];

          final result = DirectionsResult(
            points: decodePolyline(points),
            distanceText: distance['text'] ?? '',
            durationText: duration['text'] ?? '',
            distanceMeters: distance['value'] ?? 0,
            durationSeconds: duration['value'] ?? 0,
          );

          _updateCache(origin, destination, result);
          return result;
        }
      }
    } catch (e) {
      debugPrint('PolylineService: Error fetching directions: $e');
    }

    // Fallback: straight line
    final fallback = DirectionsResult(
      points: [origin, destination],
      distanceText: '',
      durationText: '',
      distanceMeters: 0,
      durationSeconds: 0,
    );
    _updateCache(origin, destination, fallback);
    return fallback;
  }

  void _updateCache(
    LatLng origin,
    LatLng destination,
    DirectionsResult result,
  ) {
    _cachedOrigin = origin;
    _cachedDestination = destination;
    _cachedResult = result;
  }

  /// Clear the cached result (e.g., on status change).
  void clearCache() {
    _cachedResult = null;
    _cachedOrigin = null;
    _cachedDestination = null;
  }

  /// Decode an encoded polyline string into a list of LatLng points.
  static List<LatLng> decodePolyline(String encoded) {
    final List<LatLng> poly = [];
    int index = 0;
    final int len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  /// Haversine distance in meters.
  static double _distanceBetween(LatLng a, LatLng b) {
    const double earthRadius = 6371000; // meters
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);
    final h = sinDLat * sinDLat +
        math.cos(_toRadians(a.latitude)) *
            math.cos(_toRadians(b.latitude)) *
            sinDLng *
            sinDLng;
    return earthRadius * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  /// Reverse geocode LatLng coordinates into a human-readable street address using Google Geocoding API.
  Future<String?> reverseGeocode(double lat, double lng) async {
    final key = AppEnv.googleMapsApiKey.isNotEmpty
        ? AppEnv.googleMapsApiKey
        : AppEnv.googlePlacesApiKey;
    if (key.isEmpty) return null;

    try {
      final url =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$key';
      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final results = response.data['results'] as List;
        if (results.isNotEmpty) {
          return results[0]['formatted_address'] as String?;
        }
      }
    } catch (e) {
      debugPrint('PolylineService: Reverse geocode error: $e');
    }
    return null;
  }

  /// Launch native Google Maps app for turn-by-turn navigation (saves Google API costs).
  static Future<void> launchExternalNavigation({
    required double destLat,
    required double destLng,
    double? originLat,
    double? originLng,
  }) async {
    final String urlStr =
        'https://www.google.com/maps/dir/?api=1'
        '${originLat != null && originLng != null ? "&origin=$originLat,$originLng" : ""}'
        '&destination=$destLat,$destLng&travelmode=driving';

    try {
      final Uri uri = Uri.parse(urlStr);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('PolylineService: Error launching external navigation: $e');
    }
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
