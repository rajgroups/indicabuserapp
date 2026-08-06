import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/config/Config.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/modules/home/HomeController.dart';
import 'package:indicab/shared/widgets/MapViewWidget.dart';
import 'package:indicab/shared/widgets/google_places_input.dart';

class LocationSearchScreen extends GetView<HomeController> {
  const LocationSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool hasValidPlacesKey = AppEnv.hasGooglePlacesApiKey;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: Stack(
        children: [
          // Fullscreen Google Map Background
          Obx(
            () => MapViewWidget(
              pickupLocation:
                  controller.pickuplocation.value ?? controller.pickupPoint.value,
              dropLocation: controller.droplocation.value,
              onMapCreated: controller.onMapCreated,
              markers: controller.markers,
              polylines: controller.polylines,
            ),
          ),

          // Top Rapido-Style Route Selection Card
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(16, topPadding + 8, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App Bar Row
                  Row(
                    children: [
                      InkWell(
                        onTap: Get.back,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.textPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Select Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (!hasValidPlacesKey)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDA4AF)),
                      ),
                      child: const Text(
                        'Invalid Google Places API key. Update GOOGLE_PLACES_API_KEY in .env to enable search.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9F1239),
                        ),
                      ),
                    ),

                  // Unified Rapido Two-Dot Route Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Visual Route Connector (Green Dot -> Line -> Red Pin)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Container(
                                  width: 5,
                                  height: 5,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 32,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9CA3AF),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFE53935),
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),

                        // Middle Search Inputs (Pickup & Drop)
                        Expanded(
                          child: Column(
                            children: [
                              // Pickup Input
                              GooglePlacesInput(
                                hintText: "Pickup Location",
                                controller: controller.originController,
                                prefixIcon: Icons.my_location_rounded,
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.gps_fixed_rounded,
                                    color: AppColors.primaryDark,
                                    size: 20,
                                  ),
                                  tooltip: 'Current Location',
                                  onPressed: () async {
                                    await controller
                                        .detectAndSetCurrentLocation(force: true);
                                  },
                                ),
                                onPlaceSelected: (place) {
                                  controller.setPickup(place);
                                },
                              ),

                              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                              // Destination Input
                              GooglePlacesInput(
                                hintText: "Where are you going?",
                                controller: controller.destController,
                                prefixIcon: Icons.location_on_rounded,
                                onPlaceSelected: (place) {
                                  controller.setDrop(place);
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Right Column: Add Stop (+) and Swap (⇅) Buttons
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Material(
                              color: const Color(0xFFECEFF1),
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () {
                                  Get.snackbar(
                                    'Multiple Stops',
                                    'Multiple drop-off stops feature coming soon!',
                                    backgroundColor: AppColors.surface,
                                    colorText: AppColors.textPrimary,
                                    icon: const Icon(
                                      Icons.info_outline_rounded,
                                      color: AppColors.primaryDark,
                                    ),
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: AppColors.textPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Material(
                              color: const Color(0xFFECEFF1),
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: controller.swapLocations,
                                child: const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.swap_vert_rounded,
                                    color: AppColors.textPrimary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Quick Action Chips (Rapido Style)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _QuickChip(
                          icon: Icons.map_rounded,
                          label: 'Set on map',
                          color: AppColors.primaryDark,
                          onTap: Get.back,
                        ),
                        const SizedBox(width: 8),
                        _QuickChip(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          color: const Color(0xFF2196F3),
                          onTap: () => Get.snackbar(
                            'Home',
                            'Select home address',
                            backgroundColor: AppColors.surface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _QuickChip(
                          icon: Icons.work_rounded,
                          label: 'Work',
                          color: const Color(0xFF607D8B),
                          onTap: () => Get.snackbar(
                            'Work',
                            'Select work address',
                            backgroundColor: AppColors.surface,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _QuickChip(
                          icon: Icons.history_rounded,
                          label: 'Recent',
                          color: const Color(0xFF9C27B0),
                          onTap: () => Get.snackbar(
                            'Recent',
                            'Viewing recent places',
                            backgroundColor: AppColors.surface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Floating GPS & Map Control Buttons (Aligned dynamically above bottom card)
          Obx(() {
            final hasDrop = controller.droplocation.value != null;
            final bottomPadding = hasDrop ? 150.0 : 90.0;

            return Positioned(
              right: 16,
              bottom: bottomPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: AppColors.surface,
                    elevation: 4,
                    shadowColor: const Color(0x33000000),
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: controller.moveToCurrentLocation,
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Center(
                          child: Icon(
                            Icons.my_location_rounded,
                            color: AppColors.primaryDark,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Bottom Route Summary & Confirm Button
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Obx(() {
              final hasDrop = controller.droplocation.value != null;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasDrop) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2E7D32),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              controller.dropAddress.value.isNotEmpty
                                  ? controller.dropAddress.value
                                  : 'Destination Selected',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Get.back(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 4,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        hasDrop ? 'Confirm Destination' : 'Done',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

