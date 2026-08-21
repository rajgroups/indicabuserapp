import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/constants/Keys.dart';
import 'package:indicab/core/models/booking_request.dart';
import 'package:indicab/core/models/booking_response.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/network/network_exceptions.dart';
import 'package:indicab/core/repository/BookingRepository.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/core/services/SocketService.dart';
import 'package:indicab/core/services/StorageService.dart';
import 'package:indicab/modules/home/HomeController.dart';

class FindingDriverScreen extends StatefulWidget {
  const FindingDriverScreen({
    super.key,
    this.bookingNo,
    this.bookingData,
    this.vehicleType,
    this.bookingRequest,
  });

  final String? bookingNo;
  final BookingDataModel? bookingData;
  final String? vehicleType;
  final BookingCreateRequest? bookingRequest;

  @override
  State<FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<FindingDriverScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  final BookingRepository _bookingRepository = BookingRepository(ApiClient());
  final StorageService _storage = StorageService();
  String _statusText = 'Finding your ride...';
  BookingDataModel? _bookingData;
  late final AnimationController _pulseController;
  late final AnimationController _routeController;
  late final AnimationController _searchController;
  late final AnimationController _sweepController;

  String? _localBookingNo;
  String? _localVehicleType;
  bool _isCreatingBooking = false;
  bool _isCancelling = false;
  String? _bookingError;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
    _localBookingNo = widget.bookingNo?.trim();
    _localVehicleType = widget.vehicleType?.trim();
    _restorePendingRideState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _routeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
    _searchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();


