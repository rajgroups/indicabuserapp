import 'package:flutter/material.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/controller/BookingController.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:get/get.dart';
import 'package:indicab/layout/app.dart';
import 'package:indicab/modules/vehicle/nearby.dart';
import 'package:indicab/shared/widgets/home/home_widgets.dart';
import 'package:indicab/modules/home/HomeController.dart';
import 'package:indicab/modules/home/models/VehicleModels.dart';
import 'package:indicab/core/models/booking_response.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 380;
    final vehicleHeight = compact ? 208.0 : 216.0;
    final mapOffset = compact ? 390.0 : 330.0;

    return AppScreen(
      backgroundColor: AppColors.authBackground,
      safeAreaBottom: false,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                const HomeMapArea(),
                Obx(() {
                  final activeRide = controller.activeRide.value;
                  if (activeRide == null) {
                    return const SizedBox.shrink();
                  }

                  return Positioned(
                    top: 16,
                    left: 20,
                    right: 20,
                    child: _ActiveRideFloatingCard(
                      booking: activeRide,
                      onTap: () {
                        final status = activeRide.status?.trim().toLowerCase();
                        final bookingArgs = <String, dynamic>{
                          'booking_no': activeRide.bookingNo,
                          'booking_data': activeRide,
                        };
                        if (status == 'pending') {
                          Get.toNamed(
                            RouteNames.findingDriver,
                            arguments: <String, dynamic>{
                              'booking_no': activeRide.bookingNo,
                              'booking_data': activeRide,
                              'vehicle_type': activeRide.categoryName,
                            },
                          );
                        } else if (status == 'accepted' || status == 'started') {
                          Get.toNamed(
                            RouteNames.activeRide,
                            arguments: bookingArgs,
                          );
                        } else if (status == 'completed') {
                          Get.toNamed(
                            RouteNames.rideSummary,
                            arguments: bookingArgs,
                          );
                        }
                      },
                    ),
                  );
                }),
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SizedBox(height: mapOffset),
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x14000000),
                              blurRadius: 28,
                              offset: Offset(0, -6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            compact ? 16 : 20,
                            12,
                            compact ? 16 : 20,
                            32,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 52,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: AppColors.border,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              HomeSearchBar(
                                onTap: () =>
                                    Get.toNamed(RouteNames.locationSearch),
                              ),
                              const SizedBox(height: 6),
                              const HomeSectionTitle(
                                title: 'Choose Your Ride',
                                subtitle:
                                    'Pick the vehicle that matches this trip',
                              ),
                              const SizedBox(height: 16),
                              Obx(() {
                                if (controller.isLoading.value) {
                                  return SizedBox(
                                    height: vehicleHeight,
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                if (controller.vehicleTypes.isEmpty) {
                                  return SizedBox(
                                    height: vehicleHeight,
                                    child: Center(
                                      child: Text(
                                        'No vehicles available right now',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: compact ? 13 : 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  );
                                }

                                return SizedBox(
                                  height: vehicleHeight,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      final option =
                                          controller.vehicleTypes[index];
                                      final isSelected =
                                          controller
                                              .selectedVehicle
                                              .value
                                              ?.id ==
                                          option.id;

                                      return VehicleCard(
                                        option: option,
                                        isSelected: isSelected,
                                        onTap: () {
                                          controller.toggleVehicleSelection(
                                            option,
                                          );
                                          if (!isSelected) {
                                            _openVehicleSheet(context, option);
                                          }
                                        },
                                        onMapTap: () {
                                          Get.to(
                                            () => NearbyVehiclesScreen(
                                              categoryId: option.id,
                                              vehicleCategory: option.label,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 14),
                                    itemCount: controller.vehicleTypes.length,
                                  ),
                                );
                              }),
                              Obx(() {
                                final selectedVehicle =
                                    controller.selectedVehicle.value;

                                if (selectedVehicle == null) {
                                  return const SizedBox.shrink();
                                }

                                return Column(
                                  children: [
                                    const SizedBox(height: 18),
                                    SelectedVehicleHint(
                                      option: selectedVehicle,
                                      onTap: () => _openVehicleSheet(
                                        context,
                                        selectedVehicle,
                                      ),
                                    ),
                                  ],
                                );
                              }),
                              const SizedBox(height: 28),
                              const HomeSectionTitle(
                                title: 'Trip Essentials',
                                subtitle:
                                    'Shortcuts people use most while booking',
                              ),
                              const SizedBox(height: 14),
                              width < 420
                                  ? Column(
                                      children: [
                                        HomeQuickActionCard(
                                          icon: Icons.history_rounded,
                                          title: 'Recent',
                                          subtitle: 'Past trips',
                                          onTap: () => Get.toNamed(
                                            RouteNames.rideHistory,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        HomeQuickActionCard(
                                          icon: Icons.local_offer_rounded,
                                          title: 'Offers',
                                          subtitle: 'Save more',
                                          onTap: () => _showBookingSnack(
                                            context,
                                            'View offers',
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(
                                          child: HomeQuickActionCard(
                                            icon: Icons.history_rounded,
                                            title: 'Recent',
                                            subtitle: 'Past trips',
                                            onTap: () => Get.toNamed(
                                              RouteNames.rideHistory,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: HomeQuickActionCard(
                                            icon: Icons.local_offer_rounded,
                                            title: 'Offers',
                                            subtitle: 'Save more',
                                            onTap: () => _showBookingSnack(
                                              context,
                                              'View offers',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                              const SizedBox(height: 20),
                              const HomePromoBanner(),
                              const SizedBox(height: 28),
                              const HomeSectionTitle(
                                title: 'Booking Details',
                                subtitle:
                                    'Helpful information before you confirm',
                              ),
                              const SizedBox(height: 14),
                              const HomeBookingInfoCard(
                                icon: Icons.schedule_rounded,
                                title: 'Ride Availability',
                                value: 'Fast pickup in 3-5 mins',
                              ),
                              const SizedBox(height: 12),
                              const HomeBookingInfoCard(
                                icon: Icons.payments_rounded,
                                title: 'Payment Mode',
                                value: 'Cash, UPI and wallet supported',
                              ),
                              const SizedBox(height: 12),
                              const HomeBookingInfoCard(
                                icon: Icons.shield_rounded,
                                title: 'Safety',
                                value: 'Verified drivers and live tracking',
                              ),
                              const SizedBox(height: 28),
                              const HomeSectionTitle(
                                title: 'Saved Places',
                                subtitle:
                                    'Quickly book your most common routes',
                              ),
                              const SizedBox(height: 14),
                              HomeSavedPlaceTile(
                                icon: Icons.home_rounded,
                                title: 'Home',
                                subtitle: 'Koramangala, Bangalore',
                                onTap: () =>
                                    _showBookingSnack(context, 'Home selected'),
                              ),
                              const SizedBox(height: 10),
                              HomeSavedPlaceTile(
                                icon: Icons.work_rounded,
                                title: 'Work',
                                subtitle: 'Whitefield, Bangalore',
                                onTap: () =>
                                    _showBookingSnack(context, 'Work selected'),
                              ),
                              const SizedBox(height: 10),
                              HomeSavedPlaceTile(
                                icon: Icons.train_rounded,
                                title: 'Airport',
                                subtitle: 'Kempegowda International Airport',
                                onTap: () => _showBookingSnack(
                                  context,
                                  'Airport selected',
                                ),
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showBookingSnack(
                                    context,
                                    'Continue to booking',
                                  ),
                                  icon: const Icon(Icons.arrow_forward_rounded),
                                  label: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4),
                                    child: Text(
                                      'Continue Booking',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: AppColors.textPrimary,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: HomeTopBar(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> _openVehicleSheet(
    BuildContext context,
    VehicleOption option,
  ) async {
    final parentContext = context;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5, // Now starting at 0.5
          minChildSize: 0.3, // Can shrink down to 0.3
          maxChildSize: 0.9, // Can expand up to 0.9
          expand: false, // Often helpful in BottomSheets
          builder: (context, scrollController) {
            return VehicleDetailsSheet(
              option: option,
              scrollController: scrollController,
              onSelect: (subCategory) {
                Navigator.of(context).pop();
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!parentContext.mounted) {
                    return;
                  }
                  Get.find<BookingController>().showBookingModeDialog(
                    parentContext,
                    option,
                    subCategory,
                  );
                });
              },
              onMapTap: (subCategory) {
                Navigator.of(context).pop();
                Get.to(
                  () => NearbyVehiclesScreen(
                    vehicleCategory: subCategory.name,
                    categoryId: subCategory.id,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ActiveRideFloatingCard extends StatelessWidget {
  const _ActiveRideFloatingCard({required this.booking, required this.onTap});

  final BookingDataModel booking;
  final VoidCallback onTap;

  String get _statusText {
    final value = booking.status?.trim().toLowerCase();
    return switch (value) {
      'pending' => 'Finding your driver...',
      'accepted' => 'Driver is arriving',
      'started' => 'On trip to destination',
      'completed' => 'Trip completed',
      _ => 'Active Ride',
    };
  }

  IconData get _icon {
    final value = booking.status?.trim().toLowerCase();
    return switch (value) {
      'pending' => Icons.youtube_searched_for_rounded,
      'accepted' => Icons.local_taxi_rounded,
      'started' => Icons.navigation_rounded,
      _ => Icons.directions_car_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      _icon,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _statusText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        booking.pickupAddress ?? 'MG Road, Bengaluru',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.74),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Track',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.textPrimary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
