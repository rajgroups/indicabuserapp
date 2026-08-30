import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/utils/Helpers.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/modules/profile/ProfileController.dart';

const _kNavy   = Color(0xFF1A1A2E);
const _kGreen  = Color(0xFF00C853);
const _kRed    = Color(0xFFE53935);
const _kBg     = Color(0xFFF5F6FA);
const _kBorder = Color(0xFFEEEFF3);
const _kMuted  = Color(0xFFB0B3C1);

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
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Rapido-style top bar ──────────────────────────────────────
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
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _kNavy,
                      ),
                    ),
                    Text(
                      'Manage your preferences',
                      style: TextStyle(fontSize: 12, color: _kMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Settings list ─────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              physics: const BouncingScrollPhysics(),
              children: [
                // Preferences
                _SectionHeader(label: 'Preferences'),
                const SizedBox(height: 8),
                _SettingsCard(children: [
                  _SwitchRow(
                    icon: Icons.notifications_rounded,
                    iconColor: _kNavy,
                    title: 'Push Notifications',
                    subtitle: 'Updates about your rides',
                    value: pushNotifications,
                    onChanged: (v) => setState(() => pushNotifications = v),
                  ),
                  _CardDivider(),
                  _SwitchRow(
                    icon: Icons.mail_rounded,
                    iconColor: const Color(0xFF6C63FF),
                    title: 'Promotional Emails',
                    subtitle: 'Offers and discounts',
                    value: promoEmails,
                    onChanged: (v) => setState(() => promoEmails = v),
                  ),
                  _CardDivider(),
                  _SwitchRow(
                    icon: Icons.location_on_rounded,
                    iconColor: _kGreen,
                    title: 'Location Tracking',
                    subtitle: 'Improve pickup accuracy',
                    value: locationTracking,
                    onChanged: (v) => setState(() => locationTracking = v),
                  ),
                ]),

                const SizedBox(height: 20),

                // Account
                _SectionHeader(label: 'Account'),
                const SizedBox(height: 8),
                _SettingsCard(children: [
                  _TileRow(
                    icon: Icons.lock_rounded,
                    iconColor: const Color(0xFF00B4D8),
                    title: 'Change Password',
                    subtitle: 'Update security credentials',
                    onTap: () => Helpers.showToast('Change Password feature is coming soon!'),
                  ),
                  _CardDivider(),
                  _TileRow(
                    icon: Icons.language_rounded,
                    iconColor: const Color(0xFF9C27B0),
                    title: 'Language',
                    subtitle: 'English (IN)',
                    onTap: () => Helpers.showToast('Language settings coming soon!'),
                  ),
                  _CardDivider(),
                  _TileRow(
                    icon: Icons.privacy_tip_rounded,
                    iconColor: _kNavy,
                    title: 'Privacy Policy',
                    subtitle: 'Review our privacy rules',
                    onTap: () => Helpers.showToast('Privacy Policy feature coming soon!'),
                  ),
                ]),

                const SizedBox(height: 20),

                // Danger zone
                _SectionHeader(label: 'Danger Zone'),
                const SizedBox(height: 8),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => _handleDeleteAccount(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: _kRed.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _kRed.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.delete_forever_rounded,
                                color: _kRed,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delete Account',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: _kRed,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Permanently remove your data',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _kRed,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: _kRed,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final ProfileController profileController = Get.put(ProfileController());

    // Show loading spinner
    Helpers.loading();
    final otp = await profileController.requestDeleteOtp();
    Helpers.close(); // close loading spinner

    if (otp.isEmpty) {
      Helpers.showToast('Failed to send verification code. Please try again.');
      return;
    }

    // Now, show the OTP input dialog
    final TextEditingController otpInputController = TextEditingController(text: otp);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Verify Deletion',
          style: TextStyle(fontWeight: FontWeight.w900, color: _kNavy),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A verification code has been generated. Please enter the OTP to confirm deactivating and soft-deleting your account.',
              style: TextStyle(color: _kMuted, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpInputController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: 'Enter OTP',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel', style: TextStyle(color: _kMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = otpInputController.text.trim();
              if (code.length < 4) {
                Helpers.showToast('Please enter a valid OTP.');
                return;
              }

              Navigator.of(dialogContext).pop(); // close dialog
              Helpers.loading(); // show loading spinner
              final success = await profileController.confirmDeleteAccount(code);
              Helpers.close(); // close loading spinner

              if (success) {
                Helpers.showToast('Your account was soft-deleted successfully.');
                await Future.delayed(const Duration(seconds: 1));
                Get.offAllNamed(RouteNames.login);
              } else {
                Helpers.showToast('Invalid OTP. Account deletion aborted.');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

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

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: _kGreen,
          letterSpacing: 0.8,
        ),
      );
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(children: children),
      );
}

class _CardDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, color: _kBorder, indent: 70);
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 20)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kNavy)),
                  Text(subtitle,
                      style: const TextStyle(fontSize: 12, color: _kMuted)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: _kNavy,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: _kBorder,
            ),
          ],
        ),
      );
}

class _TileRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TileRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Icon(icon, color: iconColor, size: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kNavy)),
                      Text(subtitle,
                          style: const TextStyle(fontSize: 12, color: _kMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: _kMuted, size: 20),
              ],
            ),
          ),
        ),
      );
}