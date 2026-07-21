import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Provides smooth Uber/Ola-style marker animation for the driver position.
///
/// Instead of jumping the marker from old→new position, this class
/// interpolates over a configurable duration using a [Ticker].
/// It also computes the bearing (rotation angle) so the vehicle icon
/// points in the direction of travel.
class DriverMarkerAnimator {
  DriverMarkerAnimator({
    required TickerProvider vsync,
    this.animationDuration = const Duration(milliseconds: 1000),
  }) {
    _controller = AnimationController(
      vsync: vsync,
      duration: animationDuration,
    );
    _controller.addListener(_onTick);
  }

  final Duration animationDuration;
  late final AnimationController _controller;

  LatLng _startPosition = const LatLng(0, 0);
  LatLng _endPosition = const LatLng(0, 0);
  LatLng _currentPosition = const LatLng(0, 0);
  double _currentBearing = 0;
  bool _hasInitialPosition = false;

  /// Callback invoked on every animation frame with the updated position and bearing.
  void Function(LatLng position, double bearing)? onUpdate;

  /// The most recent interpolated position.
  LatLng get currentPosition => _currentPosition;

  /// The most recent computed bearing (degrees, 0=north, clockwise).
  double get currentBearing => _currentBearing;

  /// Whether the animator has received at least one position.
  bool get hasPosition => _hasInitialPosition;

  /// Smoothly animate the marker to [newPosition].
  ///
  /// If this is the first position, the marker jumps immediately.
  /// Otherwise, it interpolates from the current position over [animationDuration].
  void animateTo(LatLng newPosition, {double? bearing}) {
    if (!_hasInitialPosition) {
      _hasInitialPosition = true;
      _startPosition = newPosition;
      _endPosition = newPosition;
      _currentPosition = newPosition;
      if (bearing != null) _currentBearing = bearing;
      onUpdate?.call(_currentPosition, _currentBearing);
      return;
    }

    // Compute bearing from current position to new position
    _currentBearing = bearing ?? _computeBearing(_currentPosition, newPosition);

    _startPosition = _currentPosition;
    _endPosition = newPosition;

    // Reset and start the animation
    _controller.reset();
    _controller.forward();
  }

  void _onTick() {
    final t = _controller.value;
    _currentPosition = LatLng(
      _lerpDouble(_startPosition.latitude, _endPosition.latitude, t),
      _lerpDouble(_startPosition.longitude, _endPosition.longitude, t),
    );
    onUpdate?.call(_currentPosition, _currentBearing);
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

  /// Compute bearing (in degrees, 0=North, clockwise) from [from] to [to].
  static double _computeBearing(LatLng from, LatLng to) {
    final dLon = _toRadians(to.longitude - from.longitude);
    final lat1 = _toRadians(from.latitude);
    final lat2 = _toRadians(to.latitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final bearing = math.atan2(y, x);
    return (_toDegrees(bearing) + 360) % 360;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
  static double _toDegrees(double radians) => radians * 180 / math.pi;

  /// Dispose the animation controller. Must be called in the widget's dispose.
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
  }
}
