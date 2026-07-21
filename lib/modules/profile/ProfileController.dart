import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/models/UserProfileModel.dart';
import 'ProfileService.dart';

class ProfileController extends GetxController {
  ProfileController();

  final ProfileService _profileService = ProfileService();

  final Rxn<UserProfileModel> userProfile = Rxn<UserProfileModel>();
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;

  // Text Editing Controllers for Edit Profile Form
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController mobileController;
  late TextEditingController addressController;
  late TextEditingController emergencyNameController;
  late TextEditingController emergencyMobileController;
  final RxString selectedGender = 'male'.obs;

  @override
  void onInit() {
    super.onInit();
    nameController = TextEditingController();
    emailController = TextEditingController();
    mobileController = TextEditingController();
    addressController = TextEditingController();
    emergencyNameController = TextEditingController();
    emergencyMobileController = TextEditingController();

    fetchUserProfile();
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    addressController.dispose();
    emergencyNameController.dispose();
    emergencyMobileController.dispose();
    super.onClose();
  }

  Future<void> fetchUserProfile({bool silent = false}) async {
    if (!silent) {
      isLoading.value = true;
    }

    try {
      final profile = await _profileService.fetchProfile();
      userProfile.value = profile;

      // Populate text fields
      nameController.text = profile.name ?? '';
      emailController.text = profile.email ?? '';
      mobileController.text = profile.mobile ?? '';
      addressController.text = profile.address ?? '';
      emergencyNameController.text = profile.emergencyContactName ?? '';
      emergencyMobileController.text = profile.emergencyContactMobile ?? '';
      if (profile.gender != null && profile.gender!.isNotEmpty) {
        selectedGender.value = profile.gender!.toLowerCase();
      }
    } catch (e) {
      debugPrint('ProfileController.fetchUserProfile error: $e');
    } finally {
      if (!silent) {
        isLoading.value = false;
      }
    }
  }

  Future<bool> saveProfile() async {
    isUpdating.value = true;

    try {
      final updateData = {
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'gender': selectedGender.value,
        'address': addressController.text.trim(),
        'emergency_contact_name': emergencyNameController.text.trim(),
        'emergency_contact_mobile': emergencyMobileController.text.trim(),
      };

      final updatedProfile = await _profileService.updateProfile(updateData);
      userProfile.value = updatedProfile;

      Get.snackbar(
        'Success',
        'Profile updated successfully.',
        backgroundColor: AppColors.surface,
        colorText: AppColors.textPrimary,
      );

      return true;
    } catch (e) {
      debugPrint('ProfileController.saveProfile error: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile: $e',
        backgroundColor: AppColors.surface,
        colorText: Colors.red,
      );
      return false;
    } finally {
      isUpdating.value = false;
    }
  }
}
