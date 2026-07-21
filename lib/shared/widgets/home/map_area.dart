import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:indicab/core/config/Config.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/modules/home/HomeController.dart';
import 'package:indicab/shared/widgets/MapViewWidget.dart';

class HomeMapArea extends GetView<HomeController> {
  const HomeMapArea({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = width < 380 ? 390.0 : 420.0;
    final shouldShowFallback = kIsWeb || !AppEnv.hasGoogleMapsApiKey;

    debugPrint(
      'HomeMapArea: isWeb=$kIsWeb, '
      'hasGoogleMapsApiKey=${AppEnv.hasGoogleMapsApiKey}, '
      'showFallback=$shouldShowFallback',
    );

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          if (shouldShowFallback)
            _MapSetupFallback(isWeb: kIsWeb)
          else

            Obx(
              () => MapViewWidget(
                pickupLocation: controller.pickupPoint.value,
                dropLocation: controller.droplocation.value,
                onMapCreated: controller.onMapCreated,
                markers: controller.markers,
                polylines: controller.polylines,
                zoom: 2,
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.authBackground.withValues(alpha: 0.08),
                      AppColors.authBackground.withValues(alpha: 0.02),
                      AppColors.authBackground.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 18,
            child: Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x16000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            controller.isAddressLoading.value
                                ? 'Finding address...'
                                : 'Drop location',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.dropAddress.value.isNotEmpty
                                ? controller.dropAddress.value
                                : 'Tap search bar to select destination',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.droplocation.value != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: controller.launchExternalNavigation,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.navigation_rounded,
                                size: 16,
                                color: AppColors.textPrimary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Maps',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapSetupFallback extends StatelessWidget {
  const _MapSetupFallback({required this.isWeb});

  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8F6F0), Color(0xFFF7F0D7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.map_rounded,
                size: 42,
                color: AppColors.primaryDark,
              ),
              const SizedBox(height: 12),
              Text(
                isWeb ? 'Google Maps web setup needed' : 'Add your Google Maps key',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isWeb
                    ? 'The map is hidden on web until the Google Maps JavaScript script is added.'
                    : 'Replace the dummy GOOGLE_MAPS_API_KEY value in .env and rebuild the app.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeTopBar extends GetView<HomeController> {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.only(top: 22, left: 20, right: 20),
      child: Row(
        children: [
          InkWell(
            onTap: () => Get.toNamed(RouteNames.menu),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: width < 380 ? 48 : 54,
              height: width < 380 ? 48 : 54,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x16000000),
                    blurRadius: 18,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.menu_rounded,
                size: 28,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Obx(
              () => InkWell(
                onTap: () => Get.toNamed(RouteNames.locationSearch),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: width < 380 ? 14 : 18,
                    vertical: width < 380 ? 14 : 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x16000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pickup Location',
                        style: TextStyle(
                          fontSize: width < 380 ? 12 : 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.pickupAddress.value.isNotEmpty
                            ? controller.pickupAddress.value
                            : 'Select Pickup Location',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: width < 380 ? 14 : 16,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
