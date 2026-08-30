import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:indicab/core/config/Config.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/constants/Keys.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/repository/AppUpdateRepository.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/core/services/SecureStorageService.dart';
import 'package:indicab/core/services/StorageService.dart';
import 'package:indicab/shared/widgets/app_update_dialog.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _isNavigating = false;
  Timer? _failsafeTimer;

  late final AnimationController _mainAnimController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final AnimationController _pulseController;

  final StorageService _storage = StorageService();
  final SecureStorageService _secureStorage = SecureStorageService();
  final ApiClient _client = ApiClient();

  @override
  void initState() {
    super.initState();

    _mainAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = CurvedAnimation(
      parent: _mainAnimController,
      curve: Curves.easeOut,
    );

    _scaleAnim = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimController,
        curve: Curves.easeOutBack,
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _mainAnimController.forward();

    // ── Failsafe Timer ────────────────────────────────────────────────────────
    final int delaySec = AppEnv.splashDelaySeconds;
    _failsafeTimer = Timer(Duration(seconds: delaySec + 5), () {
      _performNavigation(false);
    });

    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final startTime = DateTime.now();
    bool isAuthorized = false;

    try {
      // 1. Check for app update
      try {
        final updateRepo = AppUpdateRepository(_client);
        final updateInfo = await updateRepo.checkUpdate(appVersion: '1.0.0');

        if (updateInfo.updateAvailable && mounted) {
          await AppUpdateDialog.show(
            context: context,
            updateModel: updateInfo,
            onDismiss: () {},
          );
          if (updateInfo.forceUpdate) {
            return;
          }
        }
      } catch (e) {
        debugPrint('[Splash] Update check error (continuing): $e');
      }

      // 2. Resolve authentication token
      final token = await _readStoredToken();
      isAuthorized = token != null && token.trim().isNotEmpty;

      if (isAuthorized) {
        _client.setTokens(token);
      }
    } catch (e) {
      debugPrint('[Splash] Auth check error: $e');
      isAuthorized = false;
    } finally {
      // Ensure splash remains visible for configured delay duration
      final elapsed = DateTime.now().difference(startTime);
      final targetDuration = Duration(seconds: AppEnv.splashDelaySeconds);
      final remaining = targetDuration - elapsed;
      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }

      _performNavigation(isAuthorized);
    }
  }

  Future<String?> _readStoredToken() async {
    try {
      final secureToken = await _secureStorage.read(StorageKeys.token);
      if (secureToken != null && secureToken.isNotEmpty) {
        final cachedToken = _storage.read(StorageKeys.token);
        if (cachedToken != secureToken) {
          _storage.write(StorageKeys.token, secureToken);
        }
        return secureToken;
      }
    } catch (e) {
      debugPrint('[Splash] Secure storage read error: $e');
    }

    final cachedToken = _storage.read(StorageKeys.token);
    if (cachedToken is String && cachedToken.isNotEmpty) {
      await _secureStorage.write(StorageKeys.token, cachedToken);
      return cachedToken;
    }

    return null;
  }

  void _performNavigation(bool isAuthorized) {
    if (!mounted || _isNavigating) return;
    _isNavigating = true;
    _failsafeTimer?.cancel();

    if (isAuthorized) {
      Get.offAllNamed(RouteNames.home);
    } else {
      Get.offAllNamed(RouteNames.login);
    }
  }

  @override
  void dispose() {
    _isNavigating = true;
    _failsafeTimer?.cancel();
    _mainAnimController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ── Dual Radial Gradient Pulse Background Accents ───────────────────
            Positioned(
              top: -80,
              right: -80,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(
                            alpha: 0.08 + _pulseController.value * 0.05,
                          ),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.brandGreen.withValues(
                            alpha: 0.06 + (1 - _pulseController.value) * 0.04,
                          ),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Main Content & Rapido Yellow Branding ────────────────────
            Center(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Corporate Emblem Container ──────────────────────────
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Pulse Ambient Glow Ring (Yellow Rapido Accent)
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final double pulseScale =
                                  1.0 + (_pulseController.value * 0.08);
                              return Transform.scale(
                                scale: pulseScale,
                                child: Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          // Outer Ring Accent
                          Container(
                            width: 114,
                            height: 114,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.35),
                                width: 1.5,
                              ),
                            ),
                          ),

                          // App Icon Card Container
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.28),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.lightGrey,
                                width: 1.2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Image.asset(
                                  'assets/icon/app_icon.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                    Icons.local_taxi_rounded,
                                    size: 52,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // ── Brand Title with Rapido Yellow Badge ──────────────────
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Indica',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: AppColors.darkSlate,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.40),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Text(
                              'B',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w900,
                                color: AppColors.darkSlate,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ── Accent Line Divider ───────────────────────────
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.primary.withValues(alpha: 0.8),
                                ],
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.square_rounded,
                              size: 6,
                              color: AppColors.primary,
                            ),
                          ),
                          Container(
                            width: 36,
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // ── Corporate Tagline ──────────────────────────────────
                      const Text(
                        'Your Trusted Ride, Every Time',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.subtleSlate,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom Loading Progress & Footer ─────────────────
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Text(
                    'Initializing app...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.subtleSlate,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sleek Progress Indicator in Rapido Yellow
                  SizedBox(
                    width: 140,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: const LinearProgressIndicator(
                        minHeight: 3.5,
                        backgroundColor: AppColors.lightGrey,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Corporate Footer Branding
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'MADE WITH ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.subtleSlate,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        '❤️',
                        style: TextStyle(fontSize: 11),
                      ),
                      Text(
                        ' IN INDIA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
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
      ),
    );
  }
}
