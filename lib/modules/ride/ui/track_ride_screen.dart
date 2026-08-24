import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/models/booking_response.dart';

class TrackRideScreen extends StatefulWidget {
  const TrackRideScreen({
    super.key,
    this.bookingNo,
    this.bookingData,
  });

  final String? bookingNo;
  final BookingDataModel? bookingData;

  @override
  State<TrackRideScreen> createState() => _TrackRideScreenState();
}

class _TrackRideScreenState extends State<TrackRideScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildMarkersAndPolyline();
    });
  }

  void _buildMarkersAndPolyline() {
    if (widget.bookingData == null) return;

    final booking = widget.bookingData!;
    final pickupLat = double.tryParse(booking.pickupLatitude ?? '');
    final pickupLng = double.tryParse(booking.pickupLongitude ?? '');
    final dropLat = double.tryParse(booking.dropLatitude ?? '');
    final dropLng = double.tryParse(booking.dropLongitude ?? '');

    if (pickupLat == null || pickupLng == null) return;

    final pickupPosition = LatLng(pickupLat, pickupLng);
    final List<LatLng> polylineCoordinates = [pickupPosition];

    setState(() {
      _markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: pickupPosition,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ));

      if (dropLat != null && dropLng != null) {
        final dropPosition = LatLng(dropLat, dropLng);
        polylineCoordinates.add(dropPosition);
        _markers.add(Marker(
          markerId: const MarkerId('drop'),
          position: dropPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ));
      }

      _polylines.add(Polyline(polylineId: const PolylineId('route'), points: polylineCoordinates, color: AppColors.primary, width: 5));
    });
  }

  String get _arrivalLabel {
    if (widget.bookingData?.status == 'started') {
      return 'Ride in progress';
    }
    return 'Arriving soon';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: () {
                final pLat = double.tryParse(widget.bookingData?.pickupLatitude ?? '');
                final pLng = double.tryParse(widget.bookingData?.pickupLongitude ?? '');
                if (pLat != null && pLng != null && pLat != 0 && pLng != 0) {
                  return LatLng(pLat, pLng);
                }
                final dLat = double.tryParse(widget.bookingData?.dropLatitude ?? '');
                final dLng = double.tryParse(widget.bookingData?.dropLongitude ?? '');
                if (dLat != null && dLng != null && dLat != 0 && dLng != 0) {
                  return LatLng(dLat, dLng);
                }
                return const LatLng(12.9756, 77.6050);
              }(),
              zoom: 14,
            ),
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
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

          // 2. Floating Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
              child: Row(
                children: [
                  InkWell(
                    onTap: Get.back,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Color(0x16000000), blurRadius: 18, offset: Offset(0, 6)),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(color: Color(0x16000000), blurRadius: 20, offset: Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Live Tracking',
                            style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _arrivalLabel,
                            style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Map Controls (Recenter)
          Positioned(
            right: 20,
            bottom: 120, // Positioned just above the driver card
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: IconButton(
                onPressed: () => Get.snackbar('Tracking', 'Map centered to route', backgroundColor: AppColors.surface),
                icon: const Icon(Icons.my_location_rounded, color: AppColors.primaryDark),
                tooltip: 'Recenter Map',
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: CustomPaint(
                foregroundPainter: const _TraditionalArchPainter(
                  color: Color(0xFF1A1A2E),
                ),
                child: Container(
                  margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 28, offset: Offset(0, 6))],
                  ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.local_taxi_rounded, size: 24, color: AppColors.primaryDark),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.bookingData?.vehicleNumber ?? '...', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          Text(widget.bookingData?.vehicleName ?? '...', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Get.snackbar('Calling', 'Connecting to driver...', backgroundColor: AppColors.surface),
                      borderRadius: BorderRadius.circular(99),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.call_rounded, size: 20, color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ],
      ),
    );
  }
}

class _TraditionalArchPainter extends CustomPainter {
  final Color color;

  const _TraditionalArchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Navy paint for outer curves
    final navyPaint = Paint()
      ..color = const Color(0xFF1A1A2E).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Gold/Amber paint for inner curves and details
    final goldPaint = Paint()
      ..color = const Color(0xFFF5B800).withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final fillGold = Paint()
      ..color = const Color(0xFFF5B800)
      ..style = PaintingStyle.fill;

    // --- Top-Right Corner Motif ---
    final trPath = Path();
    trPath.moveTo(size.width - 45, 0);
    trPath.quadraticBezierTo(size.width - 25, 0, size.width - 25, 20);
    trPath.quadraticBezierTo(size.width - 25, 40, size.width, 40);
    canvas.drawPath(trPath, navyPaint);

    final trPathInner = Path();
    trPathInner.moveTo(size.width - 30, 0);
    trPathInner.quadraticBezierTo(size.width - 15, 0, size.width - 15, 15);
    trPathInner.quadraticBezierTo(size.width - 15, 28, size.width, 28);
    canvas.drawPath(trPathInner, goldPaint);

    // Decorative Lotus/Accent Petals in Top-Right
    canvas.drawCircle(Offset(size.width - 15, 15), 3.0, fillGold);
    canvas.drawCircle(Offset(size.width - 25, 6), 2.0, fillGold);
    canvas.drawCircle(Offset(size.width - 6, 25), 2.0, fillGold);

    // --- Bottom-Left Corner Motif ---
    final blPath = Path();
    blPath.moveTo(0, size.height - 40);
    blPath.quadraticBezierTo(25, size.height - 40, 25, size.height - 20);
    blPath.quadraticBezierTo(25, size.height, 45, size.height);
    canvas.drawPath(blPath, navyPaint);

    final blPathInner = Path();
    blPathInner.moveTo(0, size.height - 28);
    blPathInner.quadraticBezierTo(15, size.height - 28, 15, size.height - 15);
    blPathInner.quadraticBezierTo(15, size.height, 30, size.height);
    canvas.drawPath(blPathInner, goldPaint);

    // Decorative Accent Dots in Bottom-Left
    canvas.drawCircle(Offset(15, size.height - 15), 3.0, fillGold);
    canvas.drawCircle(Offset(6, size.height - 25), 2.0, fillGold);
    canvas.drawCircle(Offset(25, size.height - 6), 2.0, fillGold);
  }

  @override
  bool shouldRepaint(covariant _TraditionalArchPainter oldDelegate) =>
      oldDelegate.color != color;
}