import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:get/get.dart';
import 'package:indicab/core/routes/names.dart';

class Helpers {

  static void success(String message, String? route, {dynamic arguments}) {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.success,
      text: message,
      onConfirmBtnTap: () async {

        /// CLOSE ALERT
        Get.back();

        /// WAIT SMALL DELAY
        await Future.delayed(
          const Duration(milliseconds: 200),
        );

        /// NAVIGATE
        if (route != null) {
          Get.offAllNamed(route, arguments: arguments);
        }
      },
    );
  }

  static bool _isSessionExpiredAlertShowing = false;

  static void error(String message) {
    if (message.contains("Unauthenticated") || message.contains("Session expired")) {
      if (_isSessionExpiredAlertShowing || Get.currentRoute == RouteNames.login) {
        return;
      }
      _isSessionExpiredAlertShowing = true;
      QuickAlert.show(
        context: Get.context!,
        type: QuickAlertType.error,
        text: "Session expired. Please log in again.",
        onConfirmBtnTap: () {
          _isSessionExpiredAlertShowing = false;
          Get.back();
        },
      );
      return;
    }

    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.error,
      text: message,
    );
  }

  static void loading() {
    QuickAlert.show(
      context: Get.context!,
      type: QuickAlertType.loading,
      text: "Please wait...",
      barrierDismissible: false,
    );
  }

  static void showToast(String message) {
    Get.rawSnackbar(
      messageText: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
      borderRadius: 50,
      margin: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static void showComingSoon(String featureTitle, {String? customText}) {
    final context = Get.context;
    if (context == null) return;

    QuickAlert.show(
      context: context,
      type: QuickAlertType.info,
      title: '$featureTitle',
      text: customText ?? 'The $featureTitle feature is coming soon in our upcoming update!',
      confirmBtnText: 'Got it!',
      confirmBtnColor: const Color(0xFF00C853),
    );
  }

  static void close() {
    Get.back();
  }
}
