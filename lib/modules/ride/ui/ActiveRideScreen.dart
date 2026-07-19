import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:indicab/core/config/Config.dart';
import 'package:indicab/core/services/SocketService.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/network/network_exceptions.dart';
import 'package:indicab/core/repository/BookingRepository.dart';
import 'package:indicab/core/models/booking_response.dart';
import 'package:indicab/modules/ride/ui/track_ride_screen.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/modules/ride/ui/sos_screen.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key, this.bookingNo, this.bookingData});

  final String? bookingNo;
  final BookingDataModel? bookingData;

  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen>
    with WidgetsBindingObserver {
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Timer? _refreshTimer;
  BookingDataModel? _bookingData;
  bool _isLoading = false;
  LatLng? _driverPosition;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
    if (_bookingData != null) {
      final driverLat = double.tryParse(_bookingData?.driverLatitude ?? '');
      final driverLng = double.tryParse(_bookingData?.driverLongitude ?? '');
      if (driverLat != null && driverLng != null) {
        _driverPosition = LatLng(driverLat, driverLng);
      }
    }
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildMarkersAndPolyline();
    });
    _fetchBookingDetails();
    _startAutoRefresh();

    // Subscribe to WebSocket driver location updates
    final socketService = Get.find<SocketService>();
    socketService.on('driver_location_update', _onDriverLocationUpdate);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _fetchBookingDetails();
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    final bookingNo = widget.bookingNo?.trim();
    if (bookingNo == null || bookingNo.isEmpty) {
      return;
    }

    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _fetchBookingDetails(silent: true);
    });
  }

  Future<void> _fetchBookingDetails({bool silent = false}) async {
    final bookingNo = widget.bookingNo?.trim();
    if (bookingNo == null || bookingNo.isEmpty) return;

    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final BookingRepository bookingRepository = BookingRepository(ApiClient());
    try {
      final response = await bookingRepository.getBooking(
        bookingNo,
        includeOtp: true,
      );
      final bookingData = response.data;
      if (bookingData != null && mounted) {
        final oldDriverLat = _driverPosition?.latitude;
        final oldDriverLng = _driverPosition?.longitude;

        final driverLat = double.tryParse(bookingData.driverLatitude ?? '');
        final driverLng = double.tryParse(bookingData.driverLongitude ?? '');
        if (driverLat != null && driverLng != null) {
          _driverPosition = LatLng(driverLat, driverLng);
        }

        final shouldRebuildMap =
            bookingData.pickupLatitude != _bookingData?.pickupLatitude ||
            bookingData.pickupLongitude != _bookingData?.pickupLongitude ||
            bookingData.dropLatitude != _bookingData?.dropLatitude ||
            bookingData.dropLongitude != _bookingData?.dropLongitude ||
            driverLat != oldDriverLat ||
            driverLng != oldDriverLng;

        setState(() {
          _bookingData = bookingData;
        });

        if (shouldRebuildMap) {
          _markers.clear();
          _polylines.clear();
          _buildMarkersAndPolyline();
        }
      }
    } catch (e) {
      if (e is NetworkException && e.statusCode == 401) {
        return; // Handled by global handler
      }
      Get.snackbar(
        'Error',
        'Failed to fetch ride details: $e',
        backgroundColor: AppColors.surface,
      );
    } finally {
      if (!silent && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String get _bookingNoLabel =>
      _bookingData?.bookingNo ?? widget.bookingNo ?? 'Ride in progress';

  String get _driverName => _bookingData?.driverName?.trim().isNotEmpty == true
      ? _bookingData!.driverName!.trim()
      : 'Driver';

  String get _vehicleLabel {
    final parts = <String>[
      if (_bookingData?.vehicleName?.trim().isNotEmpty == true)
        _bookingData!.vehicleName!.trim(),
      if (_bookingData?.vehicleNumber?.trim().isNotEmpty == true)
        _bookingData!.vehicleNumber!.trim(),
    ];

    if (parts.isEmpty) {
      return 'Vehicle details pending';
    }

    return parts.join(' • ');
  }

  String get _pickupLabel =>
      _bookingData?.pickupAddress ?? 'Waiting for live pickup location';

  String get _dropLabel =>
      _bookingData?.dropAddress ??
      'Destination will be updated by socket event';

  String get _statusLabel {
    final status = _bookingData?.status?.trim();
    if (status == null || status.isEmpty) {
      return 'Ride in progress';
    }

    return switch (status) {
      'started' => 'Ride in progress',
      'completed' => 'Ride completed',
      _ => status,
    };
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    final socketService = Get.find<SocketService>();
    socketService.off('driver_location_update', _onDriverLocationUpdate);
    super.dispose();
  }

  void _onDriverLocationUpdate(dynamic data) {
    if (data is! Map<String, dynamic> || !mounted) return;
    
    final bookingNo = data['booking_no']?.toString();
    if (bookingNo != widget.bookingNo) return;

    final lat = double.tryParse(data['latitude']?.toString() ?? '');
    final lng = double.tryParse(data['longitude']?.toString() ?? '');

    if (lat != null && lng != null) {
      setState(() {
        _driverPosition = LatLng(lat, lng);
      });
      _buildMarkersAndPolyline(notify: true);
    }
  }

  Future<List<LatLng>> _getDirections(LatLng origin, LatLng destination) async {
    final key = AppEnv.googleMapsApiKey;
    if (key.isEmpty) {
      return [origin, destination];
    }

    try {
      final dio = Dio();
      final url = 'https://maps.googleapis.com/maps/api/directions/json'
          '?origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&key=$key';

      final response = await dio.get(url);
      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final routes = response.data['routes'] as List;
        if (routes.isNotEmpty) {
          final points = routes[0]['overview_polyline']['points'] as String;
          return _decodePolyline(points);
        }
      }
    } catch (e) {
      debugPrint('Error fetching directions: $e');
    }

    return [origin, destination];
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> poly = [];
    int index = 0, len = encoded.length;
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

  Future<void> _buildMarkersAndPolyline({bool notify = true}) async {
    if (_bookingData == null) return;

    final booking = _bookingData!;
    final pickupLat = double.tryParse(booking.pickupLatitude ?? '');
    final pickupLng = double.tryParse(booking.pickupLongitude ?? '');
    final dropLat = double.tryParse(booking.dropLatitude ?? '');
    final dropLng = double.tryParse(booking.dropLongitude ?? '');

    if (pickupLat == null || pickupLng == null) return;

    final pickupPosition = LatLng(pickupLat, pickupLng);
    List<LatLng> polylineCoordinates = [pickupPosition];

    if (booking.requiresDropLocation && dropLat != null && dropLng != null) {
      final dropPosition = LatLng(dropLat, dropLng);
      polylineCoordinates = await _getDirections(pickupPosition, dropPosition);
    }

    void updateState() {
      _markers.clear();
      _polylines.clear();

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

      if (booking.requiresDropLocation && dropLat != null && dropLng != null) {
        final dropPosition = LatLng(dropLat, dropLng);
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

      if (_driverPosition != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('driver'),
            position: _driverPosition!,
            infoWindow: const InfoWindow(title: 'Driver Location'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
          ),
        );
      }

      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylineCoordinates,
          color: AppColors.primary,
          width: 5,
        ),
      );
    }

    if (notify && mounted) {
      setState(updateState);
      _adjustMapBounds();
    } else {
      updateState();
      _adjustMapBounds();
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _bookingData?.status?.trim().toLowerCase();
    final isStarted = status == 'started';
    final isAccepted = status == 'accepted';
    final otp = _bookingData?.startOtp;

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                double.tryParse(_bookingData?.pickupLatitude ?? '0') ?? 20.5937,
                double.tryParse(_bookingData?.pickupLongitude ?? '0') ??
                    78.9629,
              ),
              zoom: 14,
            ),
            onMapCreated: (GoogleMapController controller) {
              _mapController.complete(controller);
            },
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      Get.offAllNamed(
                        RouteNames.home,
                        arguments: <String, dynamic>{'from_active_ride': true},
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
                          Text(
                            _statusLabel,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  InkWell(
                    onTap: () {
                      Get.to(
                        () => TrackRideScreen(
                          bookingNo: widget.bookingNo,
                          bookingData: _bookingData,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
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
                        Icons.track_changes_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.38,
            minChildSize: 0.38,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  crossAxisAlignment: CrossAxisAlignment.end,
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
                                      borderRadius: BorderRadius.circular(20),
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
                                      'booking_no':
                                          widget.bookingNo ??
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
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            isStarted
                                ? 'Share this OTP to End the Ride'
                                : isAccepted
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
                                  isStarted ? 'Completion OTP' : 'Ride OTP',
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
                          if (_bookingData?.requiresDropLocation != false) ...[
                            const SizedBox(height: 14),
                            _RouteStep(
                              icon: Icons.location_on_rounded,
                              title: 'Drop',
                              subtitle: _dropLabel,
                            ),
                          ],
                          const SizedBox(height: 28),
                          InkWell(
                            onTap: () => Get.to(() => const SosScreen()),
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.18),
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
