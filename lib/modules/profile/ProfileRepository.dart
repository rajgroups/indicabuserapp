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
}
