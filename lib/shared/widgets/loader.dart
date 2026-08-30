import 'package:flutter/material.dart';
import '../../core/constants/Colors.dart';

/// 🟡 Standard App Circular Progress Loader
class AppLoader extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? message;

  const AppLoader({
    super.key,
    this.size = 36.0,
    this.color,
    this.strokeWidth = 3.5,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;

    final spinner = SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(activeColor),
      ),
    );

    if (message == null || message!.isEmpty) {
      return Center(child: spinner);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          spinner,
          const SizedBox(height: 14),
          Text(
            message!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 🟡 Pulsing Emblem Logo Loader (Matching Driver App Aesthetics)
class AppPulsingLogoLoader extends StatefulWidget {
  final double size;
  final String? message;
  final Color primaryColor;

  const AppPulsingLogoLoader({
    super.key,
    this.size = 84.0,
    this.message,
    this.primaryColor = AppColors.primary,
  });

  @override
  State<AppPulsingLogoLoader> createState() => _AppPulsingLogoLoaderState();
}

class _AppPulsingLogoLoaderState extends State<AppPulsingLogoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double outerSize = widget.size * 1.35;
    final double midSize = widget.size * 1.18;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer Ambient Pulse Ring
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final double scale = 1.0 + (_pulseController.value * 0.10);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: outerSize,
                    height: outerSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.primaryColor.withValues(
                        alpha: 0.12 + (_pulseController.value * 0.08),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Mid Accent Ring Border
            Container(
              width: midSize,
              height: midSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.primaryColor.withValues(alpha: 0.35),
                  width: 1.8,
                ),
              ),
            ),

            // Center Logo Container Card
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.30),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 1,
                  ),
                ],
                border: Border.all(
                  color: AppColors.lightGrey,
                  width: 1.2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.local_taxi_rounded,
                      size: widget.size * 0.5,
                      color: widget.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.message != null && widget.message!.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            widget.message!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.darkSlate,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ],
    );
  }
}

/// 🟡 Sleek Horizontal Linear Loader
class AppLinearLoader extends StatelessWidget {
  final double width;
  final double height;
  final Color? color;
  final Color? backgroundColor;

  const AppLinearLoader({
    super.key,
    this.width = 140.0,
    this.height = 4.0,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          minHeight: height,
          backgroundColor: backgroundColor ?? AppColors.lightGrey,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// 🟡 Button Loading Spinner
class AppButtonLoader extends StatelessWidget {
  final Color color;
  final double size;

  const AppButtonLoader({
    super.key,
    this.color = AppColors.darkSlate,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
