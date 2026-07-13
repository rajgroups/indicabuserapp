import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/models/booking_response.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/repository/BookingRepository.dart';
import 'package:indicab/core/network/network_exceptions.dart';

class RideOtpScreen extends StatefulWidget {
  const RideOtpScreen({
    super.key,
    this.bookingNo,
    this.bookingData,
    this.rideOtp,
    this.driverName,
    this.vehicleName,
    this.vehicleNumber,
  });

  final String? bookingNo;
  final BookingDataModel? bookingData;
  final String? rideOtp;
  final String? driverName;
  final String? vehicleName;
  final String? vehicleNumber;

  @override
  State<RideOtpScreen> createState() => _RideOtpScreenState();
}

class _RideOtpScreenState extends State<RideOtpScreen> {
  bool _isLoading = false;
  BookingDataModel? _bookingData;

  @override
  void initState() {
    super.initState();
    _bookingData = widget.bookingData;
    if (widget.bookingNo != null && widget.bookingNo!.isNotEmpty) {
      if (_bookingData == null) {
        _fetchBookingDetails();
      }
    }
  }

  Future<void> _fetchBookingDetails() async {
    setState(() {
      _isLoading = true;
    });

    final BookingRepository bookingRepository = BookingRepository(ApiClient());
    try {
      final response = await bookingRepository.getBooking(
        widget.bookingNo!,
        includeOtp: true,
      );
      final bookingData = response.data;
      if (bookingData != null && mounted) {
        setState(() {
          _bookingData = bookingData;
        });
      }
    } catch (e) {
      if (e is NetworkException && e.statusCode == 401) {
        return; // Handled by global handler
      }
      Get.snackbar(
        'Error',
        'Failed to fetch ride details: $e',
        backgroundColor: AppColors.surface,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _displayName(String? fallback) {
    final value = fallback?.trim();
    if (value == null || value.isEmpty) {
      return 'Waiting for driver details';
    }
    return value;
  }

  String _otpLabel(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Waiting for OTP from the server';
    }

    return value.trim().split('').join('  ');
  }

  String _vehicleLabel(String? vehicleName, String? vehicleNumber) {
    final parts = <String>[
      if (vehicleName != null && vehicleName.isNotEmpty) vehicleName,
      if (vehicleNumber != null && vehicleNumber.isNotEmpty) vehicleNumber,
    ];

    if (parts.isEmpty) {
      return 'Waiting for vehicle details';
    }

    return parts.join(' • ');
  }

  Future<void> _copyOtp() async {
    final otp = widget.rideOtp ?? _bookingData?.startOtp;
    if (otp == null || otp.isEmpty) {
      Get.snackbar(
        'Ride OTP',
        'OTP is not available yet',
        backgroundColor: AppColors.surface,
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: otp));
    Get.snackbar(
      'Ride OTP',
      'OTP copied to clipboard',
      backgroundColor: AppColors.surface,
    );
  }

  Future<void> _showCancelConfirmation() async {
    Get.dialog(
      AlertDialog(
        title: const Text('Cancel Ride'),
        content: const Text('Are you sure you want to cancel this ride?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('No')),
          TextButton(
            onPressed: () {
              Get.back(); // Close dialog

              Get.offAllNamed(RouteNames.home); // Go back to home
            },
            child: const Text('Yes, Cancel'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.authBackground,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text('Ride OTP'),
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Ride OTP',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _copyOtp,
            child: const Text(
              'Copy',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.borderSoft),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Share this OTP with the driver',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The driver needs this code to start the trip.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Ride OTP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _otpLabel(widget.rideOtp ?? _bookingData?.startOtp),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _MetaTile(
                    label: 'Driver',
                    value: _displayName(
                      widget.driverName ?? _bookingData?.driverName,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MetaTile(
                    label: 'Vehicle',
                    value: _vehicleLabel(
                      widget.vehicleName ?? _bookingData?.vehicleName,
                      widget.vehicleNumber ?? _bookingData?.vehicleNumber,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _MetaTile(
                    label: 'Status',
                    value: _bookingData?.status == null
                        ? 'Waiting for ride start'
                        : _bookingData!.status == 'accepted'
                            ? 'Waiting for ride start'
                            : _bookingData!.status == 'started'
                                ? 'Ride started'
                                : _bookingData!.status == 'completed'
                                    ? 'Ride completed'
                                    : _bookingData!.status!,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _copyOtp,
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
                  'Copy OTP',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _showCancelConfirmation,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Cancel Ride',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
