import 'package:indicab/core/models/UserProfileModel.dart';
import 'package:indicab/core/network/client.dart';
import 'ProfileRepository.dart';

class ProfileService {
  ProfileService({ProfileRepository? repository})
      : _repository = repository ?? ProfileRepository(ApiClient());

  final ProfileRepository _repository;

  Future<UserProfileModel> fetchProfile() async {
    return await _repository.getProfile();
  }

  Future<UserProfileModel> updateProfile(Map<String, dynamic> data) async {
    return await _repository.updateProfile(data);
  }
}
