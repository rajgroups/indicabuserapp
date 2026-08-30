import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/utils/Helpers.dart';
import 'package:indicab/modules/history/ui/ride_history.dart';
import 'package:indicab/modules/help/ui/help.dart';
import 'package:indicab/modules/settings/ui/settings.dart';
import 'package:indicab/modules/profile/ProfileController.dart';
import 'package:indicab/modules/profile/ui/EditProfileScreen.dart';
import 'package:indicab/modules/auth/AuthController.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kNavy   = Color(0xFF1A1A2E);
const _kGreen  = Color(0xFF00C853);
const _kRed    = Color(0xFFE53935);
const _kBg     = Color(0xFFF5F6FA);
const _kBorder = Color(0xFFEEEFF3);
const _kMuted  = Color(0xFFB0B3C1);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController profileController = Get.put(ProfileController());
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _kBg,
      body: Obx(() {
        final profile = profileController.userProfile.value;
        final displayName = profile?.displayName ?? 'User';
        final displayPhone = profile?.displayPhone ?? 'Setting up profile...';
        final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
        final rating = profile?.rating ?? 4.85;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Collapsible hero header ───────────────────────────────
            SliverAppBar(
              backgroundColor: _kNavy,
              expandedHeight: 220,
              pinned: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                onPressed: Get.back,
              ),
              title: const Text(
                'My Profile',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  color: _kNavy,
                  padding: EdgeInsets.fromLTRB(20, topPad + 60, 20, 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Get.to(() => const EditProfileScreen()),
                        child: Row(
                          children: [
                            // Avatar
                            Stack(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: _kGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.25),
                                        width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _kGreen.withValues(alpha: 0.4),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    initial,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _kNavy, width: 1.5),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      size: 13,
                                      color: _kNavy,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    displayPhone,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.65),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          size: 14, color: Color(0xFFFFCC00)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${rating.toStringAsFixed(2)} rating',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFFFCC00),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white54,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Wallet section disabled

                  // ── Section label ───────────────────────────────────
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'QUICK ACCESS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _kGreen,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),

                  // ── Menu items card ─────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _kBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _MenuItem(
                            icon: Icons.history_rounded,
                            iconBg: _kNavy.withValues(alpha: 0.10),
                            iconColor: _kNavy,
                            title: 'Ride History',
                            subtitle: 'View all your trips',
                            onTap: () => Get.to(() => const RideHistoryScreen()),
                          ),
                          _Divider(),
                          _MenuItem(
                            icon: Icons.location_on_rounded,
                            iconBg: _kGreen.withValues(alpha: 0.10),
                            iconColor: _kGreen,
                            title: 'Saved Addresses',
                            subtitle: 'Home, Work & more',
                            isComingSoon: true,
                            onTap: () => Helpers.showComingSoon('Saved Addresses'),
                          ),
                          _Divider(),
                          _MenuItem(
                            icon: Icons.credit_card_rounded,
                            iconBg: const Color(0xFF6C63FF).withValues(alpha: 0.10),
                            iconColor: const Color(0xFF6C63FF),
                            title: 'Payment Methods',
                            subtitle: 'Manage cards & UPI',
                            isComingSoon: true,
                            onTap: () => Helpers.showComingSoon('Payment Methods'),
                          ),
                          _Divider(),
                          _MenuItem(
                            icon: Icons.local_offer_rounded,
                            iconBg: const Color(0xFFFF8F00).withValues(alpha: 0.10),
                            iconColor: const Color(0xFFFF8F00),
                            title: 'Offers & Coupons',
                            subtitle: 'Save on your rides',
                            isComingSoon: true,
                            onTap: () => Helpers.showComingSoon('Offers & Coupons'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ACCOUNT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: _kGreen,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _kBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _MenuItem(
                            icon: Icons.help_outline_rounded,
                            iconBg: const Color(0xFF00B4D8).withValues(alpha: 0.10),
                            iconColor: const Color(0xFF00B4D8),
                            title: 'Help & Support',
                            subtitle: 'FAQs & contact us',
                            onTap: () => Get.to(() => const HelpSupportScreen()),
                          ),
                          _Divider(),
                          _MenuItem(
                            icon: Icons.settings_rounded,
                            iconBg: _kNavy.withValues(alpha: 0.10),
                            iconColor: _kNavy,
                            title: 'Settings',
                            subtitle: 'Preferences & privacy',
                            onTap: () => Get.to(() => const SettingsScreen()),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Logout button ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {
                          Get.dialog(
                            AlertDialog(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text(
                                'Logout',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: _kNavy,
                                ),
                              ),
                              content: const Text(
                                'Are you sure you want to log out of Indicab?',
                                style: TextStyle(color: _kMuted),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: Get.back,
                                  child: const Text('Cancel',
                                      style: TextStyle(color: _kMuted)),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Get.back();
                                    final authController =
                                        Get.isRegistered<AuthController>()
                                            ? Get.find<AuthController>()
                                            : Get.put(AuthController());
                                    authController.logout();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kRed,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: _kRed.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, color: _kRed, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _kRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  const Text(
                    'Indicab v1.0.0',
                    style: TextStyle(fontSize: 12, color: _kMuted),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Menu item widget ──────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isComingSoon = false,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isComingSoon;


  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Opacity(
            opacity: isComingSoon ? 0.7 : 1.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                        child: Icon(icon, color: iconColor, size: 20)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isComingSoon ? _kMuted : _kNavy,
                          ),
                        ),
                        Text(subtitle,
                            style: const TextStyle(
                                fontSize: 12, color: _kMuted)),
                      ],
                    ),
                  ),
                  if (isComingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kBorder,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        'Soon',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _kMuted,
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isComingSoon ? _kBorder : _kMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: _kBorder, indent: 72);
}