import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/core/services/SocketService.dart';

class FindingDriverScreen extends StatefulWidget {
  const FindingDriverScreen({super.key, this.vehicleType});

  final String? vehicleType;

  @override
  State<FindingDriverScreen> createState() => _FindingDriverScreenState();
}

class _FindingDriverScreenState extends State<FindingDriverScreen>
    with TickerProviderStateMixin {
  String _statusText = 'Finding your ride...';

  final SocketService _socketService = Get.find<SocketService>();
  late final AnimationController _pulseController;
  late final AnimationController _routeController;
  late final AnimationController _searchController;

  @override
  void initState() {
    super.initState();
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

    // Listen for booking status updates
    _socketService.on('booking_status', _handleBookingStatus);
  }

  void _handleBookingStatus(dynamic data) {
    if (data is! Map<String, dynamic>) return;

    final booking = data['booking'] as Map<String, dynamic>?;
    if (booking == null) return;

    final status = booking['status'] as String?;
    final bookingNo = booking['booking_no'] as String?;

    if (status == 'accepted' && bookingNo != null) {
      // A driver has been found, navigate to the ride screen.
      Get.offNamed(RouteNames.rideOtp, arguments: {'booking_no': bookingNo});
    } else {
      // You can handle other statuses here, like 'cancelled' or 'no_drivers_found'.
    }
  }

  String get _vehicleTypeLabel {
    final value = widget.vehicleType?.trim();
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

  @override
  void dispose() {
    _pulseController.dispose();
    _routeController.dispose();
    _searchController.dispose();
    _socketService.off('booking_status', _handleBookingStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: _RideSearchBackdrop()),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _pulseController,
                _routeController,
                _searchController,
              ]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _RideSearchPainter(
                    pulseValue: _pulseController.value,
                    routeValue: _routeController.value,
                    searchValue: _searchController.value,
                    vehicleLabel: _vehicleTypeLabel,
                    vehicleIcon: _vehicleIcon,
                  ),
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
                      InkWell(
                        onTap: Get.back,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 18,
                                offset: Offset(0, 8),
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
                            color: AppColors.surface.withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x12000000),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Searching for nearby drivers',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _statusText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
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
                    onCancel: () {
                      Get.back();
                    },
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

class _RideSearchBackdrop extends StatelessWidget {
  const _RideSearchBackdrop();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF9F7F1), Color(0xFFF4F0E5), Color(0xFFECE3CF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -54,
            left: -42,
            child: _GlowBlob(
              size: 180,
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            top: 110,
            right: -44,
            child: _GlowBlob(
              size: 150,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          Positioned(
            bottom: -48,
            left: 26,
            child: _GlowBlob(
              size: 220,
              color: AppColors.primaryLight.withValues(alpha: 0.18),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.pulse,
    required this.route,
    required this.search,
    required this.vehicleIcon,
    required this.vehicleType,
    required this.onCancel,
  });

  final double pulse;
  final double route;
  final double search;
  final IconData vehicleIcon;
  final String vehicleType;
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
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Finding your ride',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We are matching your $vehicleType with the nearest available driver.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: Colors.red.withValues(alpha: 0.05),
              ),
              child: const Text(
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
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primaryLight.withValues(alpha: 0.52),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          Transform.rotate(
            angle: math.sin(route * math.pi * 2) * 0.04,
            child: Icon(vehicleIcon, size: 40, color: AppColors.primaryDark),
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

class _RideSearchPainter extends CustomPainter {
  _RideSearchPainter({
    required this.pulseValue,
    required this.routeValue,
    required this.searchValue,
    required this.vehicleLabel,
    required this.vehicleIcon,
  });

  final double pulseValue;
  final double routeValue;
  final double searchValue;
  final String vehicleLabel;
  final IconData vehicleIcon;

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.22)
      ..strokeWidth = 1;

    const gridSpacing = 42.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), roadPaint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), roadPaint);
    }

    final route = Path()
      ..moveTo(size.width * 0.12, size.height * 0.7)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.52,
        size.width * 0.54,
        size.height * 0.84,
        size.width * 0.88,
        size.height * 0.36,
      );

    final haloPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..color = Colors.white.withValues(alpha: 0.72)
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(route, haloPaint);

    final streakPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.primary.withValues(alpha: 0.2),
          AppColors.primaryDark.withValues(alpha: 0.5),
          AppColors.primary.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final streakWidth = size.width * 0.34;
    final streakLeft =
        -streakWidth + (size.width + streakWidth * 2) * routeValue;
    canvas.save();
    canvas.clipPath(route);
    canvas.drawRect(
      Rect.fromLTWH(streakLeft, size.height * 0.56, streakWidth, 6),
      streakPaint,
    );
    canvas.restore();

    final pulsePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withValues(alpha: 0.14);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.6),
      88 + math.sin(pulseValue * math.pi * 2) * 8,
      pulsePaint,
    );

    final labelPainter = TextPainter(
      text: TextSpan(
        text: 'Searching $vehicleLabel',
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width * 0.8);
    labelPainter.paint(canvas, Offset(size.width * 0.08, size.height * 0.08));
  }

  @override
  bool shouldRepaint(covariant _RideSearchPainter oldDelegate) {
    return oldDelegate.pulseValue != pulseValue ||
        oldDelegate.routeValue != routeValue ||
        oldDelegate.searchValue != searchValue ||
        oldDelegate.vehicleLabel != vehicleLabel ||
        oldDelegate.vehicleIcon != vehicleIcon;
  }
}
