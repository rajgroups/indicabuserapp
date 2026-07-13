import 'package:get/get.dart';
import 'package:indicab/core/bindings/AuthBinding.dart';
import 'package:indicab/core/bindings/HomeBinding.dart';
import 'package:indicab/layout/partials/menu.dart';
import 'package:indicab/modules/auth/ui/login.dart';
import 'package:indicab/modules/auth/ui/otp.dart';
import 'package:indicab/core/models/booking_response.dart';
import 'package:indicab/modules/history/ui/ride_details.dart';
import 'package:indicab/modules/history/ui/ride_history.dart';
import 'package:indicab/modules/home/ui/Home.dart';
import 'package:indicab/modules/home/ui/LocationSearchScreen.dart';
import 'package:indicab/modules/ride/ui/ActiveRideScreen.dart';
import 'package:indicab/modules/ride/ui/FindingDriverScreen.dart';
import 'package:indicab/modules/ride/ui/ride_otp_screen.dart';
import 'package:indicab/modules/ride/ui/ride_summary_screen.dart';
import 'names.dart';

class AppRoutes {
  static const initial = RouteNames.login;

  static final pages = [
    GetPage(
      name: RouteNames.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: RouteNames.otp,
      page: () => const OtpScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: RouteNames.home,
      page: () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: RouteNames.locationSearch,
      page: () => const LocationSearchScreen(),
    ),
    GetPage(
      name: RouteNames.findingDriver,
      page: () => FindingDriverScreen(
        vehicleType: Get.arguments is Map<String, dynamic>
            ? Get.arguments['vehicle_type']?.toString()
            : null,
      ),
    ),
    GetPage(
      name: RouteNames.rideOtp,
      page: () => RideOtpScreen(
        bookingNo: Get.arguments is Map<String, dynamic>
            ? Get.arguments['booking_no']?.toString()
            : null,
        bookingData: Get.arguments is Map<String, dynamic>
            ? Get.arguments['booking_data'] as BookingDataModel?
            : null,
      ),
    ),
    GetPage(
      name: RouteNames.activeRide,
      page: () => ActiveRideScreen(
        bookingNo: Get.arguments is Map<String, dynamic>
            ? Get.arguments['booking_no']?.toString()
            : null,
        bookingData: Get.arguments is Map<String, dynamic>
            ? Get.arguments['booking_data'] as BookingDataModel?
            : null,
      ),
    ),
    GetPage(
      name: RouteNames.rideSummary,
      page: () => RideSummaryScreen(
        bookingNo: Get.arguments is Map<String, dynamic>
            ? Get.arguments['booking_no']?.toString()
            : null,
        bookingData: Get.arguments is Map<String, dynamic>
            ? Get.arguments['booking_data'] as BookingDataModel?
            : null,
      ),
    ),
    GetPage(
      name: RouteNames.rideHistory,
      page: () => const RideHistoryScreen(),
    ),
    GetPage(
      name: RouteNames.rideDetails,
      page: () => const RideDetailsScreen(),
    ),
    GetPage(name: RouteNames.menu, page: () => const ProfileScreen()),
  ];
}
