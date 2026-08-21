import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/modules/home/HomeController.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEEFF3), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Obx(() {
            final pickup = controller.pickupAddress.value;
            final drop = controller.dropAddress.value;
            final hasPickup = pickup.isNotEmpty;
            final hasDrop = drop.isNotEmpty;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Left route rail ───────────────────────────────────
                  SizedBox(
                    width: 24,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pickup dot
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C853)
                                    .withValues(alpha: 0.4),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        // Dashed line
                        Expanded(
                          child: CustomPaint(
                            painter: _DashedLinePainter(),
                          ),
                        ),
                        // Destination teardrop
                        const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFFE53935),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ── Right: pickup + divider + destination ─────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pickup line
                        Text(
                          hasPickup ? pickup : 'Choose pickup location',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: hasPickup
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: hasPickup
                                ? const Color(0xFF1A1A2E)
                                : const Color(0xFFB0B3C1),
                          ),
                        ),
                        Divider(
                          height: 14,
                          thickness: 1,
                          color: const Color(0xFFEEEFF3),
                        ),
                        // Destination line
                        Text(
                          hasDrop ? drop : 'Where to?',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: hasDrop
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: hasDrop
                                ? const Color(0xFF1A1A2E)
                                : const Color(0xFF5C5E6E),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Chevron ───────────────────────────────────────────
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Center(
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 24,
                        color: Color(0xFFB0B3C1),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Dashed vertical line painter (reused from LocationSearchScreen)
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashH = 3.5;
    const gapH = 2.5;
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
