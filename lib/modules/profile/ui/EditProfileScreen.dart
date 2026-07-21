import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Colors.dart';
import '../ProfileController.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: Get.back,
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (controller.nameController.text.isNotEmpty
                                ? controller.nameController.text[0]
                                : 'U')
                            .toUpperCase(),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Full Name
              _InputField(
                label: 'Full Name',
                controller: controller.nameController,
                icon: Icons.person_outline_rounded,
                hint: 'Enter full name',
              ),
              const SizedBox(height: 20),

              // Email Address
              _InputField(
                label: 'Email Address',
                controller: controller.emailController,
                icon: Icons.email_outlined,
                hint: 'Enter email address',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Mobile Number (Read-Only)
              _InputField(
                label: 'Mobile Number',
                controller: controller.mobileController,
                icon: Icons.phone_android_rounded,
                hint: 'Mobile number',
                readOnly: true,
              ),
              const SizedBox(height: 20),

              // Gender Selector
              const Text(
                'Gender',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _GenderTile(
                    label: 'Male',
                    value: 'male',
                    groupValue: controller.selectedGender.value,
                    onChanged: (val) => controller.selectedGender.value = val!,
                  ),
                  const SizedBox(width: 12),
                  _GenderTile(
                    label: 'Female',
                    value: 'female',
                    groupValue: controller.selectedGender.value,
                    onChanged: (val) => controller.selectedGender.value = val!,
                  ),
                  const SizedBox(width: 12),
                  _GenderTile(
                    label: 'Other',
                    value: 'other',
                    groupValue: controller.selectedGender.value,
                    onChanged: (val) => controller.selectedGender.value = val!,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Home Address
              _InputField(
                label: 'Address',
                controller: controller.addressController,
                icon: Icons.location_on_outlined,
                hint: 'Enter address',
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Emergency Contact Section
              const Divider(color: AppColors.borderSoft),
              const SizedBox(height: 16),
              const Text(
                'Emergency Contact',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 14),

              _InputField(
                label: 'Contact Person Name',
                controller: controller.emergencyNameController,
                icon: Icons.person_search_rounded,
                hint: 'Emergency contact name',
              ),
              const SizedBox(height: 16),

              _InputField(
                label: 'Contact Mobile Number',
                controller: controller.emergencyMobileController,
                icon: Icons.phone_rounded,
                hint: 'Emergency contact mobile',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 36),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isUpdating.value
                      ? null
                      : () async {
                          final success = await controller.saveProfile();
                          if (success) {
                            Get.back();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: controller.isUpdating.value
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation(AppColors.textPrimary),
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.hint,
    this.readOnly = false,
    this.keyboardType,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final bool readOnly;
  final TextInputType? keyboardType;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primaryDark),
            filled: true,
            fillColor: readOnly ? AppColors.borderSoft : AppColors.inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _GenderTile extends StatelessWidget {
  const _GenderTile({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final String value;
  final String groupValue;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return Expanded(
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.inputFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primaryDark : AppColors.borderSoft,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
