  import 'package:flutter/material.dart';
  import 'package:get/get.dart';
  import 'package:indicab/core/constants/Colors.dart';
  import 'package:indicab/core/routes/names.dart';
  import 'package:indicab/modules/history/ui/ride_history.dart';
  import 'package:indicab/modules/address/ui/address.dart';
  import 'package:indicab/modules/help/ui/help.dart';
  import 'package:indicab/modules/settings/ui/settings.dart';

  class ProfileScreen extends StatelessWidget {
    const ProfileScreen({super.key});

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
            'Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            // User Info Section
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'A',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderSoft, width: 1.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1A000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amit Sharma',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '+91 9876543210',
                          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.star_rounded, size: 16, color: AppColors.primaryDark),
                            SizedBox(width: 4),
                            Text(
                              '4.85 Rating',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSoft),

            // Wallet Section
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFFC107)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Indicab Wallet',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        Icon(Icons.card_giftcard_rounded, size: 20, color: AppColors.textPrimary),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '₹450',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    const Text(
                      'Available Balance',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Get.snackbar('Wallet', 'Wallet top-up opening soon...', backgroundColor: AppColors.surface);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        minimumSize: const Size(0, 36),
                      ),
                      child: const Text('Add Money', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSoft),

            // Menu Items
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _ProfileMenuItem(
                    icon: Icons.history_rounded,
                    title: 'Ride History',
                    subtitle: 'View all your trips',
                    onTap: () => Get.to(() => const RideHistoryScreen()),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.location_on_rounded,
                    title: 'Saved Addresses',
                    subtitle: 'Home, Work & more',
                    onTap: () => Get.to(() => const SavedAddressesScreen()),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.credit_card_rounded,
                    title: 'Payment Methods',
                    subtitle: 'Manage cards & UPI',
                    onTap: () => Get.snackbar('Payment Methods', 'Manage your cards here.', backgroundColor: AppColors.surface),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.local_offer_rounded,
                    title: 'Offers & Coupons',
                    subtitle: 'Save on your rides',
                    trailingBadge: '3 New',
                    onTap: () => Get.snackbar('Offers', 'View your available coupons.', backgroundColor: AppColors.surface),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    subtitle: 'FAQs & Contact us',
                    onTap: () => Get.to(() => const HelpSupportScreen()),
                  ),
                  _ProfileMenuItem(
                    icon: Icons.settings_rounded,
                    title: 'Settings',
                    subtitle: 'Preferences & privacy',
                    onTap: () => Get.to(() => const SettingsScreen()),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Logout Button
                  InkWell(
                    onTap: () {
                      Get.snackbar('Logout', 'Logging you out...', backgroundColor: AppColors.surface, colorText: Colors.red);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('Indicab v1.0.0', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  class _ProfileMenuItem extends StatelessWidget {
    const _ProfileMenuItem({required this.icon, required this.title, required this.subtitle, this.trailingBadge, this.onTap});

    final IconData icon;
    final String title;
    final String subtitle;
    final String? trailingBadge;
    final VoidCallback? onTap;

    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: AppColors.inputFill, borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: AppColors.primaryDark, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (trailingBadge != null)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(999)),
                    child: Text(trailingBadge!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      );
    }
  }