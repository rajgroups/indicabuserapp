import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/constants/Strings.dart';
import 'package:indicab/core/utils/Helpers.dart';
import 'package:indicab/layout/app.dart';
import 'package:indicab/modules/auth/widgets/login_illustration.dart';

import '../../../shared/widgets/social_button.dart';
import '../AuthController.dart';

// ─── Rapido Driver Palette & Fonts ───────────────────────────────────────────
const _kNavy  = Color(0xFF1A1A2E);
const _kGreen = Color(0xFF00C853);
const _kBg    = Color(0xFFF5F6FA);

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
      backgroundColor: _kBg,
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

                        /// Main Form Card (Matching Driver App LoginView)
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFEEEFF3),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _kNavy.withValues(alpha: 0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
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
                                            color: _kNavy,
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
                                                      color: _kGreen,
                                                      size: 14,
                                                    ),
                                                  ),
                                                Text(
                                                  "$length/10",
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: isValid
                                                        ? _kGreen
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
                                        color: const Color(0xFFF5F6FA),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFEEEFF3),
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
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(0xFFEEEFF3),
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
                                                              color: _kNavy,
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
                                                color: _kNavy,
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

                                    /// Gradient Action Button (Matching Driver App LoginView)
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
                                                        _kNavy,
                                                        Color(0xFF2D2D4E),
                                                      ],
                                                      begin: Alignment.centerLeft,
                                                      end: Alignment.centerRight,
                                                    ),
                                              color: controller.isLoading.value
                                                  ? const Color(0xFFEEEFF3)
                                                  : null,
                                              borderRadius: BorderRadius.circular(
                                                24,
                                              ),
                                              boxShadow: controller
                                                      .isLoading.value
                                                  ? null
                                                  : [
                                                      BoxShadow(
                                                        color: _kNavy
                                                            .withValues(alpha: 0.30),
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
                                                            color: _kNavy,
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
                                                            color: Colors.white,
                                                            letterSpacing: 0.3,
                                                          ),
                                                        ),
                                                        SizedBox(width: 6),
                                                        Icon(
                                                          Icons
                                                              .arrow_forward_rounded,
                                                          color: _kGreen,
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
                                        const Expanded(
                                          child: Divider(
                                            color: Color(0xFFEEEFF3),
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: Text(
                                            AppStrings.or,
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          child: Divider(
                                            color: Color(0xFFEEEFF3),
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
                                      onTap: () => Helpers.showComingSoon('Google Sign In'),
                                      isGoogle: true,
                                    ),
                                    const SizedBox(height: 10),
                                    SocialButton(
                                      icon: Icons.apple_rounded,
                                      label: AppStrings.sign_apple,
                                      onTap: () => Helpers.showComingSoon('Apple Sign In'),
                                      isGoogle: false,
                                    ),
                                  ],
                                ),
                              ],
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
                                children: const [
                                  TextSpan(
                                    text: AppStrings.terms,
                                    style: TextStyle(
                                      color: _kNavy,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  TextSpan(
                                    text: " ${AppStrings.and_sign} ",
                                    style: TextStyle(color: AppColors.textMuted),
                                  ),
                                  TextSpan(
                                    text: AppStrings.privacy,
                                    style: TextStyle(
                                      color: _kNavy,
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
