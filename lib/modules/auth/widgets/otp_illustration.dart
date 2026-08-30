import 'package:flutter/material.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/constants/Strings.dart';

/// Top hero card for OTP screen integrating Brand Icon, Brand Name, Title, and Phone confirmation inside top banner.
class OtpIllustration extends StatelessWidget {
  final String maskedMobile;
  final VoidCallback onEditMobile;

  const OtpIllustration({
    super.key,
    required this.maskedMobile,
    required this.onEditMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF5B800).withValues(alpha: 0.12),
            blurRadius: 22,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            /// Vector Art Background Canvas
            Positioned.fill(
              child: CustomPaint(
                painter: _OtpTopHeroVectorPainter(),
              ),
            ),

            /// Foreground Content (Brand Name, Icon, Verification Title & Phone)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Top Row: Brand Icon + Brand Name & Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primary, AppColors.primaryDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/icon/app_icon.png',
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.local_taxi_rounded,
                                  size: 22,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            AppStrings.appName,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppColors.textPrimary,
                              fontFamily: 'SF Pro Text',
                            ),
                          ),
                        ],
                      ),

                      /// Secure OTP Status Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFF5B800).withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, size: 13, color: Color(0xFFB88400)),
                            SizedBox(width: 4),
                            Text(
                              "Secure OTP",
                              style: TextStyle(
                                color: Color(0xFFB88400),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// Title Inside Top Hero
                  const Text(
                    "Verify 4-Digit Code",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      fontFamily: 'SF Pro Display',
                      height: 1.2,
                      letterSpacing: -0.3,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// Masked Phone Confirmation Subtitle with Responsive Gesture Edit Button
                  Row(
                    children: [
                      Text(
                        "Code sent to $maskedMobile",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                      const SizedBox(width: 8),

                      /// Edit Mobile Button with Crisp Touch Gesture Recognition
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onEditMobile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFFF5B800).withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_rounded,
                                size: 11,
                                color: AppColors.primaryDark,
                              ),
                              SizedBox(width: 3),
                              Text(
                                "Edit",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  /// Feature Chips inside Top Hero
                  Row(
                    children: [
                      _OtpHeroBadgeChip(
                        icon: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFFB88400),
                        text: "Encrypted OTP",
                      ),
                      const SizedBox(width: 8),
                      _OtpHeroBadgeChip(
                        icon: Icons.sms_outlined,
                        iconColor: const Color(0xFF1976D2),
                        text: "Instant SMS",
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

class _OtpHeroBadgeChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _OtpHeroBadgeChip({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

const _kNavy  = Color(0xFF1A1A2E);
const _kGreen = Color(0xFF00C853);

/// Custom Vector Painter for top background graphics of OTP card
class _OtpTopHeroVectorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Ambient radial glow - subtle navy tint
    final bgGlowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _kNavy.withValues(alpha: 0.04),
          const Color(0xFFFFFFFF),
        ],
        center: Alignment.topRight,
        radius: 1.1,
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgGlowPaint);

    final shieldCenterX = width * 0.85;
    final shieldCenterY = height * 0.55;

    // Signal rings - green pulse
    final pulseRing1 = Paint()
      ..color = _kGreen.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(shieldCenterX, shieldCenterY), 38, pulseRing1);

    final pulseRing2 = Paint()
      ..color = _kGreen.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(Offset(shieldCenterX, shieldCenterY), 54, pulseRing2);

    // Shield Graphic - navy with green glow
    final shieldPath = Path();
    final sTop = shieldCenterY - 18;
    final sWidth = 32.0;
    final sHeight = 38.0;

    shieldPath.moveTo(shieldCenterX, sTop);
    shieldPath.cubicTo(
      shieldCenterX + sWidth * 0.5, sTop,
      shieldCenterX + sWidth * 0.5, sTop + sHeight * 0.4,
      shieldCenterX + sWidth * 0.5, sTop + sHeight * 0.55,
    );
    shieldPath.cubicTo(
      shieldCenterX + sWidth * 0.5, sTop + sHeight * 0.85,
      shieldCenterX, sTop + sHeight,
      shieldCenterX, sTop + sHeight,
    );
    shieldPath.cubicTo(
      shieldCenterX, sTop + sHeight,
      shieldCenterX - sWidth * 0.5, sTop + sHeight * 0.85,
      shieldCenterX - sWidth * 0.5, sTop + sHeight * 0.55,
    );
    shieldPath.cubicTo(
      shieldCenterX - sWidth * 0.5, sTop + sHeight * 0.4,
      shieldCenterX - sWidth * 0.5, sTop,
      shieldCenterX, sTop,
    );
    shieldPath.close();

    final shieldGradientPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1A1A2E), Color(0xFF2D2D4E)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(
          shieldCenterX - sWidth / 2, sTop, sWidth, sHeight));

    canvas.drawPath(shieldPath, shieldGradientPaint);

    // Green check on shield
    final checkPaint = Paint()
      ..color = _kGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final checkPath = Path();
    checkPath.moveTo(shieldCenterX - 6, shieldCenterY + 1);
    checkPath.lineTo(shieldCenterX - 1, shieldCenterY + 6);
    checkPath.lineTo(shieldCenterX + 8, shieldCenterY - 4);
    canvas.drawPath(checkPath, checkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
