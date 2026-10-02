import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/services/StorageService.dart';
import 'package:indicab/core/constants/Colors.dart';

class OnboardingOverlay extends StatefulWidget {
  final Widget child;

  const OnboardingOverlay({super.key, required this.child});

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  final StorageService _storageService = Get.isRegistered<StorageService>()
      ? Get.find<StorageService>()
      : Get.put(StorageService());
  bool _showOverlay = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final hasSeenOnboarding =
        _storageService.read('hasSeenOnboarding') ?? false;
    if (!hasSeenOnboarding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _showOverlay = true;
        });
      });
    }
  }

  void _nextStep() {
    setState(() {
      if (_currentStep < 2) {
        _currentStep++;
      } else {
        _dismissOnboarding();
      }
    });
  }

  void _dismissOnboarding() {
    _storageService.write('hasSeenOnboarding', true);
    setState(() {
      _showOverlay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showOverlay)
          Positioned.fill(
            child: Material(
              color: Colors.black.withOpacity(0.7),
              child: SafeArea(
                child: Stack(
                  children: [
                    // Close button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed: _dismissOnboarding,
                      ),
                    ),

                    // Content
                    Positioned(
                      left: 20,
                      right: 20,
                      top: _currentStep == 0
                          ? MediaQuery.of(context).size.height * 0.45
                          : _currentStep == 1
                          ? MediaQuery.of(context).size.height * 0.25
                          : MediaQuery.of(context).size.height * 0.65,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentStep == 0
                                  ? 'Choose Your Ride'
                                  : _currentStep == 1
                                  ? 'Destination is Optional!'
                                  : 'Book Instantly',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _currentStep == 0
                                  ? 'Select from cars, bikes, tractors, and more. Swipe horizontally to see all options.'
                                  : _currentStep == 1
                                  ? 'For services like tractors or hourly rentals, you don\'t need to enter a drop location. Just book and tell the driver where to go!'
                                  : 'Ready to go? Tap the Book button to find a driver immediately or schedule for later.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: List.generate(
                                    3,
                                    (index) => Container(
                                      margin: const EdgeInsets.only(right: 6),
                                      width: _currentStep == index ? 24 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _currentStep == index
                                            ? AppColors.primary
                                            : AppColors.border,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: _nextStep,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    _currentStep < 2 ? 'Next' : 'Got it!',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
