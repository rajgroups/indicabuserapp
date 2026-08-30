import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:indicab/core/config/Config.dart';
import 'package:indicab/core/services/SocketService.dart';
import 'package:indicab/core/services/DriverMarkerAnimator.dart';
import 'package:indicab/core/services/PolylineService.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/network/network_exceptions.dart';
import 'package:indicab/core/repository/BookingRepository.dart';
import 'package:indicab/core/models/booking_response.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/core/constants/Keys.dart';
import 'package:indicab/core/services/StorageService.dart';
import 'package:indicab/modules/home/HomeController.dart';
import 'package:indicab/modules/ride/ui/sos_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key, this.bookingNo, this.bookingData});

  final String? bookingNo;
  final BookingDataModel? bookingData;

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final PolylineService _polylineService = PolylineService();

  late final DriverMarkerAnimator _driverAnimator;

  BookingDataModel? _bookingData;
  bool _isLoading = false;
  bool _isCancelling = false;
  LatLng? _driverPosition;
  bool _userMovedMap = false;
  bool _arrivedSheetShown = false;

  String? _lastPolylineStatus;

  // ETA info from the Directions API (fetched once per phase)
  String _etaDistance = '';
  String _etaDuration = '';

  String? get _effectiveBookingNo {
    if (widget.bookingNo != null && widget.bookingNo!.trim().isNotEmpty) {
      return widget.bookingNo!.trim();
    }
    if (_bookingData?.bookingNo != null && _bookingData!.bookingNo!.trim().isNotEmpty) {
      return _bookingData!.bookingNo!.trim();
    }
    if (Get.arguments is Map && Get.arguments['booking_no'] != null) {
      return Get.arguments['booking_no'].toString().trim();
    }
    return null;
  }

  BitmapDescriptor? _customCategoryMarkerIcon;
  String? _loadedCategoryIconUrl;

  BitmapDescriptor get _effectiveDriverMarkerIcon {
    return _customCategoryMarkerIcon ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  }

  Future<void> _loadCategoryMarkerIconIfNeeded(String? iconUrl) async {
    if (iconUrl == null || iconUrl.trim().isEmpty) return;
    final trimmed = iconUrl.trim();
    if (_loadedCategoryIconUrl == trimmed) return;
    _loadedCategoryIconUrl = trimmed;

    try {
      final String fullUrl;
      final baseOrigin = Uri.parse(AppEnv.apiBaseUrl).origin;
      if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
        fullUrl = trimmed;
      } else if (trimmed.startsWith('/')) {
        fullUrl = '$baseOrigin$trimmed';
      } else {
        fullUrl = '$baseOrigin/storage/$trimmed';
      }

      final request = await HttpClient().getUrl(Uri.parse(fullUrl)).timeout(const Duration(seconds: 4));
      final response = await request.close();
      if (response.statusCode == 200) {
        final bytes = await response.fold<List<int>>(
          <int>[],
          (previous, element) => previous..addAll(element),
        );
        if (bytes.isNotEmpty) {
          final codec = await ui.instantiateImageCodec(
            Uint8List.fromList(bytes),
            targetWidth: 110,
          );
          final frame = await codec.getNextFrame();
          final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null && mounted) {
            setState(() {
              _customCategoryMarkerIcon = BitmapDescriptor.bytes(
                byteData.buffer.asUint8List(),
              );
            });
            _updateDriverMarkerIconInPlace();
          }
        }
      }
    } catch (e) {
      debugPrint('Custom category marker load error ($iconUrl), using default marker fallback: $e');
    }
  }

  void _updateDriverMarkerIconInPlace() {
    if (!mounted) return;
    _markers.removeWhere((m) => m.markerId.value == 'driver');
    if (_driverPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverAnimator.hasPosition
              ? _driverAnimator.currentPosition
              : _driverPosition!,
          rotation: _driverAnimator.currentBearing,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          icon: _effectiveDriverMarkerIcon,
          infoWindow: const InfoWindow(title: 'Driver'),
        ),
      );
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData ??
        (Get.arguments is Map && Get.arguments['booking_data'] is BookingDataModel
            ? Get.arguments['booking_data'] as BookingDataModel
            : null);

    _loadCategoryMarkerIconIfNeeded(_bookingData?.effectiveCategoryIconUrl);

    // If initial status is already completed/cancelled, handle navigation immediately
    final initialStatus = _bookingData?.status?.trim().toLowerCase();
    if (initialStatus == 'completed') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Get.currentRoute != RouteNames.rideSummary && mounted) {
          Get.offAllNamed(
            RouteNames.rideSummary,
            arguments: {
              'booking_no': _effectiveBookingNo,
              'booking_data': _bookingData,
            },
          );
        }
      });
      return;
    } else if (initialStatus == 'cancelled') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Get.offAllNamed(RouteNames.home);
        }
      });
      return;
    }

    _driverAnimator = DriverMarkerAnimator(vsync: this);
    _driverAnimator.onUpdate = _onDriverAnimationTick;

    // Seed the initial driver position from the booking data or pickup location
    _seedDriverPosition();

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildMarkersAndPolyline();
    });

    // Single initial API fetch
    _fetchBookingDetails();



    // Subscribe to WebSocket events
    final socketService = Get.find<SocketService>();
    socketService.on('driver_location_update', _onDriverLocationUpdate);
    socketService.on('booking_status', _onBookingStatusUpdate);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _fetchBookingDetails();
    }
  }

  @override
  void dispose() {
    _driverAnimator.dispose();
    WidgetsBinding.instance.removeObserver(this);
    final socketService = Get.find<SocketService>();
    socketService.off('driver_location_update', _onDriverLocationUpdate);
    socketService.off('booking_status', _onBookingStatusUpdate);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // API Fetch (single call on init + app resume, no polling)
  // ---------------------------------------------------------------------------

  Future<void> _fetchBookingDetails({bool silent = false}) async {
    final bookingNo = _effectiveBookingNo;
    if (bookingNo == null || bookingNo.isEmpty) return;

    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }

    final BookingRepository bookingRepository = BookingRepository(ApiClient());
    try {
      final response = await bookingRepository.getBooking(
        bookingNo,
        includeOtp: true,
      );
      final bookingData = response.data;
      if (bookingData != null && mounted) {
        final status = bookingData.status?.trim().toLowerCase();

        // If completed -> Navigate to RideSummaryScreen immediately
        if (status == 'completed') {
          final storage = StorageService();
          storage.delete(StorageKeys.pendingRideBookingNo);
          storage.delete(StorageKeys.pendingRideVehicleType);

          if (Get.isRegistered<HomeController>()) {
            final homeCtrl = Get.find<HomeController>();
            homeCtrl.activeRide.value = null;
            homeCtrl.resetSearchAndRouteState();
          }

          if (Get.currentRoute != RouteNames.rideSummary) {
            Get.offAllNamed(
              RouteNames.rideSummary,
              arguments: {
                'booking_no': bookingData.bookingNo ?? bookingNo,
                'booking_data': bookingData,
              },
            );
          }
          return;
        }

        // If cancelled -> Navigate to Home screen
        if (status == 'cancelled') {
          final storage = StorageService();
          storage.delete(StorageKeys.pendingRideBookingNo);
          storage.delete(StorageKeys.pendingRideVehicleType);

          if (Get.isRegistered<HomeController>()) {
            final homeCtrl = Get.find<HomeController>();
            homeCtrl.activeRide.value = null;
            homeCtrl.resetSearchAndRouteState();
          }

          Get.snackbar(
            'Ride Cancelled',
            'Your ride has been cancelled.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 3),
          );
          Get.offAllNamed(RouteNames.home);
          return;
        }

        setState(() => _bookingData = bookingData);
        _loadCategoryMarkerIconIfNeeded(bookingData.effectiveCategoryIconUrl);
        _seedDriverPosition();
        _buildMarkersAndPolyline();
      }
    } catch (e) {
      if (e is NetworkException && e.statusCode == 401) return;
      if (!silent && mounted) {
        Get.snackbar(
          'Error',
          'Failed to fetch ride details',
          backgroundColor: AppColors.surface,
        );
      }
    } finally {
      if (!silent && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Socket Event Handlers
  // ---------------------------------------------------------------------------

  void _seedDriverPosition() {
    final pLat = double.tryParse(_bookingData?.pickupLatitude ?? '');
    final pLng = double.tryParse(_bookingData?.pickupLongitude ?? '');
    final pickupPos = (pLat != null && pLng != null && pLat != 0 && pLng != 0)
        ? LatLng(pLat, pLng)
        : null;

    final dLat = double.tryParse(_bookingData?.driverLatitude ?? '');
    final dLng = double.tryParse(_bookingData?.driverLongitude ?? '');

    if (dLat != null && dLng != null && dLat != 0 && dLng != 0) {
      final candPos = LatLng(dLat, dLng);
      // Ignore stale seeded location (e.g. Vijayawada) if > 50km from pickup
      if (pickupPos == null || _distanceBetween(candPos, pickupPos) < 50000) {
        _driverPosition = candPos;
        _driverAnimator.animateTo(_driverPosition!);
        return;
      }
    }

    if (pickupPos != null) {
      _driverPosition = pickupPos;
      _driverAnimator.animateTo(_driverPosition!);
    }
  }

  double _distanceBetween(LatLng a, LatLng b) {
    const double earthRadius = 6371000;
    final dLat = (b.latitude - a.latitude) * math.pi / 180;
    final dLng = (b.longitude - a.longitude) * math.pi / 180;
    final sinDLat = math.sin(dLat / 2);
    final sinDLng = math.sin(dLng / 2);
    final h = sinDLat * sinDLat +
        math.cos(a.latitude * math.pi / 180) *
            math.cos(b.latitude * math.pi / 180) *
            sinDLng *
            sinDLng;
    return earthRadius * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  void _onDriverLocationUpdate(dynamic data) {
    if (data is! Map<String, dynamic> || !mounted) return;

    final incomingNo = data['booking_no']?.toString();
    final activeNo = widget.bookingNo ?? _bookingData?.bookingNo;
    if (incomingNo != null &&
        incomingNo.isNotEmpty &&
        activeNo != null &&
        activeNo.isNotEmpty &&
        incomingNo != activeNo) {
      return;
    }

    final lat = double.tryParse(data['latitude']?.toString() ?? '');
    final lng = double.tryParse(data['longitude']?.toString() ?? '');
    if (lat == null || lng == null || (lat == 0 && lng == 0)) return;

    final newPos = LatLng(lat, lng);
    final bearing = double.tryParse(data['bearing']?.toString() ?? '');

    _driverPosition = newPos;
    _driverAnimator.animateTo(newPos, bearing: bearing);
    _updateDriverToPickupRouteIfNeeded(newPos);
  }

  Future<void> _updateDriverToPickupRouteIfNeeded(LatLng newPos) async {
    final status = _bookingData?.status?.trim().toLowerCase() ?? '';
    if (status == 'accepted' || status == 'arrived') {
      final pLat = double.tryParse(_bookingData?.pickupLatitude ?? '');
      final pLng = double.tryParse(_bookingData?.pickupLongitude ?? '');
      if (pLat != null && pLng != null && pLat != 0 && pLng != 0) {
        final pickupPos = LatLng(pLat, pLng);
        final directionsResult = await _polylineService.fetchRoute(
          newPos,
          pickupPos,
          forceRefresh: true,
        );
        if (directionsResult.points.isNotEmpty && mounted) {
          _polylines.clear();
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: directionsResult.points,
              color: AppColors.primary,
              width: 5,
            ),
          );
          setState(() {
            _etaDistance = directionsResult.distanceText;
            _etaDuration = directionsResult.durationText;
          });
        }
      }
    }
  }

  void _onBookingStatusUpdate(dynamic data) {
    if (data is! Map<String, dynamic> || !mounted) return;

    Map<String, dynamic>? bookingMap;
    if (data['booking'] is Map<String, dynamic>) {
      bookingMap = data['booking'] as Map<String, dynamic>;
    } else if (data['booking_no'] != null) {
      bookingMap = data;
    }

    if (bookingMap == null) return;

    final bookingNo = bookingMap['booking_no']?.toString().trim();
    final currentNo = _effectiveBookingNo;
    if (bookingNo != null && currentNo != null && bookingNo.isNotEmpty && bookingNo != currentNo) {
      return;
    }

    final newBooking = BookingDataModel.fromJson(bookingMap);
    final newStatus = newBooking.status?.trim().toLowerCase();

    // Handle cancellation — navigate back to home with a message
    if (newStatus == 'cancelled') {
      if (!mounted) return;

      final storage = StorageService();
      storage.delete(StorageKeys.pendingRideBookingNo);
      storage.delete(StorageKeys.pendingRideVehicleType);

      if (Get.isRegistered<HomeController>()) {
        final homeCtrl = Get.find<HomeController>();
        homeCtrl.activeRide.value = null;
        homeCtrl.resetSearchAndRouteState();
      }

      Get.snackbar(
        'Ride Cancelled',
        'Your ride has been cancelled.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
      );
      Get.offAllNamed(RouteNames.home);
      return;
    }

    // Handle ride completion — navigate to the ride summary screen
    if (newStatus == 'completed') {
      final storage = StorageService();
      storage.delete(StorageKeys.pendingRideBookingNo);
      storage.delete(StorageKeys.pendingRideVehicleType);

      if (Get.isRegistered<HomeController>()) {
        final homeCtrl = Get.find<HomeController>();
        homeCtrl.activeRide.value = null;
        homeCtrl.resetSearchAndRouteState();
      }

      if (Get.currentRoute != RouteNames.rideSummary) {
        Get.offAllNamed(
          RouteNames.rideSummary,
          arguments: {
            'booking_no': newBooking.bookingNo ?? currentNo,
            'booking_data': newBooking,
          },
        );
      }
      return;
    }


    setState(() => _bookingData = newBooking);
    _loadCategoryMarkerIconIfNeeded(newBooking.effectiveCategoryIconUrl);

    // If OTP is missing, fetch full details with OTP included
    if (newBooking.startOtp == null || newBooking.startOtp!.trim().isEmpty) {
      _fetchBookingDetails(silent: true);
    }

    // Handle arrived status — show bottom sheet with OTP
    if (newStatus == 'arrived' && !_arrivedSheetShown) {
      _arrivedSheetShown = true;
      _showDriverArrivedSheet();
    }

    // On status change, rebuild polyline for the new phase
    _buildMarkersAndPolyline();
  }

  // ---------------------------------------------------------------------------
  // Driver Animation Tick — update marker without rebuilding map
  // ---------------------------------------------------------------------------

  void _onDriverAnimationTick(LatLng position, double bearing) {
    if (!mounted) return;

    // Update only the driver marker in-place (no full rebuild)
    _markers.removeWhere((m) => m.markerId.value == 'driver');
    _markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: position,
        rotation: bearing,
        anchor: const Offset(0.5, 0.5),
        flat: true,
        icon: _effectiveDriverMarkerIcon,
        infoWindow: const InfoWindow(title: 'Driver'),
      ),
    );

    setState(() {});

    // Auto-follow camera unless user has manually moved the map
    if (!_userMovedMap) {
      _animateCameraToDriver(position);
    }
  }

  Future<void> _animateCameraToDriver(LatLng position) async {
    if (!_mapController.isCompleted) return;
    final controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLng(position));
  }

  // ---------------------------------------------------------------------------
  // Polyline & Markers
  // ---------------------------------------------------------------------------

  Future<void> _buildMarkersAndPolyline() async {
    if (_bookingData == null) return;

    final booking = _bookingData!;
    final status = booking.status?.trim().toLowerCase() ?? '';
    final pickupLat = double.tryParse(booking.pickupLatitude ?? '');
    final pickupLng = double.tryParse(booking.pickupLongitude ?? '');
    final dropLat = double.tryParse(booking.dropLatitude ?? '');
    final dropLng = double.tryParse(booking.dropLongitude ?? '');

    if (pickupLat == null || pickupLng == null) return;

    final pickupPosition = LatLng(pickupLat, pickupLng);
    LatLng? dropPosition;
    if (dropLat != null && dropLng != null) {
      dropPosition = LatLng(dropLat, dropLng);
    }

    // Determine the phase-appropriate polyline
    // Only fetch if the status phase has changed
    final phaseKey = _phaseKeyFor(status);
    if (phaseKey != _lastPolylineStatus) {
      _lastPolylineStatus = phaseKey;
      _polylineService.clearCache();

      DirectionsResult? directionsResult;

      if (phaseKey == 'en_route_to_pickup' && _driverPosition != null) {
        // Driver → Pickup
        directionsResult = await _polylineService.fetchRoute(
          _driverPosition!,
          pickupPosition,
        );
      } else if (phaseKey == 'ride_started' &&
          dropPosition != null) {
        // Pickup → Destination (one-time fetch)
        directionsResult = await _polylineService.fetchRoute(
          pickupPosition,
          dropPosition,
        );
      }

      if (directionsResult != null && mounted) {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: directionsResult.points,
            color: AppColors.primary,
            width: 5,
          ),
        );
        _etaDistance = directionsResult.distanceText;
        _etaDuration = directionsResult.durationText;
      }
    }

    // Build markers (without the driver marker — that's handled by the animator)
    _markers.removeWhere(
      (m) => m.markerId.value == 'pickup' || m.markerId.value == 'drop',
    );

    if (status == 'started') {
      // During ride: show destination marker only
      if (dropPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('drop'),
            position: dropPosition,
            infoWindow: const InfoWindow(title: 'Destination'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    } else {
      // Before ride start: show pickup marker
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupPosition,
          infoWindow: const InfoWindow(title: 'Pickup Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
      // Also show drop if it exists
      if (booking.requiresDropLocation && dropPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('drop'),
            position: dropPosition,
            infoWindow: const InfoWindow(title: 'Drop-off Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
    }

    // Ensure driver marker is present
    if (_driverPosition != null &&
        !_markers.any((m) => m.markerId.value == 'driver')) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverAnimator.hasPosition
              ? _driverAnimator.currentPosition
              : _driverPosition!,
          rotation: _driverAnimator.currentBearing,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          icon: _effectiveDriverMarkerIcon,
          infoWindow: const InfoWindow(title: 'Driver'),
        ),
      );
    }

    if (mounted) {
      setState(() {});
      _adjustMapBounds();
    }
  }

  /// Maps booking status to a polyline phase key.
  String _phaseKeyFor(String status) {
    switch (status) {
      case 'accepted':
      case 'arrived':
        return 'en_route_to_pickup';
      case 'started':
        return 'ride_started';
      default:
        return status;
    }
  }

  Future<void> _adjustMapBounds() async {
    if (!mounted || !_mapController.isCompleted) return;

    final controller = await _mapController.future;

    if (_markers.isEmpty) return;

    double? minLat, maxLat, minLng, maxLng;

    for (final marker in _markers) {
      final lat = marker.position.latitude;
      final lng = marker.position.longitude;

      if (minLat == null || lat < minLat) minLat = lat;
      if (maxLat == null || lat > maxLat) maxLat = lat;
      if (minLng == null || lng < minLng) minLng = lng;
      if (maxLng == null || lng > maxLng) maxLng = lng;
    }

    if (minLat != null && maxLat != null && minLng != null && maxLng != null) {
      final bounds = LatLngBounds(
        northeast: LatLng(maxLat, maxLng),
        southwest: LatLng(minLat, minLng),
      );

      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 80),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Driver Arrived Bottom Sheet
  // ---------------------------------------------------------------------------

  void _showDriverArrivedSheet() {
    // Ensure we attempt to load OTP if missing
    if (_bookingData?.startOtp == null || _bookingData!.startOtp!.trim().isEmpty) {
      _fetchBookingDetails(silent: true);
    }

    // Haptic feedback
    HapticFeedback.heavyImpact();
    // System notification sound
    SystemSound.play(SystemSoundType.alert);

    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final otpStr = _bookingData?.startOtp?.trim();
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 44,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Driver has arrived!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your driver $_driverName is waiting at the pickup location.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Prominent Ride OTP Card inside Driver Arrived sheet
              CustomPaint(
                foregroundPainter: const _TraditionalArchPainter(
                  color: Color(0xFFFFC107),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF5B800),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'SHARE THIS OTP WITH YOUR DRIVER',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: Color(0xFFFFC107),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        otpStr != null && otpStr.isNotEmpty
                            ? otpStr.split('').join('  ')
                            : 'Waiting for OTP...',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'OK, GOT IT',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Cancel Ride API Trigger
  // ---------------------------------------------------------------------------

  Future<void> _handleCancelRide() async {
    final currentStatus = _bookingData?.status?.trim().toLowerCase();
    if (currentStatus == 'started') {
      Get.snackbar(
        'Cannot Cancel Ride',
        'Trip is already in progress and cannot be cancelled once picked up.',
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 4),
      );
      return;
    }

    if (_isCancelling) return;

    final bookingNo = widget.bookingNo ?? _bookingData?.bookingNo;
    if (bookingNo == null || bookingNo.isEmpty) {
      Get.offAllNamed(RouteNames.home);
      return;
    }

    setState(() {
      _isCancelling = true;
    });

    try {
      final repository = BookingRepository(ApiClient());
      await repository.cancelBooking(bookingNo);

      final storage = StorageService();
      storage.delete(StorageKeys.pendingRideBookingNo);
      storage.delete(StorageKeys.pendingRideVehicleType);

      if (Get.isRegistered<HomeController>()) {
        final homeCtrl = Get.find<HomeController>();
        homeCtrl.activeRide.value = null;
        homeCtrl.resetSearchAndRouteState();
      }

      if (mounted) {
        Get.snackbar(
          'Ride Cancelled',
          'Your ride has been cancelled successfully.',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
        Get.offAllNamed(RouteNames.home);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
        Get.snackbar(
          'Error',
          'Failed to cancel ride: ${e.toString().replaceAll('Exception: ', '')}',
          backgroundColor: AppColors.surface,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Navigation Button — launch Google Maps
  // ---------------------------------------------------------------------------

  Future<void> _launchNavigation() async {
    final dropLat = double.tryParse(_bookingData?.dropLatitude ?? '');
    final dropLng = double.tryParse(_bookingData?.dropLongitude ?? '');
    final pickupLat = double.tryParse(_bookingData?.pickupLatitude ?? '');
    final pickupLng = double.tryParse(_bookingData?.pickupLongitude ?? '');

    double? destLat, destLng;

    final status = _bookingData?.status?.trim().toLowerCase();
    if (status == 'started' && dropLat != null && dropLng != null) {
      destLat = dropLat;
      destLng = dropLng;
    } else if (pickupLat != null && pickupLng != null) {
      destLat = pickupLat;
      destLng = pickupLng;
    }

    if (destLat == null || destLng == null) {
      Get.snackbar(
        'Navigation',
        'Destination not available',
        backgroundColor: AppColors.surface,
      );
      return;
    }

    final uri = Uri.parse(
      'google.navigation:q=$destLat,$destLng&mode=d',
    );

    // Fallback to Google Maps web URL
    final fallbackUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar(
          'Navigation',
          'Could not open navigation',
          backgroundColor: AppColors.surface,
        );
      }
    } catch (e) {
      debugPrint('Navigation launch error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Re-center camera
  // ---------------------------------------------------------------------------

  void _recenterCamera() {
    _userMovedMap = false;
    _adjustMapBounds();
  }

  // ---------------------------------------------------------------------------
  // Label Helpers
  // ---------------------------------------------------------------------------

  String get _bookingNoLabel =>
      _bookingData?.bookingNo ?? widget.bookingNo ?? 'Ride in progress';

  String get _driverName =>
      _bookingData?.driverName?.trim().isNotEmpty == true
          ? _bookingData!.driverName!.trim()
          : 'Driver';

  String get _vehicleLabel {
    final parts = <String>[
      if (_bookingData?.vehicleName?.trim().isNotEmpty == true)
        _bookingData!.vehicleName!.trim(),
      if (_bookingData?.vehicleNumber?.trim().isNotEmpty == true)
        _bookingData!.vehicleNumber!.trim(),
    ];
    if (parts.isEmpty) return 'Vehicle details pending';
    return parts.join(' • ');
  }

  String get _pickupLabel =>
      _bookingData?.pickupAddress ?? 'Waiting for live pickup location';

  String get _dropLabel =>
      _bookingData?.dropAddress ??
      'Destination will be updated by socket event';

  String get _statusLabel {
    final status = _bookingData?.status?.trim().toLowerCase();
    if (status == null || status.isEmpty) return 'Ride in progress';
    return switch (status) {
      'accepted' => 'Driver en route',
      'arrived' => 'Driver arrived',
      'started' => 'Ride in progress',
      'completed' => 'Ride completed',
      _ => status,
    };
  }

  LatLng _getInitialCameraTarget() {
    if (_driverPosition != null &&
        _driverPosition!.latitude != 0 &&
        _driverPosition!.longitude != 0) {
      return _driverPosition!;
    }
    final pLat = double.tryParse(_bookingData?.pickupLatitude ?? '');
    final pLng = double.tryParse(_bookingData?.pickupLongitude ?? '');
    if (pLat != null && pLng != null && pLat != 0 && pLng != 0) {
      return LatLng(pLat, pLng);
    }
    final dLat = double.tryParse(_bookingData?.dropLatitude ?? '');
    final dLng = double.tryParse(_bookingData?.dropLongitude ?? '');
    if (dLat != null && dLng != null && dLat != 0 && dLng != 0) {
      return LatLng(dLat, dLng);
    }
    return const LatLng(12.9756, 77.6050);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final status = _bookingData?.status?.trim().toLowerCase();
    final isStarted = status == 'started';
    final isAccepted = status == 'accepted';
    final isArrived = status == 'arrived';
    final otp = _bookingData?.startOtp;
    final fare = _bookingData?.estimatedAmount;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // -- Google Map --
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _getInitialCameraTarget(),
              zoom: 14,
            ),
            onMapCreated: (GoogleMapController controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
            onCameraMoveStarted: () {
              // Detect user manual map interaction to disable auto-follow
              _userMovedMap = true;
            },
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
          ),

          // -- Top Bar Floating Banner (Glassmorphic Modern Header) --
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
              child: Row(
                children: [
                  // Back Button
                  InkWell(
                    onTap: () {
                      Get.offAllNamed(
                        RouteNames.home,
                        arguments: <String, dynamic>{
                          'from_active_ride': true,
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x20000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Color(0xFF0F172A),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Header Info Floating Pill
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x20000000),
                            blurRadius: 18,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'RIDE #${_bookingNoLabel.toUpperCase()}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _statusLabel,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_etaDuration.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7ED),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFF5B800),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.access_time_filled_rounded,
                                    size: 14,
                                    color: Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _etaDistance.isNotEmpty
                                        ? '$_etaDuration • $_etaDistance'
                                        : _etaDuration,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -- Floating Map Buttons: Recenter + Navigation --
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.44 + 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recenter button
                if (_userMovedMap)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x20000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _recenterCamera,
                        icon: const Icon(
                          Icons.my_location_rounded,
                          color: Color(0xFF0F172A),
                        ),
                        tooltip: 'Recenter Map',
                      ),
                    ),
                  ),
                // Google Maps Navigation button
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5B800),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF5B800).withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _launchNavigation,
                    icon: const Icon(
                      Icons.navigation_rounded,
                      color: Color(0xFF1E1B4B),
                      size: 24,
                    ),
                    tooltip: 'Open Google Maps',
                  ),
                ),
              ],
            ),
          ),

          // -- Rapido Style Bottom Sheet --
          DraggableScrollableSheet(
            initialChildSize: 0.44,
            minChildSize: 0.44,
            maxChildSize: 0.88,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFFF5B800),
                      width: 2.5,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 30,
                      offset: Offset(0, -8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                  physics: const BouncingScrollPhysics(),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Drag indicator handle
                        Center(
                          child: Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFCBD5E1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: CircularProgressIndicator(
                                color: Color(0xFFF5B800),
                              ),
                            ),
                          )
                        else ...[
                          // 1. Live Phase Status Banner Card
                          _buildPhaseBanner(isAccepted, isArrived, isStarted),
                          const SizedBox(height: 18),

                          // 2. Rapido Driver & Vehicle Details Card
                          _buildDriverAndVehicleCard(isStarted),
                          const SizedBox(height: 20),

                          // 3. Signature Rapido OTP PIN Section (Traditional Arch Frame)
                          _buildOtpCard(otp, isStarted, isAccepted, isArrived),
                          const SizedBox(height: 22),

                          // 4. Trip Route Timeline Card
                          const Text(
                            'TRIP ROUTE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildTripTimeline(),
                          const SizedBox(height: 20),

                          // 5. Estimated Fare & Payment Mode Card
                          if (fare != null && fare > 0) ...[
                            _buildFareCard(fare),
                            const SizedBox(height: 20),
                          ],

                          // 6. Emergency & Safety Section
                          _buildSafetySection(),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helper UI Components
  // ---------------------------------------------------------------------------

  /// Phase Status Header Banner Card
  Widget _buildPhaseBanner(bool isAccepted, bool isArrived, bool isStarted) {
    Color bg;
    Color border;
    Color iconColor;
    IconData icon;
    String title;
    String subtitle;

    if (isArrived) {
      bg = const Color(0xFFECFDF5);
      border = const Color(0xFF6EE7B7);
      iconColor = const Color(0xFF059669);
      icon = Icons.check_circle_rounded;
      title = 'Driver Has Arrived!';
      subtitle = 'Your driver is waiting at the pickup point';
    } else if (isStarted) {
      bg = const Color(0xFFEFF6FF);
      border = const Color(0xFF93C5FD);
      iconColor = const Color(0xFF2563EB);
      icon = Icons.navigation_rounded;
      title = 'Trip in Progress';
      subtitle = 'Heading towards your destination';
    } else {
      bg = const Color(0xFFFFFBEB);
      border = const Color(0xFFFDE68A);
      iconColor = const Color(0xFFD97706);
      icon = Icons.near_me_rounded;
      title = 'Driver En Route';
      subtitle = 'Driver is on the way to pick you up';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Driver Profile & Indian License Plate Vehicle Card
  Widget _buildDriverAndVehicleCard(bool isStarted) {
    final vehicleNo = _bookingData?.vehicleNumber?.trim() ?? '';
    final vehicleModel = _vehicleLabel;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Driver Avatar
              Stack(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B4B),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF5B800),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFF5B800),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: Color(0xFFD97706),
                          ),
                          SizedBox(width: 2),
                          Text(
                            '4.9',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Driver Name & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _driverName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: Color(0xFF0284C7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vehicleModel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Rapido Commercial License Plate Badge (Yellow Plate style)
              if (vehicleNo.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF1E1B4B),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x15000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    vehicleNo.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E1B4B),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons: Call Driver & Cancel Ride
          Row(
            children: [
              // Call Driver Button
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => Get.snackbar(
                    'Calling Driver',
                    'Connecting your call...',
                    backgroundColor: const Color(0xFF0F172A),
                    colorText: Colors.white,
                    snackPosition: SnackPosition.TOP,
                  ),
                  icon: const Icon(
                    Icons.call_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  label: const Text(
                    'Call Driver',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF101424),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Cancel Ride Button
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  onPressed:
                      (_isCancelling || isStarted) ? null : _handleCancelRide,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: isStarted
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFFFCA5A5),
                      width: 1.5,
                    ),
                    backgroundColor: isStarted
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFFEF2F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isCancelling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFEF4444),
                          ),
                        )
                      : Text(
                          isStarted ? "In Ride" : "Cancel",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isStarted
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFFDC2626),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Signature Rapido OTP Card with Traditional Golden Arch Framing & Digit Boxes
  Widget _buildOtpCard(
    String? otp,
    bool isStarted,
    bool isAccepted,
    bool isArrived,
  ) {
    final rawOtp = otp?.trim() ?? '';
    final digits = rawOtp.isNotEmpty
        ? rawOtp.split('')
        : ['•', '•', '•', '•'];

    return CustomPaint(
      foregroundPainter: const _TraditionalArchPainter(
        color: Color(0xFFFFC107),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF101424),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFF5B800),
            width: 1.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.lock_clock_rounded,
                  size: 16,
                  color: Color(0xFFFFC107),
                ),
                const SizedBox(width: 8),
                Text(
                  isStarted
                      ? 'SHARE THIS OTP TO COMPLETE RIDE'
                      : 'SHARE THIS PIN WITH YOUR DRIVER',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: Color(0xFFFFC107),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // OTP Digit Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: digits.map((digit) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 48,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFF5B800).withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    digit,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              }).toList(),
            ),

            if (rawOtp.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: rawOtp));
                  Get.snackbar(
                    'OTP Copied',
                    'Ride PIN $rawOtp copied to clipboard',
                    backgroundColor: const Color(0xFFF5B800),
                    colorText: const Color(0xFF1E1B4B),
                    snackPosition: SnackPosition.TOP,
                    duration: const Duration(seconds: 2),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.copy_rounded,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to copy PIN $rawOtp',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Trip Route Connected Nodes Timeline
  Widget _buildTripTimeline() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Pickup Node
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 34,
                    color: const Color(0xFFCBD5E1),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PICKUP LOCATION',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _pickupLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Drop Node
          if (_bookingData?.requiresDropLocation != false) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFEF4444),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DESTINATION',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _dropLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Estimated Fare & Payment Mode Card
  Widget _buildFareCard(num fare) {
    final paymentType =
        _bookingData?.bookingMode?.trim().toUpperCase() ?? 'CASH';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ESTIMATED FARE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '₹${fare.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.payments_rounded,
                  size: 16,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                Text(
                  paymentType == 'CASH' ? 'Pay Cash' : paymentType,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Emergency SOS & Safety Section
  Widget _buildSafetySection() {
    return InkWell(
      onTap: () => Get.to(() => SosScreen(
            bookingNo: widget.bookingNo ?? _bookingData?.bookingNo ?? '',
            defaultTriggerType: 'safety_team',
            autoTriggerDefault: true,
          )),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFFCA5A5),
            width: 1.2,
          ),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.shield_rounded,
              color: Color(0xFFDC2626),
              size: 22,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Safety & Emergency SOS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF991B1B),
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    '24/7 Support & emergency assistance',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFB91C1C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFDC2626),
            ),
          ],
        ),
      ),
    );
  }
}

