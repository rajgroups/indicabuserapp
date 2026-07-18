import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/models/booking_request.dart';
import 'package:indicab/core/models/booking_response.dart';
import 'package:indicab/core/repository/BookingRepository.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/core/utils/Helpers.dart';
import 'package:indicab/modules/home/HomeController.dart';
import 'package:indicab/modules/home/models/VehicleModels.dart';
import 'package:indicab/core/services/SocketService.dart';
import 'package:indicab/core/network/network_exceptions.dart';

class BookingController extends GetxController {
  BookingController() : _repository = BookingRepository(ApiClient());

  final BookingRepository _repository;
  final HomeController _homeController = Get.find<HomeController>();
  final SocketService _socketService = Get.find<SocketService>();

  final RxBool isSubmitting = false.obs;
  final RxString selectedMode = ''.obs;

  Future<void> showBookingModeDialog(
    BuildContext context,
    VehicleOption option,
    VehicleSubCategory subCategory,
  ) async {
    await Get.dialog(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: option.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(option.icon, color: option.accentColor),
              ),
              const SizedBox(height: 16),
              Text(
                'Book ${option.label}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to ride with ${subCategory.name}.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              _ModeButton(
                title: 'Instant Ride',
                subtitle: 'Find and assign a driver now',
                accentColor: option.accentColor,
                onTap: () async {
                  Get.back();
                  await _submitBooking(
                    option: option,
                    subCategory: subCategory,
                    bookingMode: 'instant',
                  );
                },
              ),
              const SizedBox(height: 12),
              _ModeButton(
                title: 'Scheduled Ride',
                subtitle: 'Pick a date and time first',
                accentColor: option.accentColor,
                outlined: true,
                onTap: () async {
                  final scheduledAt = await _pickScheduledAt(context);
                  if (scheduledAt == null) {
                    return;
                  }

                  Get.back();
                  await _submitBooking(
                    option: option,
                    subCategory: subCategory,
                    bookingMode: 'scheduled',
                    scheduledAt: scheduledAt,
                  );
                },
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: Get.back,
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Color(0xFF5F5A52),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }

  Future<void> _submitBooking({
    required VehicleOption option,
    required VehicleSubCategory subCategory,
    required String bookingMode,
    String? scheduledAt,
  }) async {
    final request = _buildRequest(
      option: option,
      subCategory: subCategory,
      bookingMode: bookingMode,
      scheduledAt: scheduledAt,
    );

    try {
      isSubmitting.value = true;
      Helpers.loading();

      final BookingResponseModel response = await _repository.createBooking(
        request,
      );

      Helpers.close();

      if (!response.status) {
        Get.snackbar(
          'Booking',
          response.message.isNotEmpty
              ? response.message
              : 'Unable to create booking.',
          backgroundColor: Colors.white,
        );
        return;
      }

      if (bookingMode == 'instant') {
        await _socketService.ensureConnected();
        Get.toNamed(
          RouteNames.findingDriver,
          arguments: {
            'vehicle_type': option.label,
            'booking_no': response.data?.bookingNo,
            'booking_data': response.data,
          },
        );
        return;
      }

      Get.snackbar(
        'Booking confirmed',
        response.message.isNotEmpty
            ? response.message
            : 'Your ride has been scheduled.',
        backgroundColor: Colors.white,
      );
      Get.offAllNamed(RouteNames.home);
    } catch (error) {
      Helpers.close();
      if (error is NetworkException && error.statusCode == 401) {
        return;
      }
      Get.snackbar(
        'Booking failed',
        error.toString(),
        backgroundColor: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> openRideDetailsFromBookingNo(String bookingNo) async {
    try {
      isSubmitting.value = true;
      Helpers.loading();

      final BookingResponseModel response = await _repository.getBooking(
        bookingNo,
        includeOtp: true,
      );

      Helpers.close();

      final booking = response.data;
      if (booking == null) {
        throw Exception('Booking details not found.');
      }

      Get.offNamed(
        RouteNames.rideOtp,
        arguments: {'booking_no': booking.bookingNo, 'booking_data': booking},
      );
    } catch (error) {
      Helpers.close();
      if (error is NetworkException && error.statusCode == 401) {
        return;
      }
      Get.snackbar(
        'Ride updates',
        error.toString(),
        backgroundColor: Colors.white,
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  BookingCreateRequest _buildRequest({
    required VehicleOption option,
    required VehicleSubCategory subCategory,
    required String bookingMode,
    String? scheduledAt,
  }) {
    final pickupLocation =
        _homeController.pickuplocation.value ??
        _homeController.pickupPoint.value;
    final dropLocation = _homeController.droplocation.value;

    final locations = <BookingLocationRequest>[];
    locations.add(
      BookingLocationRequest(
        locationType: 'pickup',
        latitude: pickupLocation.latitude,
        longitude: pickupLocation.longitude,
        address: _homeController.pickupAddress.value.isNotEmpty
            ? _homeController.pickupAddress.value
            : _homeController.currentAddress.value,
        sequence: 1,
      ),
    );

    if (dropLocation != null &&
        (dropLocation.latitude != 0 || dropLocation.longitude != 0)) {
      locations.add(
        BookingLocationRequest(
          locationType: 'drop',
          latitude: dropLocation.latitude,
          longitude: dropLocation.longitude,
          address: _homeController.dropAddress.value.isNotEmpty
              ? _homeController.dropAddress.value
              : null,
          sequence: 2,
        ),
      );
    }

    return BookingCreateRequest(
      vehicleCategoryId: option.id,
      bookingMode: bookingMode,
      driverId: null,
      vehicleId: null,
      paymentMethod: 'cash',
      scheduledAt: scheduledAt,
      durationHours: null,
      locations: locations,
      usage: BookingUsageRequest(
        distanceKm: _estimateDistanceKm(),
        hoursUsed: _estimateHoursUsed(subCategory),
      ),
    );
  }

  double _estimateDistanceKm() {
    final pickup = _homeController.pickuplocation.value;
    final drop = _homeController.droplocation.value;

    if (pickup == null || drop == null) {
      return 0;
    }

    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(drop.latitude - pickup.latitude);
    final dLng = _degToRad(drop.longitude - pickup.longitude);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(pickup.latitude)) *
            math.cos(_degToRad(drop.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _estimateHoursUsed(VehicleSubCategory subCategory) {
    final etaDigits = RegExp(r'(\d+(\.\d+)?)').firstMatch(subCategory.eta);
    if (etaDigits != null) {
      return double.tryParse(etaDigits.group(1) ?? '') ?? 0;
    }
    return 0;
  }

  double _degToRad(double value) => value * 3.1415926535897932 / 180.0;

  Future<String?> _pickScheduledAt(BuildContext context) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (date == null) {
      return null;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.textPrimary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: AppColors.surface,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (time == null) {
      return null;
    }

    final scheduledDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    return _formatScheduledDateTime(scheduledDateTime);
  }

  String _formatScheduledDateTime(DateTime dateTime) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return [
          dateTime.year.toString().padLeft(4, '0'),
          twoDigits(dateTime.month),
          twoDigits(dateTime.day),
        ].join('-') +
        ' ' +
        [
          twoDigits(dateTime.hour),
          twoDigits(dateTime.minute),
          twoDigits(dateTime.second),
        ].join(':');
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
    this.outlined = false,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: outlined ? Colors.transparent : accentColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: outlined ? Colors.white : accentColor,
            borderRadius: BorderRadius.circular(20),
            border: outlined
                ? Border.all(color: accentColor.withValues(alpha: 0.25))
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: outlined
                      ? accentColor.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  outlined ? Icons.schedule_rounded : Icons.local_taxi_rounded,
                  color: outlined ? accentColor : Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: outlined ? Colors.black : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: outlined
                            ? const Color(0xFF5F5A52)
                            : Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
