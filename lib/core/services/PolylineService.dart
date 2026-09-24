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

  /// Cooldown state to prevent rapid UI API spam
  DateTime? _lastDirectionsRequestAt;
  static const Duration _sameRouteCooldown = Duration(seconds: 30);
  static const Duration _rapidUiCooldown = Duration(seconds: 3);

  DateTime? _lastGoogleGeocodeRequestAt;
  static const Duration _googleGeocodeCooldown = Duration(seconds: 5);

  /// Last fetched result cache.
  DirectionsResult? _cachedResult;
  LatLng? _cachedOrigin;
  LatLng? _cachedDestination;

  /// Minimum distance change (in meters) to trigger a re-fetch.
  static const double _refreshThresholdMeters = 200;

  /// In-flight route requests to prevent duplicate concurrent calls.
  final Map<String, Future<DirectionsResult>> _inFlightRequests = {};

  /// Fetch a route between [origin] and [destination].
  ///
  /// Returns the cached result if positions haven't moved significantly.
  /// Uses Google Directions first and only falls back to a straight line
  /// for the current call when the API is unavailable or returns no route.
  Future<DirectionsResult> fetchRoute(
    LatLng origin,
    LatLng destination, {
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();

    // 1. Fingerprint & In-Flight Protection
    // Round to 4 decimal places (~11 meters) to deduplicate tiny concurrent GPS variations
    final String requestKey =
        '${origin.latitude.toStringAsFixed(4)},${origin.longitude.toStringAsFixed(4)}-${destination.latitude.toStringAsFixed(4)},${destination.longitude.toStringAsFixed(4)}';

    if (_inFlightRequests.containsKey(requestKey)) {
      assert(() {
        debugPrint('[DIRECTIONS] BLOCKED — request already running');
        return true;
      }());
      return _inFlightRequests[requestKey]!;
    }

    // 2. Cache Protection (Protection A)
    final bool isSimilarRoute = _cachedOrigin != null &&
        _cachedDestination != null &&
        _cachedResult != null &&
        _distanceBetween(_cachedOrigin!, origin) < _refreshThresholdMeters &&
        _distanceBetween(_cachedDestination!, destination) < _refreshThresholdMeters;

    if (isSimilarRoute) {
      if (forceRefresh) {
        // Enforce strong 30-second cooldown for the same logical route even if forced
        if (_lastDirectionsRequestAt != null &&
            now.difference(_lastDirectionsRequestAt!) < _sameRouteCooldown) {
          assert(() {
            debugPrint('[DIRECTIONS] BLOCKED — cooldown (same route forced refresh)');
            return true;
          }());
          return _cachedResult!;
        }
      } else {
        assert(() {
          debugPrint('[DIRECTIONS] BLOCKED — cached route (no meaningful change)');
          return true;
        }());
        return _cachedResult!;
      }
    } else {
      // 3. Rapid UI Protection
      // Prevent wild map dragging from generating >200m route requests instantly
      if (_lastDirectionsRequestAt != null &&
          now.difference(_lastDirectionsRequestAt!) < _rapidUiCooldown) {
        assert(() {
          debugPrint('[DIRECTIONS] BLOCKED — rapid UI cooldown');
          return true;
        }());
        return _cachedResult ?? DirectionsResult.empty;
      }
    }

    final key = AppEnv.googleMapsApiKey;
    if (key.isEmpty) {
      return DirectionsResult.empty;
    }

    assert(() {
      debugPrint('[DIRECTIONS] REQUEST — route changed or cooldown expired');
      return true;
    }());
    _lastDirectionsRequestAt = now;

    final Future<DirectionsResult> requestFuture = _executeDirectionsRequest(origin, destination, key);
    _inFlightRequests[requestKey] = requestFuture;

    try {
      return await requestFuture;
    } finally {
      _inFlightRequests.remove(requestKey);
    }
  }

  Future<DirectionsResult> _executeDirectionsRequest(LatLng origin, LatLng destination, String key) async {
    assert(() {
      debugPrint('[GOOGLE ROUTES] Directions API Request: $origin -> $destination');
      return true;
    }());

    try {
      final url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=driving'
          '&alternatives=false'
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

      debugPrint(
        'PolylineService: Directions returned status=${response.data['status']} '
        'for origin=$origin destination=$destination',
      );
    } catch (e) {
      debugPrint('PolylineService: Error fetching directions: $e');
    }

    // Fallback: straight line
    return DirectionsResult.empty;
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
    _lastDirectionsRequestAt = null;
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

  static final Map<String, String> _addressCache = {};

  /// Reverse geocode LatLng coordinates into a human-readable street address using Google Geocoding API or OpenStreetMap Nominatim.
  Future<String?> reverseGeocode(double lat, double lng) async {
    final cacheKey = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey];
    }

    final key = AppEnv.hasGoogleMapsApiKey
        ? AppEnv.googleMapsApiKey
        : (AppEnv.hasGooglePlacesApiKey ? AppEnv.googlePlacesApiKey : '');

    if (key.isNotEmpty) {
      final now = DateTime.now();
      if (_lastGoogleGeocodeRequestAt == null ||
          now.difference(_lastGoogleGeocodeRequestAt!) >= _googleGeocodeCooldown) {
        _lastGoogleGeocodeRequestAt = now;
        try {
          assert(() {
            debugPrint('[GOOGLE GEOCODING] Reverse Geocoding API Request: $lat, $lng');
            return true;
          }());

          final url =
              'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$key';
          final response = await _dio.get(url);

          if (response.statusCode == 200 && response.data['status'] == 'OK') {
            final results = response.data['results'] as List;
            if (results.isNotEmpty) {
              final addr = results[0]['formatted_address'] as String?;
              if (addr != null && addr.trim().isNotEmpty) {
                final formatted = addr.trim();
                _addressCache[cacheKey] = formatted;
                return formatted;
              }
            }
          }
        } catch (e) {
          debugPrint('PolylineService: Google reverse geocode error: $e');
        }
      } else {
        assert(() {
          debugPrint('[GOOGLE GEOCODING] BLOCKED — cooldown active, falling back to Nominatim');
          return true;
        }());
      }
    }

    // Fallback: OpenStreetMap Nominatim reverse geocode (Free & reliable street address)
    try {
      final url =
          'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1';
      final response = await _dio.get(
        url,
        options: Options(
          headers: {'User-Agent': 'IndicabUserApp/1.0'},
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.trim().isNotEmpty) {
          final formatted = displayName.trim();
          _addressCache[cacheKey] = formatted;
          return formatted;
        }
      }
    } catch (e) {
      debugPrint('PolylineService: Nominatim reverse geocode error: $e');
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
