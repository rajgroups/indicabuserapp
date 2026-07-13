import 'package:get/get.dart';
import 'package:indicab/core/constants/Keys.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/services/SecureStorageService.dart';
import 'package:get_storage/get_storage.dart';
import 'package:indicab/core/services/SocketService.dart';

import 'AuthRepository.dart';
import 'models/login_request.dart';
import 'models/login_response.dart';
import 'models/otp_request.dart';

class AuthService {
  final AuthRepository _repo = AuthRepository();
  final SecureStorageService _storage = SecureStorageService();
  final ApiClient _client = ApiClient();

  Future sendOtp(LoginRequest request) async {
    return await _repo.sendOtp(request);
  }

  Future<LoginResponse> verifyOtp(OtpRequest request) async {
    final response = await _repo.verifyOtp(request);

    final authToken = response.data.token;

    /// SAVE TOKEN
    await _storage.write(StorageKeys.token, authToken);
    await GetStorage().write(StorageKeys.token, authToken);

    /// SET TOKEN TO DIO
    _client.setTokens(authToken);

    // Keep the token ready for active-ride or booking-driven socket connection.
    Get.find<SocketService>().setToken(authToken);

    return response;
  }

  Future socialLogin(String provider, String token) async {
    final response = await _repo.socialLogin(provider, token);
    final data = response.data;
    final authToken = data is Map<String, dynamic> ? data['token'] : null;

    if (authToken is String && authToken.isNotEmpty) {
      await _storage.write(StorageKeys.token, authToken);
      await GetStorage().write(StorageKeys.token, authToken);
      _client.setTokens(authToken);
      Get.find<SocketService>().setToken(authToken);
    }

    return response;
  }
}
