import 'package:indicab/core/network/endpoints.dart';

import '../../core/network/client.dart';
import 'models/login_request.dart';
import 'models/login_response.dart';
import 'models/otp_request.dart';

class AuthRepository {
  final ApiClient _client = ApiClient();

  Future<dynamic> sendOtp(LoginRequest request) async {
    return await _client.post(
       ApiEndpoints.sendOtp,
      data: request.toJson(),
    );
  }

  Future<LoginResponse> verifyOtp(
    OtpRequest request,
  ) async {

    final response = await _client.post(
      ApiEndpoints.verifyOtp,
      data: request.toJson(),
    );

    return LoginResponse.fromJson(response.data);
  }

  Future<dynamic> socialLogin(String provider, String token) async {
    return await _client.post(
      '/auth/social-login',
      data: {
        "provider": provider,
        "token": token,
      },
    );
  }

  Future<dynamic> logout() async {
    return await _client.post(ApiEndpoints.logout);
  }
}