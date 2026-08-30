import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/config/Config.dart';
import 'package:indicab/modules/home/HomeController.dart';
import 'package:indicab/shared/widgets/MapViewWidget.dart';
import 'package:indicab/shared/widgets/google_places_input.dart';

class PickLocationMapScreen extends StatefulWidget {
  const PickLocationMapScreen({super.key});

  @override
  State<PickLocationMapScreen> createState() => _PickLocationMapScreenState();
}

class _PickLocationMapScreenState extends State<PickLocationMapScreen> {
  final HomeController controller = Get.find<HomeController>();
  late final LocationSelectionTarget _target;
  late final int _stopIndex;

  bool get _isPickup => _target == LocationSelectionTarget.pickup;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    if (args is Map) {
      final rawTarget = args['target']?.toString().toLowerCase().trim();
      _target = (rawTarget == 'drop' || rawTarget == 'destination')
          ? LocationSelectionTarget.drop
          : LocationSelectionTarget.pickup;
      _stopIndex = (args['stop_index'] is int) ? args['stop_index'] as int : 0;
    } else {
      _target = LocationSelectionTarget.pickup;
      _stopIndex = 0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.setLocationTarget(_target);
      if (!_isPickup && _stopIndex > 0) {
        controller.setActiveDropStop(_stopIndex);
      }
      controller.isMapViewMode.value = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasValidPlacesKey = AppEnv.hasGooglePlacesApiKey;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final controllerToUse = _isPickup
        ? controller.originController
        : (_stopIndex < controller.dropStops.length
            ? controller.dropStops[_stopIndex].controller
            : controller.destController);

    final hintText =
        _isPickup ? 'Search pickup location' : 'Search destination';

    // Rapido colors
    const pickupColor = Color(0xFF00C853);
    const dropColor = Color(0xFFE53935);
    final pinColor = _isPickup ? pickupColor : dropColor;
    final confirmLabel =
        _isPickup ? 'Confirm Pickup' : 'Confirm Destination';

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) controller.exitLocationSelection();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F6FA),
        body: Stack(
          children: [
            // ── Full-screen map ──────────────────────────────────────────
            Obx(
              () => MapViewWidget(
                pickupLocation:
                    controller.pickuplocation.value ?? controller.pickupPoint.value,
                dropLocation: controller.droplocation.value,
                onMapCreated: controller.onMapCreated,
                onCameraMove: controller.onLocationMapCameraMove,
                onCameraMoveStarted: controller.onCameraMoveStarted,
                onCameraIdle: controller.onLocationMapCameraIdle,
                markers: controller.markers,
                polylines: controller.polylines,
                scrollGesturesEnabled: true,
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
              ),
            ),

            // ── Animated center pin ──────────────────────────────────────
            Obx(() {
              if (!controller.isMapViewMode.value &&
                  !controller.isMapDragging.value) {
                return const SizedBox.shrink();
              }

              final isDragging = controller.isMapDragging.value;
              final isLocating = controller.isReverseGeocodingCenter.value;

              final String addressText = isDragging
                  ? 'Pinning…'
                  : isLocating
                      ? 'Getting address…'
                      : (_isPickup
                          ? (controller.pickupAddress.value.isNotEmpty
                              ? controller.pickupAddress.value
                              : 'Move map to set pickup')
                          : (controller.dropAddress.value.isNotEmpty
                              ? controller.dropAddress.value
                              : 'Move map to set destination'));

              return Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 52),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Floating address pill ────────────────────────
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        constraints: const BoxConstraints(maxWidth: 260),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isDragging || isLocating)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF00C853),
                                    ),
                                  ),
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  _isPickup
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.location_on_rounded,
                                  size: 14,
                                  color: pinColor,
                                ),
                              ),
                            Flexible(
                              child: Text(
                                addressText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Animated pin body ────────────────────────────
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        transform: Matrix4.translationValues(
                          0,
                          isDragging ? -10 : 0,
                          0,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Glow ring when dragging
                            if (isDragging)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: pinColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            // Outer colored ring
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: pinColor,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: pinColor.withValues(alpha: 0.45),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _isPickup
                                          ? Icons.radio_button_checked_rounded
                                          : Icons.location_on_rounded,
                                      size: 12,
                                      color: pinColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Pin tip triangle
                      CustomPaint(
                        size: const Size(14, 8),
                        painter: _PinTipPainter(color: pinColor),
                      ),

                      // Shadow ellipse on ground
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: isDragging ? 10 : 16,
                        height: isDragging ? 3 : 5,
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withValues(alpha: isDragging ? 0.10 : 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // ── Top header + search input ────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(14, topPadding + 8, 14, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        _CircleButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () {
                            controller.exitLocationSelection();
                            Get.back();
                          },
                        ),
                        const SizedBox(width: 12),
                        // Mode badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isPickup
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPickup
                                    ? Icons.radio_button_checked_rounded
                                    : Icons.location_on_rounded,
                                size: 13,
                                color: pinColor,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isPickup ? 'Pickup' : 'Destination',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: pinColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // API key warning
                    if (!hasValidPlacesKey)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: const Color(0xFFFDA4AF)),
                        ),
                        child: const Text(
                          'Google Places API key missing. Search is disabled.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF9F1239),
                          ),
                        ),
                      ),

                    // Search field
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: pinColor.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: GooglePlacesInput(
                        hintText: hintText,
                        controller: controllerToUse,
                        prefixIcon: _isPickup
                            ? Icons.radio_button_checked_rounded
                            : Icons.location_on_rounded,
                        onTap: () {
                          // When user taps the input, stop the dragging animation
                          // so the center pin returns to settled (non-"Pinning…") state.
                          controller.onInputFocused();
                          controller.setLocationTarget(_target);
                        },
                        onClear: () {
                          controllerToUse.clear();
                          if (_isPickup) {
                            controller.clearPickup();
                          } else {
                            _stopIndex > 0
                                ? controller.removeDropStop(_stopIndex)
                                : controller.clearDrop();
                          }
                        },
                        onPlaceSelected: (place) {
                          controller.setLocationTarget(_target);

                          // Build the set-location future based on target type.
                          final Future<void> setFuture;
                          if (_isPickup) {
                            setFuture = controller.setPickup(place);
                          } else {
                            setFuture = _stopIndex > 0
                                ? controller.setDropStop(_stopIndex, place)
                                : controller.setDrop(place);
                          }

                          // After the location is committed (which also calls
                          // _focusMapOnSelectedLocations → fit-to-bounds),
                          // re-center the camera exactly on the selected place so
                          // the center pin appears right on top of the marker —
                          // not at the midpoint of pickup+drop.
                          unawaited(setFuture.then((_) async {
                            await controller.refocusOnSelectedLocation();
                            controller.isMapViewMode.value = true;
                          }));
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── My-location FAB ──────────────────────────────────────────
            Positioned(
              right: 16,
              bottom: bottomPadding + 90,
              child: Material(
                color: Colors.white,
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.15),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () =>
                      controller.detectAndSetCurrentLocation(force: true),
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Center(
                      child: Icon(
                        Icons.my_location_rounded,
                        color: Color(0xFF1A1A2E),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Confirm button ───────────────────────────────────────────
            Positioned(
              bottom: bottomPadding + 16,
              left: 16,
              right: 16,
              child: ElevatedButton(
                onPressed: () {
                  controller.exitLocationSelection();
                  Get.back();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPickup
                      ? const Color(0xFF00C853)
                      : const Color(0xFFE53935),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  confirmLabel,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
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

// ── Small circular icon button ────────────────────────────────────────────────
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F6),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Center(
            child: Icon(icon, size: 20, color: const Color(0xFF1A1A2E)),
          ),
        ),
      ),
    );
  }
}

// ── Pin tip triangle painter ──────────────────────────────────────────────────
class _PinTipPainter extends CustomPainter {
  final Color color;
  const _PinTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTipPainter old) => old.color != color;
}
