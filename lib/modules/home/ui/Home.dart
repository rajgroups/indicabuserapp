import 'package:flutter/material.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/controller/BookingController.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/core/utils/Helpers.dart';
import 'package:get/get.dart';
import 'package:indicab/layout/app.dart';
import 'package:indicab/modules/vehicle/nearby.dart';
import 'package:indicab/shared/widgets/home/home_widgets.dart';
import 'package:indicab/modules/home/HomeController.dart';
import 'package:indicab/modules/home/models/VehicleModels.dart';
import 'package:indicab/core/models/booking_response.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController controller = Get.find<HomeController>();
  final ScrollController _vehicleListScrollController = ScrollController();

  @override
  void dispose() {
    _vehicleListScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final compact = width < 380;
    final vehicleHeight = compact ? 208.0 : 216.0;

    return AppScreen(
      backgroundColor: AppColors.authBackground,
      safeAreaBottom: false,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                const HomeMapArea(),
                DraggableScrollableSheet(
                  initialChildSize: compact ? 0.48 : 0.52,
                  minChildSize: compact ? 0.14 : 0.15,
                  maxChildSize: 0.92,
                  builder: (context, scrollController) {
                    return Container(
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
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: const BouncingScrollPhysics(),
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
                              const SizedBox(height: 16),
                              Obx(() {
                                final activeRide = controller.activeRide.value;
                                final status = activeRide?.status?.trim().toLowerCase();

                                if (activeRide == null ||
                                    status == 'completed' ||
                                    status == 'cancelled') {
                                  return const SizedBox.shrink();
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _ActiveRideFloatingCard(
                                    booking: activeRide,
                                    onTap: () {
                                      final status =
                                          activeRide.status?.trim().toLowerCase();
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
                                            'vehicle_type':
                                                activeRide.categoryName,
                                          },
                                        );
                                      } else if (status == 'accepted' ||
                                          status == 'arrived' ||
                                          status == 'started') {
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
                              HomeSearchBar(
                                onTap: () => Get.toNamed(
                                  RouteNames.locationSearch,
                                  arguments: <String, dynamic>{
                                    'target': controller.nextSelectionTarget ==
                                            LocationSelectionTarget.drop
                                        ? 'drop'
                                        : 'pickup',
                                  },
                                ),
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
                                    controller: _vehicleListScrollController,
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: controller.vehicleTypes.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 14),
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
                                          controller.selectVehicle(
                                            option,
                                          );
                                          _openVehicleSheet(context, option);
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
                              const SizedBox(height: 16),
                              GridView.count(
                                crossAxisCount: 4,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.85,
                                children: [
                                  _EssentialGridItem(
                                    icon: Icons.history_rounded,
                                    label: 'Recent',
                                    color: const Color(0xFF6C63FF),
                                    onTap: () =>
                                        Get.toNamed(RouteNames.rideHistory),
                                  ),
                                  _EssentialGridItem(
                                    icon: Icons.local_offer_rounded,
                                    label: 'Offers',
                                    color: const Color(0xFFFF6B35),
                                    onTap: () => Helpers.showComingSoon('Offers'),
                                  ),
                                  _EssentialGridItem(
                                    icon: Icons.schedule_rounded,
                                    label: 'Schedule',
                                    color: const Color(0xFF00B4D8),
                                    onTap: () => Helpers.showComingSoon('Schedule Ride'),
                                  ),
                                  _EssentialGridItem(
                                    icon: Icons.support_agent_rounded,
                                    label: 'Support',
                                    color: const Color(0xFF2ECC71),
                                    onTap: () => Helpers.showComingSoon('Customer Support'),
                                  ),
                                  _EssentialGridItem(
                                    icon: Icons.card_giftcard_rounded,
                                    label: 'Rewards',
                                    color: const Color(0xFFFFCC00),
                                    onTap: () => Helpers.showComingSoon('Rewards & Loyalty'),
                                  ),
                                  _EssentialGridItem(
                                    icon: Icons.location_on_rounded,
                                    label: 'Saved',
                                    color: const Color(0xFFE91E63),
                                    onTap: () => Helpers.showComingSoon('Saved Places'),
                                  ),
                                  _EssentialGridItem(
                                    icon: Icons.receipt_long_rounded,
                                    label: 'Invoices',
                                    color: const Color(0xFF607D8B),
                                    onTap: () =>
                                        Get.toNamed(RouteNames.rideHistory),
                                  ),
                                  _EssentialGridItem(
                                    icon: Icons.share_rounded,
                                    label: 'Refer',
                                    color: const Color(0xFF9C27B0),
                                    onTap: () => Helpers.showComingSoon('Refer & Earn'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              const HomePromoBanner(),
                              const SizedBox(height: 28),
                              const HomeSectionTitle(
                                title: 'Saved Places',
                                subtitle:
                                    'Quickly book your most common routes',
                              ),
                              const SizedBox(height: 16),
                              GridView.count(
                                crossAxisCount: 4,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.85,
                                children: [
                                  _EssentialGridItem(
                                    icon: Icons.home_rounded,
                                    label: 'Home',
                                    color: const Color(0xFF2196F3),
                                    onTap: () => Helpers.showComingSoon('Saved Home Location'),
                                  ),
                                  _EssentialGridItem(
                                    icon: Icons.work_rounded,
                                    label: 'Work',
                                    color: const Color(0xFF607D8B),
                                    onTap: () => Helpers.showComingSoon('Saved Work Location'),
                                  ),
                                  _EssentialGridItem(
                                    icon: Icons.flight_rounded,
                                    label: 'Airport',
                                    color: const Color(0xFF00BCD4),
                                    onTap: () => Helpers.showComingSoon('Airport Rides'),
                                  ),
                                  _EssentialGridItem(
                                    icon: Icons.add_location_alt_rounded,
                                    label: 'Add New',
                                    color: const Color(0xFF4CAF50),
                                    onTap: () => Get.toNamed(
                                      RouteNames.locationSearch,
                                      arguments: <String, dynamic>{
                                        'target': controller.nextSelectionTarget ==
                                                LocationSelectionTarget.drop
                                            ? 'drop'
                                            : 'pickup',
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => Get.toNamed(
                                    RouteNames.locationSearch,
                                    arguments: <String, dynamic>{
                                      'target': controller.nextSelectionTarget ==
                                              LocationSelectionTarget.drop
                                          ? 'drop'
                                          : 'pickup',
                                    },
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 2),
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
                    );
                  },
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

  Future<void> _openVehicleSheet(
    BuildContext context,
    VehicleOption option,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (sheetContext2, scrollController) {
            final hasDrop = controller.droplocation.value != null;
            final distKm = controller.calculateDistanceKm();

            return VehicleDetailsSheet(
              option: option,
              scrollController: scrollController,
              hasDropLocation: hasDrop,
              distanceKm: distKm,
              onSelect: (subCategory) {
                // Dismiss the bottom sheet first
                Navigator.of(sheetContext).pop();
                // Show the booking mode dialog after the sheet is fully dismissed
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final ctx = Get.context;
                  if (ctx == null) return;
                  final bookingController =
                      Get.isRegistered<BookingController>()
                      ? Get.find<BookingController>()
                      : Get.put<BookingController>(BookingController());
                  bookingController.showBookingModeDialog(
                    ctx,
                    option,
                    subCategory,
                  );
                });
              },
              onMapTap: (subCategory) {
                Navigator.of(sheetContext).pop();
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

class _EssentialGridItem extends StatelessWidget {
  const _EssentialGridItem({
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
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
                    child: Icon(_icon, color: AppColors.primary, size: 24),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
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
