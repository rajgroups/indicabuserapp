import 'package:flutter/material.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:get/get.dart';
import 'package:indicab/core/controller/VehicleController.dart';
import 'package:indicab/shared/widgets/MapViewWidget.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class NearbyVehiclesScreen extends StatelessWidget {
  final String vehicleCategory;
  final int categoryId;

  NearbyVehiclesScreen({
    super.key,
    required this.vehicleCategory,
    required this.categoryId,
  });

  String _formatRadius(int radiusInMeters) {
    if (radiusInMeters >= 1000) {
      final radiusInKm = radiusInMeters / 1000;
      return radiusInKm >= 10
          ? '${radiusInKm.toStringAsFixed(0)} km'
          : '${radiusInKm.toStringAsFixed(1)} km';
    }

    return '$radiusInMeters m';
  }

  String _formatApiRadius(int radiusInMeters) {
    return '$radiusInMeters m';
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      Vehiclecontroller(categoryId: categoryId),
      tag: 'nearby-$categoryId',
    );
    final viewportSize = MediaQuery.of(context).size;
    final overlayDiameter = viewportSize.shortestSide * 0.32;

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Obx(
              () => MapViewWidget(
                key: ValueKey('nearby-map-$categoryId'),
                zoom: 14, // Increased zoom level to see streets/markers
                onMapCreated: controller.setMapController,
                pickupLocation:
                    controller.currentLocation.value.latitude == 0 &&
                        controller.currentLocation.value.longitude == 0
                    ? controller.searchCenter.value
                    : controller.currentLocation.value,
                markers: controller.markers.toSet(),
                onCameraMove: controller.onCameraMove,
                onCameraIdle: controller.onCameraIdle,
                myLocationButtonEnabled: false,
                compassEnabled: false,
              ),
            ),
          ),
            Positioned(
                right: 16,
                top: MediaQuery.of(context).size.height * 0.35,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                    backgroundColor: AppColors.primary,
                      heroTag: "zoom_in",
                      onPressed: () {
                        controller.mapController?.animateCamera(
                          CameraUpdate.zoomIn(),
                        );
                      },
                      child: const Icon(Icons.add),
                    ),

                    const SizedBox(height: 8),

                    FloatingActionButton.small(
                      backgroundColor: AppColors.primary,
                      heroTag: "zoom_out",
                      onPressed: () {
                        controller.mapController?.animateCamera(
                          CameraUpdate.zoomOut(),
                        );
                      },
                      child: const Icon(Icons.remove),
                    ),

                    const SizedBox(height: 8),

                    FloatingActionButton.small(
                      backgroundColor: AppColors.primary,
                      heroTag: "gps",
                      onPressed: () {
                        controller.moveToCurrentLocation();
                      },
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
          IgnorePointer(
            child: Center(
              child: Container(
                width: overlayDiameter,
                height: overlayDiameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x332196F3),
                  border: Border.all(
                    color: const Color(0xFF1976D2),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          // 4. Floating Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, left: 20, right: 20),
              child: Row(
                children: [
                  InkWell(
                    onTap: Get.back,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Color(0x16000000), blurRadius: 18, offset: Offset(0, 6)),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(color: Color(0x16000000), blurRadius: 20, offset: Offset(0, 8)),
                        ],
                      ),
                      child: Text(
                        'Nearby $vehicleCategory',
                        style: const TextStyle(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 20,
            right: 20,
            child: Obx(
              () => Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xCC0D47A1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    'Showing vehicles in ${_formatRadius(controller.activeApiRadius.value)} radius • API: ${_formatApiRadius(controller.activeApiRadius.value)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
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
