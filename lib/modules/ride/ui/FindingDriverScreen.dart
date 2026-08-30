import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
      final args = Get.arguments;
      if (args is Map && args['booking_no'] != null && args['booking_no'].toString().trim().isNotEmpty) {
        _localBookingNo = args['booking_no'].toString().trim();
      }
    }

    if (_localBookingNo == null || _localBookingNo!.trim().isEmpty) {
      final storedBookingNo = _storage.read(StorageKeys.pendingRideBookingNo);
      if (storedBookingNo is String && storedBookingNo.trim().isNotEmpty) {
        _localBookingNo = storedBookingNo.trim();
      }
    }

    if (_localVehicleType == null || _localVehicleType!.trim().isEmpty) {
      final args = Get.arguments;
      if (args is Map && args['vehicle_type'] != null && args['vehicle_type'].toString().trim().isNotEmpty) {
        _localVehicleType = args['vehicle_type'].toString().trim();
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
        backgroundColor: const Color(0xFFF8FAFC),
        body: Stack(
          children: [
            // 1. Clean Fullscreen Light Map Backdrop with Pickup Pulse Halo
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return _GoogleMapsScanningBackdrop(
                    pickupLatLng: _pickupLatLng,
                    pulseProgress: _pulseController.value,
                    vehicleIcon: _vehicleIcon,
                  );
                },
              ),
            ),

            // 2. Top Floating Header Bar (Glassmorphic Light Pill)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, left: 16, right: 16),
                child: Row(
                  children: [
                    // Back button
                    InkWell(
                      onTap: _handleGoBack,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
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

                    // Status Header Pill
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
                              color: Color(0x1A000000),
                              blurRadius: 18,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF5B800),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFFF5B800),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'SEARCHING FOR DRIVERS',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _statusText,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. Corporate Bottom Search Card Layout
            Align(
              alignment: Alignment.bottomCenter,
              child: _SearchCard(
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
            ),
          ],
        ),
      ),
    );
  }
}

/// Clean light map style JSON for professional corporate presentation
const String _lightMapStyleJson = '''
[
  {"elementType":"geometry","stylers":[{"color":"#f8fafc"}]},
  {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#64748b"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#ffffff"}]},
  {"featureType":"administrative.land_parcel","elementType":"labels.text.fill","stylers":[{"color":"#cbd5e1"}]},
  {"featureType":"poi","elementType":"geometry","stylers":[{"color":"#f1f5f9"}]},
  {"featureType":"poi","elementType":"labels.text.fill","stylers":[{"color":"#64748b"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ffffff"}]},
  {"featureType":"road.arterial","elementType":"labels.text.fill","stylers":[{"color":"#475569"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#fde68a"}]},
  {"featureType":"road.highway","elementType":"labels.text.fill","stylers":[{"color":"#92400e"}]},
  {"featureType":"road.local","elementType":"labels.text.fill","stylers":[{"color":"#64748b"}]},
  {"featureType":"transit.line","elementType":"geometry","stylers":[{"color":"#e2e8f0"}]},
  {"featureType":"transit.station","elementType":"geometry","stylers":[{"color":"#f1f5f9"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#e0f2fe"}]},
  {"featureType":"water","elementType":"labels.text.fill","stylers":[{"color":"#0284c7"}]}
]
''';

class _GoogleMapsScanningBackdrop extends StatelessWidget {
  final LatLng pickupLatLng;
  final double pulseProgress;
  final IconData vehicleIcon;

