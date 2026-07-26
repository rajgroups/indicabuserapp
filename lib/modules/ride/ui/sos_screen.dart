import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/network/network_exceptions.dart';
import 'package:indicab/core/repository/SosRepository.dart';
import 'package:url_launcher/url_launcher.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key, required this.bookingNo});

  /// The active booking's unique identifier (booking_no / ulid).
  final String bookingNo;

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final SosRepository _sosRepo = SosRepository(ApiClient());

  /// Track which button type is currently loading.
  String? _loadingType;

  /// Track which types have been successfully triggered.
  final Set<String> _triggeredTypes = {};

  Future<void> _triggerSos({
    required String type,
    required String dialNumber,
  }) async {
    if (_loadingType != null) return; // Prevent multiple simultaneous taps

    // Dial phone for police / ambulance first
    if (dialNumber.isNotEmpty) {
      final uri = Uri(scheme: 'tel', path: dialNumber);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }

    setState(() => _loadingType = type);

    try {
      await _sosRepo.sendSosAlert(
        bookingNo: widget.bookingNo,
        type: type,
      );

      if (mounted) {
        setState(() => _triggeredTypes.add(type));
        _showSnackbar(
          title: '✅ Alert Sent',
          message: _successMessage(type),
          isError: false,
        );
      }
    } on NetworkException catch (e) {
      if (mounted) {
        _showSnackbar(
          title: 'Error',
          message: e.message.isNotEmpty ? e.message : 'Could not send SOS. Please try again.',
          isError: true,
        );
      }
    } catch (_) {
      if (mounted) {
        _showSnackbar(
          title: 'Error',
          message: 'Could not send SOS. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loadingType = null);
    }
  }

  void _showSnackbar({
    required String title,
    required String message,
    required bool isError,
  }) {
    Get.snackbar(
      title,
      message,
      backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade600,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
    );
  }

  String _successMessage(String type) {
    switch (type) {
      case 'police':
        return 'Police alert recorded. Dial 100 if not already connected.';
      case 'ambulance':
        return 'Medical alert recorded. Dial 108 if not already connected.';
      case 'emergency_contact':
        return 'Your emergency contacts have been notified with your ride details.';
      case 'safety_team':
        return 'Indicab Safety Team has been alerted and will contact you shortly.';
      default:
        return 'SOS alert sent successfully.';
    }
  }

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

            // Pulsing SOS icon
            _SosPulsingIcon(),

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

            // Booking reference
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.receipt_long_rounded, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Ride: ${widget.bookingNo}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            _EmergencyButton(
              icon: Icons.local_police_rounded,
              type: 'police',
              title: 'Call Police',
              subtitle: 'Tap to dial 100 & log police alert',
              dialNumber: '100',
              isPrimary: true,
              isLoading: _loadingType == 'police',
              isTriggered: _triggeredTypes.contains('police'),
              onTap: _loadingType == null
                  ? () => _triggerSos(type: 'police', dialNumber: '100')
                  : null,
            ),

            const SizedBox(height: 16),

            _EmergencyButton(
              icon: Icons.medical_services_rounded,
              type: 'ambulance',
              title: 'Call Ambulance',
              subtitle: 'Tap to dial 108 & log medical alert',
              dialNumber: '108',
              isPrimary: true,
              isLoading: _loadingType == 'ambulance',
              isTriggered: _triggeredTypes.contains('ambulance'),
              onTap: _loadingType == null
                  ? () => _triggerSos(type: 'ambulance', dialNumber: '108')
                  : null,
            ),

            const SizedBox(height: 16),

            _EmergencyButton(
              icon: Icons.contact_emergency_rounded,
              type: 'emergency_contact',
              title: 'Alert Emergency Contacts',
              subtitle: 'Notify your contacts with ride details',
              dialNumber: '',
              isPrimary: false,
              isLoading: _loadingType == 'emergency_contact',
              isTriggered: _triggeredTypes.contains('emergency_contact'),
              onTap: _loadingType == null
                  ? () => _triggerSos(type: 'emergency_contact', dialNumber: '')
                  : null,
            ),

            const SizedBox(height: 16),

            _EmergencyButton(
              icon: Icons.support_agent_rounded,
              type: 'safety_team',
              title: 'Indicab Safety Team',
              subtitle: '24/7 dedicated support — we will call you',
              dialNumber: '',
              isPrimary: false,
              isLoading: _loadingType == 'safety_team',
              isTriggered: _triggeredTypes.contains('safety_team'),
              onTap: _loadingType == null
                  ? () => _triggerSos(type: 'safety_team', dialNumber: '')
                  : null,
            ),

            const SizedBox(height: 32),

            // Disclaimer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Each alert is logged with your ride details. Our team reviews all SOS alerts and will follow up with you.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pulsing SOS Icon Widget
// ---------------------------------------------------------------------------

class _SosPulsingIcon extends StatefulWidget {
  @override
  State<_SosPulsingIcon> createState() => _SosPulsingIconState();
}

class _SosPulsingIconState extends State<_SosPulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: 4,
            ),
          ],
        ),
        child: const Icon(
          Icons.shield_rounded,
          size: 60,
          color: Colors.red,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Emergency Action Button
// ---------------------------------------------------------------------------

class _EmergencyButton extends StatelessWidget {
  const _EmergencyButton({
    required this.icon,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.dialNumber,
    required this.isPrimary,
    required this.isLoading,
    required this.isTriggered,
    required this.onTap,
  });

  final IconData icon;
  final String type;
  final String title;
  final String subtitle;
  final String dialNumber;
  final bool isPrimary;
  final bool isLoading;
  final bool isTriggered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = isPrimary ? Colors.red : AppColors.primaryDark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isTriggered
              ? Colors.green.withValues(alpha: 0.08)
              : isPrimary
                  ? Colors.red.withValues(alpha: 0.1)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTriggered
                ? Colors.green.withValues(alpha: 0.4)
                : isPrimary
                    ? Colors.red.withValues(alpha: 0.3)
                    : AppColors.borderSoft,
          ),
        ),
        child: Row(
          children: [
            // Left icon / spinner
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isLoading
                  ? Container(
                      key: const ValueKey('loading'),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: accent,
                        ),
                      ),
                    )
                  : Container(
                      key: const ValueKey('icon'),
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isTriggered
                            ? Colors.green
                            : isPrimary
                                ? Colors.red
                                : AppColors.inputFill,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isTriggered ? Icons.check_rounded : icon,
                        color: isTriggered || isPrimary ? Colors.white : AppColors.primaryDark,
                      ),
                    ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isTriggered
                          ? Colors.green.shade700
                          : isPrimary
                              ? Colors.red
                              : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isTriggered ? 'Alert sent ✓' : subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isTriggered
                          ? Colors.green.shade600
                          : isPrimary
                              ? Colors.red.withValues(alpha: 0.8)
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              isTriggered ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
              color: isTriggered
                  ? Colors.green
                  : isPrimary
                      ? Colors.red
                      : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}