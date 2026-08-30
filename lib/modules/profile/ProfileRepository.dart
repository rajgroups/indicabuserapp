import 'package:indicab/core/models/UserProfileModel.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/network/endpoints.dart';

class ProfileRepository {
  ProfileRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<UserProfileModel> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.profile);

    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        return UserProfileModel.fromJson(data);
      }
    }

    throw Exception('Failed to parse user profile response.');
  }

  Future<UserProfileModel> updateProfile(Map<String, dynamic> updateData) async {
    final response = await _apiClient.put(
      ApiEndpoints.profile,
      data: updateData,
    );

    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        return UserProfileModel.fromJson(data);
      }
    }

    throw Exception('Failed to update profile.');
  }

  Future<String> requestDeleteOtp() async {
    final response = await _apiClient.post('/delete-account/request-otp');
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic> && data.containsKey('otp')) {
        return data['otp'].toString();
      }
    }
    return '';
  }

  Future<bool> confirmDeleteAccount(String otp) async {
    final response = await _apiClient.post(
      '/delete-account/confirm',
      data: {'otp': otp},
    );
    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return payload['success'] == true;
    }
    return false;
  }
}
