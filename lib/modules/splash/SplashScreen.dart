import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Keys.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/core/services/StorageService.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _mainAnimController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final AnimationController _rotationController;

  final StorageService _storage = StorageService();

  @override
  void initState() {
    super.initState();

    _mainAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = CurvedAnimation(
      parent: _mainAnimController,
      curve: Curves.easeIn,
    );

    _scaleAnim = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimController,
        curve: Curves.elasticOut,
      ),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    _mainAnimController.forward();

    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final token = _storage.read(StorageKeys.token);
    if (token is String && token.trim().isNotEmpty) {
      Get.offAllNamed(RouteNames.home);
    } else {
      Get.offAllNamed(RouteNames.login);
    }
  }

  @override
  void dispose() {
    _mainAnimController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Stack(
        children: [
          // ── Background Glow Blobs ─────────────────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C853).withValues(alpha: 0.12),
                    blurRadius: 70,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.10),
                    blurRadius: 80,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // ── Center Branding & Content ──────────────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Animated Traditional Aura Ring + App Emblem ─────────
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Rotating Traditional Mandala Ring
                        AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationController.value * math.pi * 2,
                              child: CustomPaint(
                                size: const Size(160, 160),
                                painter: _TraditionalMandalaPainter(),
                              ),
                            );
                          },
                        ),

                        // Center Emblem Box
                        Container(
                          width: 104,
                          height: 104,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C853), Color(0xFF009624)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00C853).withValues(alpha: 0.40),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.local_taxi_rounded,
                              size: 54,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ── Brand Title ──────────────────────────────────────────
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Indica',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'B',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── Traditional Accent Divider ───────────────────────────
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF00C853).withValues(alpha: 0.8),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.star_rounded,
                            size: 12,
                            color: Color(0xFFFFB300),
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF00C853).withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ── Tagline ──────────────────────────────────────────────
                    Text(
                      'Your Trusted Ride, Every Time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.70),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom Loading Bar & India Badge ───────────────────────────────
          Positioned(
            bottom: 44,
            left: 0,
            right: 0,
            child: Column(
              children: [
                SizedBox(
                  width: 140,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF00C853),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'MADE WITH ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB0B3C1),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Text(
                      '❤️',
                      style: TextStyle(fontSize: 12),
                    ),
                    const Text(
                      ' IN INDIA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFB300),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Traditional Mandala Decorative Aura Painter ──────────────────────────────
class _TraditionalMandalaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF00C853).withValues(alpha: 0.35);

    final goldPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFFFFB300).withValues(alpha: 0.40);

    // Outer circle
    canvas.drawCircle(center, radius - 2, linePaint);

    // Inner dashed circle
    canvas.drawCircle(center, radius - 12, goldPaint);

    // 8 Traditional Lotus / Mandala Petals
    const numPetals = 8;
    for (var i = 0; i < numPetals; i++) {
      final angle = (i * 2 * math.pi) / numPetals;
      final x1 = center.dx + (radius - 2) * math.cos(angle);
      final y1 = center.dy + (radius - 2) * math.sin(angle);
      canvas.drawCircle(
        Offset(x1, y1),
        3,
        Paint()..color = const Color(0xFFFFB300).withValues(alpha: 0.70),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
