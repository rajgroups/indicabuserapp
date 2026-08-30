import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/Colors.dart';
import 'loader.dart';

/// 🟡 Theme-Styled Global Loading Overlay / Dialog Controller
class AppLoadingOverlay {
  static bool _isShowing = false;

  /// Show full-screen loading dialog with theme styling
  static void show({
    BuildContext? context,
    String message = 'Loading...',
    bool barrierDismissible = false,
  }) {
    if (_isShowing) return;
    _isShowing = true;

    final dialogContent = Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.20),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppColors.borderSoft,
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppPulsingLogoLoader(
                size: 64,
                primaryColor: AppColors.primary,
              ),
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkSlate,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 12),
              const AppLinearLoader(
                width: 120,
                height: 3.5,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );

    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (_) => PopScope(
          canPop: barrierDismissible,
          child: dialogContent,
        ),
      ).then((_) {
        _isShowing = false;
      });
    } else {
      Get.dialog(
        PopScope(
          canPop: barrierDismissible,
          child: dialogContent,
        ),
        barrierDismissible: barrierDismissible,
        barrierColor: Colors.black.withValues(alpha: 0.45),
      ).then((_) {
        _isShowing = false;
      });
    }
  }

  /// Dismiss loading dialog
  static void hide({BuildContext? context}) {
    if (!_isShowing) return;
    _isShowing = false;

    if (context != null && Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    } else if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }
}
