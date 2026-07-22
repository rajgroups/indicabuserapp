import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:indicab/core/services/SocketService.dart';
import 'package:indicab/core/services/DriverMarkerAnimator.dart';
import 'package:indicab/core/services/PolylineService.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/network/network_exceptions.dart';
import 'package:indicab/core/repository/BookingRepository.dart';
import 'package:indicab/core/models/booking_response.dart';
import 'package:indicab/core/routes/names.dart';
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
  LatLng? _driverPosition;
  bool _userMovedMap = false;
  bool _arrivedSheetShown = false;

  // ETA info from the Directions API (fetched once per phase)
  String _etaDistance = '';
  String _etaDuration = '';

  // Tracks the last status for which we fetched a polyline.
  // This avoids re-fetching on every socket event.
  String? _lastPolylineStatus;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;

    _driverAnimator = DriverMarkerAnimator(vsync: this);
    _driverAnimator.onUpdate = _onDriverAnimationTick;

    // Seed the initial driver position from the booking data or pickup location
    _seedDriverPosition();

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildMarkersAndPolyline();
    });

    // Single initial API fetch for robustness
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
      // Re-fetch once on app resume for robustness
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
    final bookingNo = widget.bookingNo?.trim();
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
        setState(() => _bookingData = bookingData);
        _seedDriverPosition();
        _buildMarkersAndPolyline();
      }
    } catch (e) {
      if (e is NetworkException && e.statusCode == 401) return;
      if (mounted) {
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

    final booking = data['booking'];
    if (booking is! Map<String, dynamic>) return;

    final bookingNo = booking['booking_no']?.toString();
    if (bookingNo != widget.bookingNo && bookingNo != _bookingData?.bookingNo) return;

    final newBooking = BookingDataModel.fromJson(booking);
    final newStatus = newBooking.status?.trim().toLowerCase();

    setState(() => _bookingData = newBooking);

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
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Share this OTP with your driver',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      otpStr != null && otpStr.isNotEmpty
                          ? otpStr.split('').join('  ')
                          : 'Waiting for OTP...',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

    return Scaffold(
      backgroundColor: AppColors.authBackground,
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
          ),

          // -- Top Bar --
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      Get.offAllNamed(
                        RouteNames.home,
                        arguments: <String, dynamic>{
                          'from_active_ride': true,
                        },
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x16000000),
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x16000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Ride #$_bookingNoLabel',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _statusLabel,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (_etaDuration.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _etaDuration,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -- Floating buttons: Recenter + Navigate --
          Positioned(
            right: 20,
            bottom: MediaQuery.of(context).size.height * 0.4 + 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recenter button
                if (_userMovedMap)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _recenterCamera,
                        icon: const Icon(
                          Icons.my_location_rounded,
                          color: AppColors.primaryDark,
                        ),
                        tooltip: 'Recenter',
                      ),
                    ),
                  ),
                // Navigate button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _launchNavigation,
                    icon: const Icon(
                      Icons.navigation_rounded,
                      color: AppColors.textPrimary,
                    ),
                    tooltip: 'Navigate',
                  ),
                ),
              ],
            ),
          ),

          // -- Bottom Sheet --
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.38,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 28,
                      offset: Offset(0, -6),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  physics: const BouncingScrollPhysics(),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_isLoading)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else ...[
                          Center(
                            child: Container(
                              width: 52,
                              height: 5,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // -- ETA & Distance Info (when available) --
                          if (_etaDistance.isNotEmpty ||
                              _etaDuration.isNotEmpty) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.schedule_rounded,
                                    size: 20,
                                    color: AppColors.primaryDark,
                                  ),
                                  const SizedBox(width: 10),
                                  if (_etaDuration.isNotEmpty)
                                    Text(
                                      _etaDuration,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  if (_etaDistance.isNotEmpty &&
                                      _etaDuration.isNotEmpty)
                                    const Text(
                                      '  •  ',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  if (_etaDistance.isNotEmpty)
                                    Text(
                                      _etaDistance,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  const Spacer(),
                                  Text(
                                    isStarted
                                        ? 'To destination'
                                        : 'To pickup',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // -- Driver Info Row --
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 32,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _driverName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          size: 16,
                                          color: AppColors.primaryDark,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '4.9',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _bookingNoLabel,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _vehicleLabel,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // -- Action Buttons --
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => Get.snackbar(
                                    'Calling',
                                    'Connecting to driver...',
                                    backgroundColor: AppColors.surface,
                                  ),
                                  icon: const Icon(Icons.call_rounded),
                                  label: const Text(
                                    'Call',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.inputFill,
                                    foregroundColor: AppColors.textPrimary,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => Get.offNamed(
                                    RouteNames.rideSummary,
                                    arguments: {
                                      'booking_no': widget.bookingNo ??
                                          _bookingData?.bookingNo,
                                      'booking_data': _bookingData,
                                    },
                                  ),
                                  icon: const Icon(Icons.flag_rounded),
                                  label: const Text(
                                    'End Ride',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.textPrimary,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // -- OTP Section --
                          Text(
                            isStarted
                                ? 'Share this OTP to End the Ride'
                                : isAccepted || isArrived
                                    ? 'Share this OTP with the driver'
                                    : 'Ride OTP',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 24,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.inputFill,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  isStarted
                                      ? 'Completion OTP'
                                      : 'Ride OTP',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  otp?.trim().isNotEmpty == true
                                      ? otp!.trim().split('').join('  ')
                                      : 'Waiting for OTP from the server',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 4,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Divider(color: AppColors.borderSoft),
                          const SizedBox(height: 24),

                          // -- Trip Route --
                          const Text(
                            'Trip Route',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _RouteStep(
                            icon: Icons.my_location_rounded,
                            title: 'Pickup',
                            subtitle: _pickupLabel,
                          ),
                          if (_bookingData?.requiresDropLocation !=
                              false) ...[
                            const SizedBox(height: 14),
                            _RouteStep(
                              icon: Icons.location_on_rounded,
                              title: 'Drop',
                              subtitle: _dropLabel,
                            ),
                          ],
                          const SizedBox(height: 28),

                          // -- SOS --
                          InkWell(
                            onTap: () =>
                                Get.to(() => const SosScreen()),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.red.withValues(
                                    alpha: 0.18,
                                  ),
                                ),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.warning_rounded,
                                    color: Colors.red,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Emergency help and support',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
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
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RouteStep extends StatelessWidget {
  const _RouteStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