    // Listen for booking status updates via socket (primary mechanism)
    final socketService = Get.find<SocketService>();
    socketService.on('booking_status', _onBookingStatusSocket);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (_bookingNo.isNotEmpty) {
        _fetchBookingStatus();
      } else if (widget.bookingRequest != null) {
        _createBookingAndFetch();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _bookingNo.isNotEmpty) {
      _fetchBookingStatus(silent: true);
    }
  }

  String get _bookingNo => _localBookingNo?.trim() ?? widget.bookingNo?.trim() ?? '';

  void _restorePendingRideState() {
    if (_localBookingNo == null || _localBookingNo!.trim().isEmpty) {
      final storedBookingNo = _storage.read(StorageKeys.pendingRideBookingNo);
      if (storedBookingNo is String && storedBookingNo.trim().isNotEmpty) {
        _localBookingNo = storedBookingNo.trim();
      }
    }

    if (_localVehicleType == null || _localVehicleType!.trim().isEmpty) {
      final storedVehicleType = _storage.read(StorageKeys.pendingRideVehicleType);
      if (storedVehicleType is String && storedVehicleType.trim().isNotEmpty) {
        _localVehicleType = storedVehicleType.trim();
      }
    }
  }

  void _persistPendingRideState({
    String? bookingNo,
    String? vehicleType,
  }) {
    final normalizedBookingNo = bookingNo?.trim();
    if (normalizedBookingNo == null || normalizedBookingNo.isEmpty) {
      return;
    }

    _storage.write(StorageKeys.pendingRideBookingNo, normalizedBookingNo);

    final normalizedVehicleType = vehicleType?.trim();
    if (normalizedVehicleType != null && normalizedVehicleType.isNotEmpty) {
      _storage.write(
        StorageKeys.pendingRideVehicleType,
        normalizedVehicleType,
      );
    }
  }

  void _clearPendingRideState() {
    _storage.delete(StorageKeys.pendingRideBookingNo);
    _storage.delete(StorageKeys.pendingRideVehicleType);
  }

  String? get _resolvedVehicleType {
    final value = _localVehicleType ?? widget.vehicleType;
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  String get _vehicleTypeLabel {
    final value = _resolvedVehicleType;
    if (value == null || value.isEmpty) {
      return 'ride';
    }

    return value.toLowerCase();
  }

  IconData get _vehicleIcon {
    final value = _vehicleTypeLabel;
    if (value.contains('bike') || value.contains('scooter')) {
      return Icons.two_wheeler_rounded;
    }
    if (value.contains('auto') || value.contains('rickshaw')) {
      return Icons.electric_rickshaw_rounded;
    }
    return Icons.local_taxi_rounded;
  }

  LatLng get _pickupLatLng {
    if (widget.bookingRequest != null &&
        widget.bookingRequest!.locations.isNotEmpty) {
      final loc = widget.bookingRequest!.locations.first;
      return LatLng(loc.latitude, loc.longitude);
    }
    if (_bookingData != null) {
      final lat = double.tryParse(_bookingData!.pickupLatitude?.toString() ?? '');
      final lng = double.tryParse(_bookingData!.pickupLongitude?.toString() ?? '');
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    if (Get.isRegistered<HomeController>()) {
      final homeController = Get.find<HomeController>();
      final loc = homeController.pickuplocation.value ?? homeController.pickupPoint.value;
      return LatLng(loc.latitude, loc.longitude);
    }
    return const LatLng(12.9716, 77.5946);
  }


  String _statusLabelFor(String? status) {
    final value = status?.trim().toLowerCase();
    return switch (value) {
      'accepted' || 'driver_assigned' => 'Driver accepted your ride',
      'started' => 'Ride in progress',
      'completed' => 'Ride completed',
      'cancelled' => 'Ride cancelled',
      'no_driver_available' => 'No driver available',
      _ => 'Finding your ride...',
    };
  }

  Map<String, dynamic> _bookingArguments(BookingDataModel booking) {
    return {
      'booking_no': booking.bookingNo ?? _bookingNo,
      'booking_data': booking,
    };
  }

  void _handleRetry() {
    // Prefer creating a fresh booking on retry so we do not reuse the same
    // booking record and accidentally keep the old driver-matching queue alive.
    if (widget.bookingRequest != null) {
      _clearPendingRideState();
      _localBookingNo = null;
      _createBookingAndFetch();
    } else if (_bookingNo.isNotEmpty) {
      _retryExistingBooking();
    } else {
      _createBookingAndFetch();
    }
  }

  Future<void> _handleGoBack() async {
    if (!mounted) {
      return;
    }

    await Get.offAllNamed(
      RouteNames.home,
      arguments: <String, dynamic>{'from_active_ride': true},
    );
  }

  Future<void> _handleCancel() async {
    if (_isCancelling) {
      return;
    }

    final bookingNoToCancel = _bookingNo;

    if (mounted) {
      setState(() {
        _isCancelling = true;
      });
    }

    if (bookingNoToCancel.isNotEmpty) {
      try {
        await _bookingRepository.cancelBooking(bookingNoToCancel);
      } catch (e) {
        debugPrint('FindingDriverScreen._handleCancel error: $e');
      }
    }

    _clearPendingRideState();

    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().activeRide.value = null;
    }

    if (!mounted) {
      return;
    }

    await Get.offAllNamed(
      RouteNames.home,
      arguments: <String, dynamic>{'from_active_ride': true},
    );
  }

  /// Handle booking status updates received via WebSocket.
  void _onBookingStatusSocket(dynamic data) {
    if (data is! Map<String, dynamic> || !mounted) return;

    final booking = data['booking'];
    if (booking is! Map<String, dynamic>) return;

    final bookingNo = booking['booking_no']?.toString();
    if (bookingNo != null && bookingNo.isNotEmpty && bookingNo != _bookingNo) {
      return; // Not our booking
    }

    final status = booking['status']?.toString().trim().toLowerCase();
    final bookingModel = BookingDataModel.fromJson(booking);

    if (status == 'no_driver_available' || status == 'expired') {
      if (mounted) {
        setState(() {
          _bookingData = bookingModel;
          _statusText = 'No drivers available';
          _bookingError = 'No drivers accepted your booking. Please try again.';
        });
      }
      _persistPendingRideState(
        bookingNo: bookingModel.bookingNo ?? _bookingNo,
        vehicleType: bookingModel.categoryName ?? _resolvedVehicleType,
      );
      return;
    }

    if (status == 'accepted' || status == 'driver_assigned') {
      _clearPendingRideState();
      if (Get.currentRoute != RouteNames.activeRide) {
        Get.offAllNamed(
          RouteNames.activeRide,
          arguments: _bookingArguments(bookingModel),
        );
      }
      return;
    }

    if (status == 'started') {
      _clearPendingRideState();
      if (Get.currentRoute != RouteNames.activeRide) {
        Get.offAllNamed(
          RouteNames.activeRide,
          arguments: _bookingArguments(bookingModel),
        );
      }
      return;
    }

    if (status == 'completed') {
      _clearPendingRideState();
      if (Get.currentRoute != RouteNames.rideSummary) {
        Get.offAllNamed(
          RouteNames.rideSummary,
          arguments: _bookingArguments(bookingModel),
        );
      }
    }
  }

  Future<void> _createBookingAndFetch() async {
    if (_isCreatingBooking || !mounted) {
      return;
    }

    if (widget.bookingRequest == null) {
      setState(() {
        _bookingError = 'Booking request details are missing.';
        _statusText = 'Booking creation failed';
      });
      return;
    }

    setState(() {
      _isCreatingBooking = true;
      _bookingError = null;
      _statusText = 'Creating booking...';
    });

    try {
      final socketService = Get.find<SocketService>();
      await socketService.ensureConnected();

      final response = await _bookingRepository.createBooking(widget.bookingRequest!);
      if (!response.status || response.data == null) {
        throw Exception(response.message.isNotEmpty ? response.message : 'Failed to create booking');
      }

      if (!mounted) return;

      setState(() {
        _localBookingNo = response.data?.bookingNo;
        _bookingData = response.data;
        _isCreatingBooking = false;
        _statusText = 'Finding your ride...';
      });
      _persistPendingRideState(
        bookingNo: response.data?.bookingNo,
        vehicleType: response.data?.categoryName ?? _resolvedVehicleType,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreatingBooking = false;
        _bookingError = e.toString();
        _statusText = 'Booking creation failed';
      });
    }
  }

  Future<void> _retryExistingBooking() async {
    if (_isCreatingBooking || _bookingNo.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _isCreatingBooking = true;
      _bookingError = null;
      _statusText = 'Resending booking request...';
    });

    try {
      final socketService = Get.find<SocketService>();
      await socketService.ensureConnected();

      final response = await _bookingRepository.retryBooking(_bookingNo);
      if (!response.status || response.data == null) {
        throw Exception(response.message.isNotEmpty ? response.message : 'Failed to retry booking');
      }

      if (!mounted) return;

      setState(() {
        _bookingData = response.data;
        _isCreatingBooking = false;
        _statusText = 'Finding your ride...';
      });
      _persistPendingRideState(
        bookingNo: response.data?.bookingNo ?? _bookingNo,
        vehicleType: response.data?.categoryName ?? _resolvedVehicleType,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreatingBooking = false;
        _bookingError = e.toString();
        _statusText = 'Booking retry failed';
      });
    }
  }

  Future<void> _fetchBookingStatus({bool silent = false}) async {
    if (_bookingNo.isEmpty || !mounted) {
      return;
    }

    if (!silent && mounted) {
      setState(() {
        _statusText = 'Syncing ride status...';
      });
    }

    try {
      final response = await _bookingRepository.getBooking(
        _bookingNo,
        includeOtp: true,
      );
      final booking = response.data;
      if (booking == null || !mounted) {
        return;
      }

      setState(() {
        _bookingData = booking;
        _statusText = _statusLabelFor(booking.status);
      });
      _persistPendingRideState(
        bookingNo: booking.bookingNo ?? _bookingNo,
        vehicleType: booking.categoryName ?? _resolvedVehicleType,
      );

      final status = booking.status?.trim().toLowerCase();
      if (status == 'accepted' || status == 'driver_assigned') {
        _clearPendingRideState();
        if (Get.currentRoute != RouteNames.activeRide) {
          Get.offAllNamed(
            RouteNames.activeRide,
            arguments: _bookingArguments(booking),
          );
        }
      } else if (status == 'started') {
        _clearPendingRideState();
        if (Get.currentRoute != RouteNames.activeRide) {
          Get.offAllNamed(
            RouteNames.activeRide,
            arguments: _bookingArguments(booking),
          );
        }
      } else if (status == 'completed') {
        _clearPendingRideState();
        if (Get.currentRoute != RouteNames.rideSummary) {
          Get.offAllNamed(
            RouteNames.rideSummary,
            arguments: _bookingArguments(booking),
          );
        }
      } else if (status == 'no_driver_available') {
        setState(() {
          _statusText = 'No driver available';
          _bookingError = 'No drivers accepted your ride request. Please try again.';
        });
        _persistPendingRideState(
          bookingNo: booking.bookingNo ?? _bookingNo,
          vehicleType: booking.categoryName ?? _resolvedVehicleType,
        );
      }
    } catch (error) {
      if (error is NetworkException && error.statusCode == 401) {
        return;
      }

      if (mounted) {
        setState(() {
          _statusText = 'Waiting for ride updates...';
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _routeController.dispose();
    _searchController.dispose();
    _sweepController.dispose();

    final socketService = Get.find<SocketService>();
    socketService.off('booking_status', _onBookingStatusSocket);
    if (_bookingError != null && _bookingNo.isNotEmpty) {
      _persistPendingRideState(
        bookingNo: _bookingNo,
        vehicleType: _resolvedVehicleType,
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleGoBack();
        }
      },
      child: Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _pulseController,
                _sweepController,
              ]),
              builder: (context, child) {
                return _GoogleMapsScanningBackdrop(
                  pickupLatLng: _pickupLatLng,
                  sweepProgress: _sweepController.value,
                  pulseProgress: _pulseController.value,
                  vehicleIcon: _vehicleIcon,
                );
              },
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Material(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _handleGoBack,
                          customBorder: const CircleBorder(),
                          child: const SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Searching for nearby drivers',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _statusText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _SearchCard(
                    pulse: _pulseController.value,
                    route: _routeController.value,
                    search: _searchController.value,
                    vehicleIcon: _vehicleIcon,
                    vehicleType: _vehicleTypeLabel,
                    bookingNo: _bookingNo,
                    bookingData: _bookingData,
                    bookingError: _bookingError,
                    isCreatingBooking: _isCreatingBooking,
                    isCancelling: _isCancelling,
                    onRetry: _handleRetry,
                    onCancel: _handleCancel,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}

const String _darkMapStyleJson = '''
[
  {"elementType":"geometry","stylers":[{"color":"#101524"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#525A70"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#101524"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#2A344D"}]},
  {"featureType":"administrative.country","elementType":"labels.text.fill","stylers":[{"color":"#7A869E"}]},
  {"featureType":"administrative.locality","elementType":"labels.text.fill","stylers":[{"color":"#9EA9BD"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#525A70"}]},
  {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#141E33"}]},
  {"featureType":"road","elementType":"geometry.fill","stylers":[{"color":"#1E273B"}]},
  {"featureType":"road","elementType":"labels.text.fill","stylers":[{"color":"#687590"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#26324A"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#00C853","weight":1.2},{"lightness":-45}]},
  {"featureType":"transit","elementType":"labels.text.fill","stylers":[{"color":"#525A70"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#0A0E1A"}]}
]
''';

class _GoogleMapsScanningBackdrop extends StatelessWidget {
  final LatLng pickupLatLng;
  final double sweepProgress;
  final double pulseProgress;
  final IconData vehicleIcon;

  const _GoogleMapsScanningBackdrop({
    required this.pickupLatLng,
    required this.sweepProgress,
    required this.pulseProgress,
    required this.vehicleIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Google Maps Base Layer with Dark Map Style
        Positioned.fill(
          child: GoogleMap(
            style: _darkMapStyleJson,
            initialCameraPosition: CameraPosition(
              target: pickupLatLng,
              zoom: 15.2,
            ),
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            rotateGesturesEnabled: false,
            tiltGesturesEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
          ),
        ),

        // 2. Dark Radial Vignette overlay to seamlessly blend map edges
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.1),
                radius: 1.15,
                colors: [
                  const Color(0xFF1A1A2E).withValues(alpha: 0.20),
                  const Color(0xFF1A1A2E).withValues(alpha: 0.65),
                  const Color(0xFF1A1A2E).withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.65, 1.0],
              ),
            ),
          ),
        ),

        // 3. Dynamic Google Maps Radar Scanning Layer
        Positioned.fill(
          child: CustomPaint(
            painter: _GoogleMapsRadarPainter(
              sweepAngle: sweepProgress * math.pi * 2,
              pulseProgress: pulseProgress,
              vehicleIcon: vehicleIcon,
            ),
          ),
        ),

        // 4. Radar Status Badge
        Positioned(
          top: 96,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: const Color(0xFF00C853).withValues(alpha: 0.40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C853).withValues(alpha: 0.25),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C853).withValues(alpha: 0.8),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LIVE RADAR SCANNING • 3KM RADIUS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF00C853).withValues(alpha: 0.95),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GoogleMapsRadarPainter extends CustomPainter {
  final double sweepAngle;
  final double pulseProgress;
  final IconData vehicleIcon;

  _GoogleMapsRadarPainter({
    required this.sweepAngle,
    required this.pulseProgress,
    required this.vehicleIcon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.40);
    final maxRadius = math.min(size.width, size.height) * 0.44;

    // 1. Concentric radar grid rings & crosshairs
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF00C853).withValues(alpha: 0.16)
      ..strokeWidth = 1.0;

    for (var i = 1; i <= 4; i++) {
      final r = maxRadius * (i / 4);
      canvas.drawCircle(center, r, gridPaint);
    }

    // Crosshair axes
    canvas.drawLine(
      Offset(center.dx - maxRadius * 1.08, center.dy),
      Offset(center.dx + maxRadius * 1.08, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius * 1.08),
      Offset(center.dx, center.dy + maxRadius * 1.08),
      gridPaint,
    );

    // Cardinal compass markers (N, S, E, W)
    _drawText(canvas, 'N', Offset(center.dx - 4, center.dy - maxRadius - 16), const Color(0xFF00C853), 10, FontWeight.w900);
    _drawText(canvas, 'S', Offset(center.dx - 4, center.dy + maxRadius + 4), const Color(0xFF00C853), 10, FontWeight.w900);
    _drawText(canvas, 'E', Offset(center.dx + maxRadius + 6, center.dy - 7), const Color(0xFF00C853), 10, FontWeight.w900);
    _drawText(canvas, 'W', Offset(center.dx - maxRadius - 16, center.dy - 7), const Color(0xFF00C853), 10, FontWeight.w900);

    // Distance ring labels
    _drawText(canvas, '250m', Offset(center.dx + maxRadius * 0.25 + 4, center.dy - 12), const Color(0xFF00C853).withValues(alpha: 0.5), 9, FontWeight.w700);
    _drawText(canvas, '500m', Offset(center.dx + maxRadius * 0.50 + 4, center.dy - 12), const Color(0xFF00C853).withValues(alpha: 0.5), 9, FontWeight.w700);
    _drawText(canvas, '1km', Offset(center.dx + maxRadius * 0.75 + 4, center.dy - 12), const Color(0xFF00C853).withValues(alpha: 0.5), 9, FontWeight.w700);

    // 2. Concentric expanding sonar pulse rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var i = 0; i < 3; i++) {
      final p = (pulseProgress + i * 0.33) % 1.0;
      final r = maxRadius * p;
      final alpha = (1.0 - p).clamp(0.0, 1.0) * 0.38;
      ringPaint.color = const Color(0xFF00C853).withValues(alpha: alpha);
      canvas.drawCircle(center, r, ringPaint);
    }

    // 3. 360° Rotating Radar Sweep Arc
    final sweepPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: maxRadius),
        sweepAngle - math.pi / 3.5,
        math.pi / 3.5,
        false,
      )
      ..close();

    final sweepShader = ui.Gradient.sweep(
      center,
      [
        Colors.transparent,
        const Color(0xFF00C853).withValues(alpha: 0.04),
        const Color(0xFF00C853).withValues(alpha: 0.18),
        const Color(0xFF00C853).withValues(alpha: 0.42),
      ],
      [0.0, 0.65, 0.88, 1.0],
      TileMode.clamp,
      sweepAngle - math.pi / 3.5,
      sweepAngle,
    );

    canvas.drawPath(sweepPath, Paint()..shader = sweepShader);

    // Sweep leading edge beam line
    final edgeX = center.dx + maxRadius * math.cos(sweepAngle);
    final edgeY = center.dy + maxRadius * math.sin(sweepAngle);
    canvas.drawLine(
      center,
      Offset(edgeX, edgeY),
      Paint()
        ..color = const Color(0xFF00FF66)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.5),
    );

    // 4. Scanning Nearby Driver Blips
    final driverOffsets = [
      Offset(maxRadius * 0.42, -maxRadius * 0.36),
      Offset(-maxRadius * 0.54, maxRadius * 0.26),
      Offset(maxRadius * 0.28, maxRadius * 0.56),
      Offset(-maxRadius * 0.42, -maxRadius * 0.46),
      Offset(maxRadius * 0.64, -maxRadius * 0.14),
      Offset(-maxRadius * 0.24, maxRadius * 0.66),
    ];

    for (var i = 0; i < driverOffsets.length; i++) {
      final pos = center + driverOffsets[i];
      final angleToBlip = math.atan2(driverOffsets[i].dy, driverOffsets[i].dx);
      var diff = (sweepAngle - angleToBlip) % (2 * math.pi);
      if (diff < 0) diff += 2 * math.pi;

      final isHit = diff < math.pi / 3.5;
      final intensity = isHit ? (1.0 - diff / (math.pi / 3.5)) : 0.0;

      // Glow when radar sweeps over blip
      if (isHit) {
        canvas.drawCircle(
          pos,
          14 + intensity * 8,
          Paint()
            ..color = const Color(0xFF00C853).withValues(alpha: intensity * 0.30)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          pos,
          10 + intensity * 5,
          Paint()
            ..color = const Color(0xFF00FF66).withValues(alpha: intensity * 0.65)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }

      // Center blip dot
      canvas.drawCircle(
        pos,
        4.5 + intensity * 2,
        Paint()
          ..color = Color.lerp(
            const Color(0xFF00C853).withValues(alpha: 0.45),
            const Color(0xFF00FF66),
            intensity,
          )!,
      );
    }

    // 5. Center Pickup Location Pin Marker
    canvas.drawCircle(
      center,
      22 + math.sin(pulseProgress * math.pi * 2) * 3.5,
      Paint()..color = const Color(0xFF00C853).withValues(alpha: 0.20),
    );
    canvas.drawCircle(
      center,
      13,
      Paint()
        ..color = Colors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
    canvas.drawCircle(
      center,
      11,
      Paint()..color = const Color(0xFF1A1A2E),
    );
    canvas.drawCircle(
      center,
      6.5,
      Paint()..color = const Color(0xFF00C853),
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    Color color,
    double fontSize,
    FontWeight fontWeight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _GoogleMapsRadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.pulseProgress != pulseProgress;
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.pulse,
    required this.route,
    required this.search,
    required this.vehicleIcon,
    required this.vehicleType,
    required this.bookingNo,
    required this.bookingData,
    required this.bookingError,
    required this.isCreatingBooking,
    required this.isCancelling,
    required this.onRetry,
    required this.onCancel,
  });

  final double pulse;
  final double route;
  final double search;
  final IconData vehicleIcon;
  final String vehicleType;
  final String bookingNo;
  final BookingDataModel? bookingData;
  final String? bookingError;
  final bool isCreatingBooking;
  final bool isCancelling;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 32,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (bookingError == null) ...[
                  CustomPaint(
                    size: const Size(280, 190),
                    painter: _MapPulsePainter(
                      pulse: pulse,
                      route: route,
                      search: search,
                      vehicleIcon: vehicleIcon,
                      vehicleType: vehicleType,
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(
                      math.cos(route * math.pi * 2) * 50,
                      math.sin(route * math.pi * 2) * 18,
                    ),
                    child: _MovingCab(route: route, vehicleIcon: vehicleIcon),
                  ),
                ] else ...[
                  Container(
                    width: 98,
                    height: 98,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1AEE3B3B),
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ── Rapido-style animated loading bar ──────────────────
          if (bookingError == null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: const Color(0xFFEEEFF3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.lerp(
                    const Color(0xFF00C853),
                    const Color(0xFF1A1A2E),
                    (search * 0.4).clamp(0.0, 1.0),
                  )!,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Step indicators (like Rapido's booking steps)
            Row(
              children: [
                _StepDot(active: true, label: 'Placed'),
                _StepLine(animate: search),
                _StepDot(
                  active: !isCreatingBooking && bookingNo.isNotEmpty,
                  label: 'Matching',
                ),
                _StepLine(animate: route),
                _StepDot(
                  active: bookingData?.driverName?.trim().isNotEmpty == true,
                  label: 'Driver',
                ),
              ],
            ),
            const SizedBox(height: 14),
          ] else
            const SizedBox(height: 10),
          Text(
            bookingError != null
                ? 'Booking Failed'
                : isCreatingBooking
                    ? 'Requesting your ride...'
                    : 'Searching nearby drivers',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bookingError != null
                ? (bookingError!.contains('Exception:')
                    ? bookingError!.replaceAll('Exception: ', '')
                    : bookingError!)
                : isCreatingBooking
                    ? 'Connecting and sending your request...'
                    : 'We are matching your $vehicleType with the nearest driver.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFB0B3C1),
              height: 1.5,
            ),
          ),
          if (bookingNo.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEEEFF3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.confirmation_number_rounded,
                    size: 16,
                    color: Color(0xFF00C853),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Number',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFB0B3C1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '#$bookingNo',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1A1A2E),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (bookingData?.driverName?.trim().isNotEmpty == true)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Assigned to',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFB0B3C1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          bookingData!.driverName!.trim(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1A1A2E),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (bookingError != null) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C853),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Retry Booking',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: isCancelling ? null : onCancel,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Colors.red.withValues(alpha: 0.05),
              ),
              child: isCancelling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : const Text(
                      'Cancel Request',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovingCab extends StatelessWidget {
  const _MovingCab({required this.route, required this.vehicleIcon});

  final double route;
  final IconData vehicleIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 98,
      height: 98,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00C853).withValues(alpha: 0.14),
                  const Color(0xFF00C853).withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          Transform.rotate(
            angle: math.sin(route * math.pi * 2) * 0.04,
            child: Icon(vehicleIcon, size: 40, color: const Color(0xFF00C853)),
          ),
          Positioned(
            top: 14,
            right: 16,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.greenAccent.shade400,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPulsePainter extends CustomPainter {
  _MapPulsePainter({
    required this.pulse,
    required this.route,
    required this.search,
    required this.vehicleIcon,
    required this.vehicleType,
  });

  final double pulse;
  final double route;
  final double search;
  final IconData vehicleIcon;
  final String vehicleType;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.46);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final ringColors = [
      AppColors.primary.withValues(alpha: 0.22),
      AppColors.primaryDark.withValues(alpha: 0.14),
      AppColors.border.withValues(alpha: 0.18),
    ];

    for (var i = 0; i < 3; i++) {
      final progress = ((pulse + i * 0.24) % 1.0).clamp(0.0, 1.0);
      final radius = 34.0 + progress * 50.0;
      ringPaint.color = ringColors[i];
      ringPaint.strokeWidth = 2.0 - progress * 0.8;
      canvas.drawCircle(center, radius, ringPaint);
    }

    final roadPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = AppColors.surface.withValues(alpha: 0.92)
      ..strokeCap = StrokeCap.round;

    final road = Path()
      ..moveTo(size.width * 0.1, size.height * 0.74)
      ..cubicTo(
        size.width * 0.3,
        size.height * 0.52,
        size.width * 0.55,
        size.height * 0.9,
        size.width * 0.88,
        size.height * 0.34,
      );
    canvas.drawPath(road, roadPaint);

    final shimmerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.primary.withValues(alpha: 0.2),
          AppColors.primaryDark.withValues(alpha: 0.48),
          AppColors.primary.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final shimmerWidth = size.width * 0.3;
    final shimmerLeft =
        -shimmerWidth + (size.width + shimmerWidth * 2) * search;
    final shimmerRect = Rect.fromLTWH(
      shimmerLeft,
      size.height * 0.58,
      shimmerWidth,
      6,
    );
    canvas.save();
    canvas.clipPath(road);
    canvas.drawRect(shimmerRect, shimmerPaint);
    canvas.restore();

    final dotPaint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 5; i++) {
      final t = ((search + i * 0.18) % 1.0).clamp(0.0, 1.0);
      final x = _lerp(size.width * 0.1, size.width * 0.88, t);
      final y = size.height * (0.74 - math.sin(t * math.pi) * 0.28);
      dotPaint.color = AppColors.primaryDark.withValues(alpha: 0.16 + t * 0.45);
      canvas.drawCircle(Offset(x, y), 3.2 + t * 1.2, dotPaint);
    }

    final labelPainter = TextPainter(
      text: TextSpan(
        text: vehicleType.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    labelPainter.paint(
      canvas,
      Offset(size.width * 0.5 - labelPainter.width / 2, size.height * 0.12),
    );

    final smallCarPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withValues(alpha: 0.15);
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.2),
      18 + math.sin(route * math.pi * 2) * 2,
      smallCarPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.28),
      14 + math.cos(route * math.pi * 2) * 2,
      smallCarPaint,
    );

    final iconPainter = TextPainter(
      text: TextSpan(
        text: _iconGlyph(vehicleIcon),
        style: const TextStyle(
          fontFamily: 'MaterialIcons',
          fontSize: 18,
          color: AppColors.primaryDark,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(size.width * 0.2 - 9, size.height * 0.2 - 10),
    );
  }

  String _iconGlyph(IconData iconData) {
    return String.fromCharCode(iconData.codePoint);
  }

  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  @override
  bool shouldRepaint(covariant _MapPulsePainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.route != route ||
        oldDelegate.search != search ||
        oldDelegate.vehicleType != vehicleType ||
        oldDelegate.vehicleIcon != vehicleIcon;
  }
}

// ── Rapido-style booking step dot ─────────────────────────────────────────────
class _StepDot extends StatelessWidget {
  final bool active;
  final String label;
  const _StepDot({required this.active, required this.label});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            width: active ? 14 : 10,
            height: active ? 14 : 10,
            decoration: BoxDecoration(
              color: active ? const Color(0xFF00C853) : const Color(0xFFEEEFF3),
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? const Color(0xFF00C853) : const Color(0xFFCDD0D8),
                width: 1.5,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00C853).withValues(alpha: 0.40),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFF1A1A2E) : const Color(0xFFB0B3C1),
            ),
          ),
        ],
      );
}

// ── Animated step connector line ──────────────────────────────────────────────
class _StepLine extends StatelessWidget {
  final double animate;
  const _StepLine({required this.animate});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 3,
              value: animate.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFEEEFF3),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C853)),
            ),
          ),
        ),
      );
}
