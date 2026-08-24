import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/constants/Strings.dart';
import 'package:indicab/layout/app.dart';
import 'package:indicab/modules/auth/widgets/login_illustration.dart';

import '../../../shared/widgets/social_button.dart';
import '../AuthController.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  static const List<Map<String, String>> countryCodes = [
    {"code": "+91", "flag": "🇮🇳", "name": "India"},
    {"code": "+1", "flag": "🇺🇸", "name": "USA"},
    {"code": "+44", "flag": "🇬🇧", "name": "UK"},
    {"code": "+971", "flag": "🇦🇪", "name": "UAE"},
  ];

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      backgroundColor: AppColors.authBackground,
      resizeToAvoidBottomInset: true,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Top Hero Banner Card
                        const LoginIllustration(),

                        const SizedBox(height: 16),

                        /// Main Form Card (Stretches to fill full available vertical height)
                        Expanded(
                          child: CustomPaint(
                            foregroundPainter: const _TraditionalArchPainter(
                              color: Color(0xFF1A1A2E),
                            ),
                            child: Container(
                              width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.borderSoft,
                                width: 1.2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0C000000),
                                  blurRadius: 20,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          AppStrings.mobile_number,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                            fontFamily: 'SF Pro Text',
                                          ),
                                        ),

                                        /// Live Digit Validation Counter
                                        ValueListenableBuilder<TextEditingValue>(
                                          valueListenable:
                                              controller.mobileController,
                                          builder: (context, value, child) {
                                            final length = value.text.length;
                                            final isValid = length == 10;
                                            return Row(
                                              children: [
                                                if (isValid)
                                                  Container(
                                                    margin: const EdgeInsets
                                                        .only(right: 4),
                                                    child: const Icon(
                                                      Icons.check_circle_rounded,
                                                      color: Color(0xFF00C853),
                                                      size: 14,
                                                    ),
                                                  ),
                                                Text(
                                                  "$length/10",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isValid
                                                        ? const Color(0xFF00C853)
                                                        : AppColors.textMuted,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    /// Phone Input Container
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.inputFill,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: AppColors.border,
                                          width: 1,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        children: [
                                          /// Country Code Picker Dropdown
                                          Obx(
                                            () => Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: AppColors.borderSoft,
                                                  width: 1,
                                                ),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: controller
                                                      .selectedCountryCode.value,
                                                  isDense: true,
                                                  icon: const Icon(
                                                    Icons
                                                        .keyboard_arrow_down_rounded,
                                                    size: 16,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                  items: countryCodes.map((item) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: item["code"],
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            item["flag"]!,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 4,
                                                          ),
                                                          Text(
                                                            item["code"]!,
                                                            style:
                                                                const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight.w700,
                                                              color: AppColors
                                                                  .textPrimary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                  onChanged: (val) {
                                                    if (val != null) {
                                                      controller
                                                          .selectedCountryCode
                                                          .value = val;
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),

                                          const SizedBox(width: 10),

                                          /// Mobile Field Input
                                          Expanded(
                                            child: TextField(
                                              controller:
                                                  controller.mobileController,
                                              keyboardType: TextInputType.phone,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.0,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: "Enter 10-digit mobile",
                                                hintStyle: TextStyle(
                                                  fontSize: 14,
                                                  color: AppColors.textMuted
                                                      .withValues(alpha: 0.7),
                                                  fontWeight: FontWeight.w400,
                                                  letterSpacing: 0,
                                                ),
                                                border: InputBorder.none,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 12,
                                                ),
                                              ),
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                                LengthLimitingTextInputFormatter(
                                                  10,
                                                ),
                                              ],
                                            ),
                                          ),

                                          /// Clear Icon
                                          ValueListenableBuilder<
                                            TextEditingValue
                                          >(
                                            valueListenable:
                                                controller.mobileController,
                                            builder: (context, value, child) {
                                              if (value.text.isEmpty) {
                                                return const SizedBox.shrink();
                                              }
                                              return IconButton(
                                                icon: const Icon(
                                                  Icons.cancel_rounded,
                                                  color: AppColors.textMuted,
                                                  size: 18,
                                                ),
                                                onPressed: () => controller
                                                    .mobileController
                                                    .clear(),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 18),

                                    /// Gradient Action Button
                                    Obx(
                                      () => SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: ElevatedButton(
                                          onPressed: controller.isLoading.value
                                              ? null
                                              : controller.sendOtp,
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            elevation: 0,
                                            backgroundColor: Colors.transparent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                          ),
                                          child: Ink(
                                            decoration: BoxDecoration(
                                              gradient: controller.isLoading.value
                                                  ? null
                                                  : const LinearGradient(
                                                      colors: [
                                                        Color(0xFFF5B800),
                                                        Color(0xFFE6A700),
                                                      ],
                                                      begin: Alignment.centerLeft,
                                                      end:
                                                          Alignment.centerRight,
                                                    ),
                                              color: controller.isLoading.value
                                                  ? AppColors.border
                                                  : null,
                                              borderRadius: BorderRadius.circular(
                                                24,
                                              ),
                                              boxShadow: controller
                                                      .isLoading.value
                                                  ? null
                                                  : [
                                                      BoxShadow(
                                                        color: const Color(
                                                          0xFFF5B800,
                                                        ).withValues(alpha: 0.35),
                                                        blurRadius: 12,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ],
                                            ),
                                            child: Container(
                                              alignment: Alignment.center,
                                              child: controller.isLoading.value
                                                  ? const SizedBox(
                                                      height: 20,
                                                      width: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2.2,
                                                            color:
                                                                AppColors.black,
                                                          ),
                                                    )
                                                  : const Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          AppStrings.contin,
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: Colors.black,
                                                            letterSpacing: 0.3,
                                                          ),
                                                        ),
                                                        SizedBox(width: 6),
                                                        Icon(
                                                          Icons
                                                              .arrow_forward_rounded,
                                                          color: Colors.black,
                                                          size: 18,
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                Column(
                                  children: [
                                    const SizedBox(height: 16),

                                    /// OR Divider
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.border,
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            AppStrings.or,
                                            style: TextStyle(
                                              color: AppColors.textMuted,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: AppColors.border,
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 16),

                                    /// Social Login Buttons
                                    SocialButton(
                                      icon: Icons.g_mobiledata_rounded,
                                      label: AppStrings.sign_google,
                                      onTap: controller.loginWithGoogle,
                                      isGoogle: true,
                                    ),
                                    const SizedBox(height: 10),
                                    SocialButton(
                                      icon: Icons.apple_rounded,
                                      label: AppStrings.sign_apple,
                                      onTap: () {
                                        // Apple sign in action
                                      },
                                      isGoogle: false,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                        const SizedBox(height: 16),

                        /// Terms & Privacy Footer Links
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text.rich(
                              TextSpan(
                                text: "${AppStrings.agree_terms} ",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  height: 1.35,
                                ),
                                children: [
                                  TextSpan(
                                    text: AppStrings.terms,
                                    style: TextStyle(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: " ${AppStrings.and_sign} ",
                                    style: TextStyle(color: AppColors.textMuted),
                                  ),
                                  TextSpan(
                                    text: AppStrings.privacy,
                                    style: TextStyle(
                                      color: AppColors.primaryDark,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
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