class _TraditionalArchPainter extends CustomPainter {
  final Color color;

  const _TraditionalArchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final goldPaint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final fillGold = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // --- Top-Right Corner Motif ---
    final trPath = Path();
    trPath.moveTo(size.width - 40, 0);
    trPath.quadraticBezierTo(size.width - 20, 0, size.width - 20, 20);
    trPath.quadraticBezierTo(size.width - 20, 35, size.width, 35);
    canvas.drawPath(trPath, goldPaint);

    canvas.drawCircle(Offset(size.width - 16, 16), 3.0, fillGold);
    canvas.drawCircle(Offset(size.width - 26, 6), 1.8, fillGold);
    canvas.drawCircle(Offset(size.width - 6, 26), 1.8, fillGold);

    // --- Bottom-Left Corner Motif ---
    final blPath = Path();
    blPath.moveTo(0, size.height - 35);
    blPath.quadraticBezierTo(20, size.height - 35, 20, size.height - 20);
    blPath.quadraticBezierTo(20, size.height, 40, size.height);
    canvas.drawPath(blPath, goldPaint);

    canvas.drawCircle(Offset(16, size.height - 16), 3.0, fillGold);
    canvas.drawCircle(Offset(6, size.height - 26), 1.8, fillGold);
    canvas.drawCircle(Offset(26, size.height - 6), 1.8, fillGold);
  }

  @override
  bool shouldRepaint(covariant _TraditionalArchPainter oldDelegate) =>
      oldDelegate.color != color;
}


