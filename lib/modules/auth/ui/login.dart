import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/constants/Strings.dart';
import 'package:indicab/layout/auth_layout.dart';

import '../../../shared/widgets/social_button.dart';
import '../AuthController.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Logo Section
          Center(
            child: Column(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5B800), Color(0xFFE6A700)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.local_taxi_rounded,
                      size: 44,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  AppStrings.appName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: AppColors.textPrimary,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.title_tag,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      fontFamily: 'SF Pro Display',
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.sub_tag,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      fontFamily: 'SF Pro Text',
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 48),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.borderSoft, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.mobile_number,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                /// Phone Input Card with subtle glassmorphism
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),

                  child: Row(
                    children: [
                      /// Mobile Number Field
                      Expanded(
                        child: TextField(
                          controller: controller.mobileController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: AppStrings.mobile_number,
                            hintStyle: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                            prefixIcon: const Icon(
                              Icons.phone_android_rounded,
                              color: AppColors.textSecondary,
                              size: 24,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 18,
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                /// Send OTP Button (Gradient + Shadow)
                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.sendOtp,
                      style:
                          ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            disabledBackgroundColor: AppColors.border,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40),
                            ),
                          ).copyWith(
                            backgroundColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.disabled)) {
                                return AppColors.border;
                              }
                              return Colors.transparent;
                            }),
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
                                  end: Alignment.centerRight,
                                ),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: controller.isLoading.value
                              ? null
                              : [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF5B800,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20,
                          ),
                          alignment: Alignment.center,
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: AppColors.textPrimary,
                                  ),
                                )
                              : const Text(
                                  AppStrings.contin,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                /// OR Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: AppColors.border, thickness: 0.8),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        AppStrings.or,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: AppColors.border, thickness: 0.8),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                /// Social Login Buttons
                SocialButton(
                  icon: Icons.g_mobiledata_rounded,
                  label: AppStrings.sign_google,
                  onTap: controller.loginWithGoogle,
                  isGoogle: true,
                ),
                const SizedBox(height: 16),
                SocialButton(
                  icon: Icons.apple_rounded,
                  label: AppStrings.sign_apple,
                  onTap: () {
                    // Apple login logic
                  },
                  isGoogle: false,
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
          const SizedBox(height: 24),

          /// Subtle Background Illustration (Taxi silhouette)
          // Align(
          //   alignment: Alignment.center,
          //   child: Opacity(
          //     opacity: 0.08,
          //     child: Icon(
          //       Icons.route_rounded,
          //       size: 120,
          //       color: Colors.white,
          //     ),
          //   ),
          // ),

          /// Legal Text
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text.rich(
                TextSpan(
                  text: AppStrings.agree_terms,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                  children: [
                    TextSpan(
                      text: AppStrings.terms,
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: AppStrings.and_sign,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    TextSpan(
                      text: AppStrings.privacy,
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w600,
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
    );
  }
}
