import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:indicab/modules/auth/models/otp_request.dart';

import '../../core/routes/names.dart';
import '../../core/utils/Helpers.dart';
import '../../core/utils/Validators.dart';
import 'AuthService.dart';
import 'models/login_request.dart';

class AuthController extends GetxController {
  final AuthService _service = AuthService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  final mobileController = TextEditingController();
  final otpController = TextEditingController();

  final RxBool isLoading = false.obs;
  RxString selectedCountryCode = "+91".obs;

  Future<void> sendOtp() async {
    final mobile = mobileController.text.trim();
    final mobileError = Validators.validateMobile(mobile);

    if (mobileError != null) {
      Helpers.error(mobileError);
      return;
    }

    try {
      isLoading.value = true;
      Helpers.loading();

      var response = await _service.sendOtp(LoginRequest(mobile: mobile));
      print('Send OTP API Response:$response');

      Helpers.close(); // Close the loading dialog
      Helpers.success("OTP sent successfully", RouteNames.otp);
      Get.toNamed(RouteNames.otp);
    } catch (e) {
      Helpers.close(); // Close the loading dialog
      print('Send OTP Error: $e'); // Print the error to the terminal
      Helpers.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    final otpError = Validators.validateOtp(otp);

    if (otpError != null) {
      Helpers.error(otpError);

      return;
    }

    try {
      isLoading.value = true;

      Helpers.loading();

      final response = await _service.verifyOtp(
        OtpRequest(mobile: mobileController.text.trim(), otp: otp),
      );

      Helpers.close();

      if (response.status == 'success') {
        Helpers.success(response.message, RouteNames.home);
      }
    } catch (e) {
      Helpers.close();

      Helpers.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      isLoading.value = true;
      Helpers.loading();

      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();

      if (account == null) {
        Helpers.close();
        return;
      }

      final auth = await account.authentication;
      final token = auth.idToken ?? auth.accessToken;

      if (token == null || token.isEmpty) {
        throw Exception("Google authentication token not available");
      }

      await _service.socialLogin('google', token);

      Helpers.close();
      Helpers.success("Login Successful", RouteNames.home);
    } catch (e) {
      Helpers.close();
      Helpers.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      isLoading.value = true;
      Helpers.loading();
      await _service.logout();
      Helpers.close();
      Get.offAllNamed(RouteNames.login);
    } catch (e) {
      Helpers.close();
      Get.offAllNamed(RouteNames.login);
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    mobileController.dispose();
    otpController.dispose();
    super.onClose();
  }
}
