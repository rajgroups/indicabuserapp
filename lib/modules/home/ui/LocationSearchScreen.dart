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

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: Stack(
        children: [
          Obx(
            () => MapViewWidget(
              pickupLocation:
                  controller.pickuplocation.value ?? controller.pickupPoint.value,
              dropLocation: controller.droplocation.value,
              onMapCreated: controller.onMapCreated,
              markers: controller.markers,
            ),
          ),

          // 4. Top Search Area
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 28,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.of(context).padding.top + 10,
                20,
                24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: Get.back,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 48,
                          height: 18,
                          decoration: BoxDecoration(
                            color: AppColors.inputFill,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Select Route',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (!hasValidPlacesKey)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDA4AF)),
                      ),
                      child: const Text(
                        'Invalid Google Places API key. Update GOOGLE_PLACES_API_KEY in .env to enable location search.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9F1239),
                        ),
                      ),
                    ),

                  // Origin Input
                  GooglePlacesInput(
                    hintText: "Pickup Location",
                    controller: controller.originController,
                    prefixIcon: Icons.my_location_rounded,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.gps_fixed),
                      onPressed: () {},
                    ),
                    onPlaceSelected: (place) {
                      controller.setPickup(place);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Destination Input
                  GooglePlacesInput(
                    hintText: "Where to go?",
                    controller: controller.destController,
                    prefixIcon: Icons.location_on_rounded,
                    onPlaceSelected: (place) {
                      controller.setDrop(place);
                    },
                  ),
                ],
              ),
            ),
          ),

          // 5. Confirm Button at bottom
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Confirm Destination',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
