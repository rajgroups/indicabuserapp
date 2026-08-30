import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/modules/home/HomeController.dart';
import 'package:indicab/shared/widgets/MapViewWidget.dart';

class LocationSearchScreen extends StatefulWidget {
  const LocationSearchScreen({super.key});

  @override
  State<LocationSearchScreen> createState() => _LocationSearchScreenState();
}

class _LocationSearchScreenState extends State<LocationSearchScreen> {
  final HomeController controller = Get.find<HomeController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.exitLocationSelection();
      controller.updateRoutePolyline();
      // If both locations are set, zoom map to fit both markers.
      controller.focusMapOnLocations();
    });
  }

  void _navigateToMapPicker({required String target}) {
    Get.toNamed(
      RouteNames.pickLocationMap,
      arguments: <String, dynamic>{'target': target},
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: Stack(
        children: [
          // ── Background map ──────────────────────────────────────────────
          Obx(
            () => MapViewWidget(
              pickupLocation:
                  controller.pickuplocation.value ?? controller.pickupPoint.value,
              dropLocation: controller.droplocation.value,
              onMapCreated: controller.onMapCreated,
              markers: controller.markers,
              polylines: controller.polylines,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: true,
            ),
          ),

          // ── Top card: header + Rapido-style route selector ─────────────
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
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header row
                  Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () {
                          controller.exitLocationSelection();
                          Get.back();
                        },
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Select Trip Locations',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Rapido-style route row ────────────────────────────
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left rail: icons + dashed connector
                        SizedBox(
                          width: 36,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Pickup circle dot
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00C853),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00C853)
                                          .withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              // Dashed vertical line
                              Expanded(
                                child: CustomPaint(
                                  painter: _DashedLinePainter(),
                                ),
                              ),
                              // Destination teardrop icon
                              Icon(
                                Icons.location_on_rounded,
                                color: const Color(0xFFE53935),
                                size: 22,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Right: pickup + destination fields
                        Expanded(
                          child: Column(
                            children: [
                              // Pickup field
                              Obx(() {
                                final addr = controller.pickupAddress.value;
                                final has = addr.isNotEmpty;
                                return _LocationField(
                                  text: has ? addr : 'Choose pickup location',
                                  hint: !has,
                                  onTap: () =>
                                      _navigateToMapPicker(target: 'pickup'),
                                  onClear: has ? controller.clearPickup : null,
                                  accentColor: const Color(0xFF00C853),
                                );
                              }),

                              Divider(
                                height: 14,
                                thickness: 1,
                                color: const Color(0xFFEEEFF3),
                              ),

                              // Destination field
                              Obx(() {
                                final addr = controller.dropAddress.value;
                                final has = addr.isNotEmpty;
                                return _LocationField(
                                  text: has
                                      ? addr
                                      : 'Choose destination location',
                                  hint: !has,
                                  onTap: () =>
                                      _navigateToMapPicker(target: 'drop'),
                                  onClear: has ? controller.clearDrop : null,
                                  accentColor: const Color(0xFFE53935),
                                );
                              }),
                            ],
                          ),
                        ),

                        // Swap button on right
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Center(
                            child: _SwapButton(onTap: controller.swapLocations),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom confirm bar ──────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Obx(() {
              final hasDrop = controller.droplocation.value != null;
              return Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasDrop) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF00C853),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.dropAddress.value.isNotEmpty
                                  ? controller.dropAddress.value
                                  : 'Destination selected',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          controller.exitLocationSelection();
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A2E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Confirm Locations',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Rapido-style tappable location field ─────────────────────────────────────
class _LocationField extends StatelessWidget {
  final String text;
  final bool hint;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final Color accentColor;

  const _LocationField({
    required this.text,
    required this.hint,
    required this.onTap,
    this.onClear,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: hint ? FontWeight.w400 : FontWeight.w700,
                    color: hint
                        ? const Color(0xFFB0B3C1)
                        : const Color(0xFF1A1A2E),
                  ),
                ),
              ),
              if (onClear != null && !hint)
                GestureDetector(
                  onTap: onClear,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      Icons.cancel_rounded,
                      size: 20,
                      color: Color(0xFFB0B3C1),
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: Color(0xFFB0B3C1),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Swap button ───────────────────────────────────────────────────────────────
class _SwapButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SwapButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F6),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Icon(
              Icons.swap_vert_rounded,
              size: 20,
              color: Color(0xFF5C5E6E),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Small circle icon back button ────────────────────────────────────────────
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

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

// ── Dashed vertical line painter ─────────────────────────────────────────────
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashH = 4.0;
    const gapH = 3.0;
    final paint = Paint()
      ..color = const Color(0xFFCDD0D8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + dashH).clamp(0, size.height)),
        paint,
      );
      y += dashH + gapH;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