  const _GoogleMapsScanningBackdrop({
    required this.pickupLatLng,
    required this.pulseProgress,
    required this.vehicleIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Google Maps Layer with Professional Light Map Style
        Positioned.fill(
          child: GoogleMap(
            style: _lightMapStyleJson,
            initialCameraPosition: CameraPosition(
              target: pickupLatLng,
              zoom: 15.4,
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

        // 2. Subtle Pickup Pulse Halo CustomPainter Layer
        Positioned.fill(
          child: CustomPaint(
            painter: _PickupRipplePainter(
              pulseProgress: pulseProgress,
            ),
          ),
        ),
      ],
    );
  }
}

/// Subtle, professional expanding pulse halo around pickup point
class _PickupRipplePainter extends CustomPainter {
  final double pulseProgress;

  _PickupRipplePainter({required this.pulseProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.38);
    const maxRadius = 90.0;

    // Expanding soft golden halo rings
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (var i = 0; i < 2; i++) {
      final p = (pulseProgress + i * 0.5) % 1.0;
      final r = 30.0 + p * (maxRadius - 30.0);
      final alpha = (1.0 - p).clamp(0.0, 1.0) * 0.35;
      ringPaint.color = const Color(0xFFF5B800).withValues(alpha: alpha);
      canvas.drawCircle(center, r, ringPaint);
    }

    // Outer glow halo
    canvas.drawCircle(
      center,
      28,
      Paint()
        ..color = const Color(0xFFF5B800).withValues(alpha: 0.18)
        ..style = PaintingStyle.fill,
    );

    // Center Pin Core
    canvas.drawCircle(
      center,
      14,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center,
      12,
      Paint()..color = const Color(0xFF1E1B4B),
    );
    canvas.drawCircle(
      center,
      6,
      Paint()..color = const Color(0xFFF5B800),
    );
  }

  @override
  bool shouldRepaint(covariant _PickupRipplePainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress;
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: Color(0xFFF5B800),
            width: 2.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 28,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Indicator Handle
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

            // Vehicle Icon Pulse Avatar
            if (bookingError == null) ...[
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF5B800),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x15000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      vehicleIcon,
                      size: 38,
                      color: const Color(0xFF1E1B4B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Rapido-style Animated Linear Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(
                  minHeight: 4,
                  backgroundColor: Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Color(0xFFF5B800),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3-Step Booking Timeline
              Row(
                children: [
                  const _StepDot(active: true, label: 'Placed'),
                  _StepLine(animate: search),
                  _StepDot(
                    active: !isCreatingBooking && bookingNo.isNotEmpty,
                    label: 'Matching',
                  ),
                  _StepLine(animate: route),
                  _StepDot(
                    active: bookingData?.driverName?.trim().isNotEmpty == true,
                    label: 'Confirmed',
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFFCA5A5),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 36,
                  color: Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Main Title
            Text(
              bookingError != null
                  ? 'Booking Request Failed'
                  : isCreatingBooking
                      ? 'Requesting Your Ride...'
                      : 'Searching for Nearby Drivers',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle Description
            Text(
              bookingError != null
                  ? (bookingError!.contains('Exception:')
                      ? bookingError!.replaceAll('Exception: ', '')
                      : bookingError!)
                  : isCreatingBooking
                      ? 'Connecting and sending your ride request...'
                      : 'Matching your ${vehicleType.toUpperCase()} request with top-rated drivers nearby...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),

            // Booking Details Summary Box
            if (bookingNo.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number_rounded,
                      size: 16,
                      color: Color(0xFFF5B800),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BOOKING ID',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Text(
                            '#$bookingNo',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0F172A),
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
                            'ASSIGNED DRIVER',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                          Text(
                            bookingData!.driverName!.trim(),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Retry Button (If Error)
            if (bookingError != null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1B4B),
                    foregroundColor: const Color(0xFFF5B800),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'RETRY BOOKING',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Cancel Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isCancelling ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(
                    color: Color(0xFFFCA5A5),
                    width: 1.5,
                  ),
                  backgroundColor: const Color(0xFFFEF2F2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: isCancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFDC2626),
                        ),
                      )
                    : const Text(
                        'Cancel Request',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFDC2626),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
              color: active ? const Color(0xFFF5B800) : const Color(0xFFE2E8F0),
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? const Color(0xFF1E1B4B) : const Color(0xFFCBD5E1),
                width: 1.5,
              ),
              boxShadow: active
                  ? [
                      const BoxShadow(
                        color: Color(0x33F5B800),
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
              fontWeight: FontWeight.w800,
              color: active ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      );
}

class _StepLine extends StatelessWidget {
  final double animate;
  const _StepLine({required this.animate});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 3,
              value: animate.clamp(0.0, 1.0),
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFF5B800),
              ),
            ),
          ),
        ),
      );
}

