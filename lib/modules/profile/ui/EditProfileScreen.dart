import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../ProfileController.dart';
import 'package:indicab/core/utils/Helpers.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kNavy    = Color(0xFF1A1A2E);
const _kGreen   = Color(0xFF00C853);
const _kBg      = Color(0xFFF5F6FA);
const _kMuted   = Color(0xFFB0B3C1);
const _kBorder  = Color(0xFFEEEFF3);

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.find<ProfileController>();
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Rapido-style top bar ─────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                _CircleBtn(icon: Icons.arrow_back_rounded, onTap: Get.back),
                const SizedBox(width: 12),
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kNavy,
                  ),
                ),
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: _kNavy),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Avatar ─────────────────────────────────────
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: _kNavy,
                              shape: BoxShape.circle,
                              border: Border.all(color: _kGreen, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: _kNavy.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (controller.nameController.text.isNotEmpty
                                      ? controller.nameController.text[0]
                                      : 'U')
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          // Camera badge
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: _kGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Personal info section ──────────────────────
                    _SectionLabel(label: 'Personal Info'),
                    const SizedBox(height: 12),
                    _InputField(
                      label: 'Full Name',
                      controller: controller.nameController,
                      icon: Icons.person_outline_rounded,
                      hint: 'Enter full name',
                    ),
                    const SizedBox(height: 14),
                    _InputField(
                      label: 'Email Address',
                      controller: controller.emailController,
                      icon: Icons.email_outlined,
                      hint: 'Enter email address',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _InputField(
                      label: 'Mobile Number',
                      controller: controller.mobileController,
                      icon: Icons.phone_android_rounded,
                      hint: 'Mobile number',
                      readOnly: true,
                    ),
                    const SizedBox(height: 14),

                    // Gender
                    _SectionLabel(label: 'Gender'),
                    const SizedBox(height: 10),
                    Obx(() => Row(
                          children: [
                            _GenderPill(
                              label: 'Male',
                              value: 'male',
                              selected: controller.selectedGender.value == 'male',
                              onTap: () => controller.selectedGender.value = 'male',
                            ),
                            const SizedBox(width: 10),
                            _GenderPill(
                              label: 'Female',
                              value: 'female',
                              selected: controller.selectedGender.value == 'female',
                              onTap: () => controller.selectedGender.value = 'female',
                            ),
                            const SizedBox(width: 10),
                            _GenderPill(
                              label: 'Other',
                              value: 'other',
                              selected: controller.selectedGender.value == 'other',
                              onTap: () => controller.selectedGender.value = 'other',
                            ),
                          ],
                        )),
                    const SizedBox(height: 14),
                    _InputField(
                      label: 'Address',
                      controller: controller.addressController,
                      icon: Icons.location_on_outlined,
                      hint: 'Enter address',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 24),

                    // ── Emergency Contact ─────────────────────────
                    Container(height: 1, color: _kBorder),
                    const SizedBox(height: 20),
                    _SectionLabel(label: 'Emergency Contact'),
                    const SizedBox(height: 12),
                    _InputField(
                      label: 'Contact Name',
                      controller: controller.emergencyNameController,
                      icon: Icons.person_search_rounded,
                      hint: 'Emergency contact name',
                    ),
                    const SizedBox(height: 14),
                    _InputField(
                      label: 'Contact Mobile',
                      controller: controller.emergencyMobileController,
                      icon: Icons.phone_rounded,
                      hint: 'Emergency contact mobile',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 32),

                    // ── Save button ───────────────────────────────
                    Obx(() => SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: controller.isUpdating.value
                                ? null
                                : () async {
                                    final success =
                                        await controller.saveProfile();
                                    if (success) {
                                      Get.back();
                                      Helpers.showToast('Profile updated successfully.');
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kNavy,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: controller.isUpdating.value
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        )),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFFF3F4F6),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 42,
            height: 42,
            child: Center(child: Icon(icon, size: 20, color: _kNavy)),
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: _kGreen,
          letterSpacing: 0.6,
        ),
      );
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
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _kNavy,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _kNavy,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _kMuted),
            prefixIcon: Icon(icon, color: _kGreen, size: 20),
            filled: true,
            fillColor:
                readOnly ? const Color(0xFFF3F4F6) : Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kGreen, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kBorder),
            ),
          ),
        ),
      ],
    );
  }
}

class _GenderPill extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  const _GenderPill({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Material(
          color: selected ? _kNavy : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? _kNavy : _kBorder,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _kMuted,
                ),
              ),
            ),
          ),
        ),
      );
}
