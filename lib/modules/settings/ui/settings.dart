// Settings Screen
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool pushNotifications = true;
  bool promoEmails = false;
  bool locationTracking = true;

  @override
  Widget build(BuildContext context) {
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
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSectionHeader('Preferences'),
          _buildSwitchTile('Push Notifications', 'Updates about your rides', pushNotifications, (v) => setState(() => pushNotifications = v)),
          _buildSwitchTile('Promotional Emails', 'Offers and discounts', promoEmails, (v) => setState(() => promoEmails = v)),
          _buildSwitchTile('Location Tracking', 'Improve pickup accuracy', locationTracking, (v) => setState(() => locationTracking = v)),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Account'),
          _buildListTile(Icons.lock_rounded, 'Change Password', 'Update your security credentials'),
          _buildListTile(Icons.language_rounded, 'Language', 'English (US)'),
          _buildListTile(Icons.privacy_tip_rounded, 'Privacy Policy', 'Review our privacy rules'),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Danger Zone'),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
            ),
            title: const Text('Delete Account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.red)),
            subtitle: const Text('Permanently remove your data', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            onTap: () {
              Get.snackbar('Warning', 'Account deletion requires verification.', backgroundColor: AppColors.surface, colorText: Colors.red);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.surface,
      activeTrackColor: AppColors.textPrimary,
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    );
  }

  Widget _buildListTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.inputFill, shape: BoxShape.circle),
        child: Icon(icon, color: AppColors.primaryDark, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      onTap: () {
        Get.snackbar(title, 'Navigating to $title settings...', backgroundColor: AppColors.surface);
      },
    );
  }
}