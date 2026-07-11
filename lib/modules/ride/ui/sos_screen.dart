import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Colors.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

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
          'Emergency SOS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.red,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shield_rounded,
                size: 56,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Are you in an emergency?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our safety team and local authorities are here to help you immediately.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 40),
            _EmergencyButton(
              icon: Icons.local_police_rounded,
              title: 'Call Police',
              subtitle: 'Dial 100 for immediate police assistance',
              onTap: () => Get.snackbar('Dialing', 'Connecting to Police...', backgroundColor: Colors.red, colorText: Colors.white),
              isPrimary: true,
            ),
            const SizedBox(height: 16),
            _EmergencyButton(
              icon: Icons.medical_services_rounded,
              title: 'Call Ambulance',
              subtitle: 'Dial 108 for medical emergencies',
              onTap: () => Get.snackbar('Dialing', 'Connecting to Ambulance...', backgroundColor: Colors.red, colorText: Colors.white),
              isPrimary: true,
            ),
            const SizedBox(height: 16),
            _EmergencyButton(
              icon: Icons.contact_emergency_rounded,
              title: 'Alert Emergency Contacts',
              subtitle: 'Share live location and ride details',
              onTap: () => Get.snackbar('Alert Sent', 'Your contacts have been notified', backgroundColor: AppColors.surface),
            ),
            const SizedBox(height: 16),
            _EmergencyButton(
              icon: Icons.support_agent_rounded,
              title: 'Indicab Safety Team',
              subtitle: '24/7 dedicated support team',
              onTap: () => Get.snackbar('Connecting', 'Calling Safety Team...', backgroundColor: AppColors.surface),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({required this.icon, required this.title, required this.subtitle, required this.onTap, this.isPrimary = false});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary ? Colors.red.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isPrimary ? Colors.red.withValues(alpha: 0.3) : AppColors.borderSoft),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isPrimary ? Colors.red : AppColors.inputFill,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isPrimary ? Colors.white : AppColors.primaryDark),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isPrimary ? Colors.red : AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: isPrimary ? Colors.red.withValues(alpha: 0.8) : AppColors.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isPrimary ? Colors.red : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}