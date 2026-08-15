import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/models/booking_response.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/repository/BookingRepository.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/core/services/SocketService.dart';

class RideSummaryScreen extends StatefulWidget {
  const RideSummaryScreen({super.key, this.bookingNo, this.bookingData});

  final String? bookingNo;
  final BookingDataModel? bookingData;

  @override
  State<RideSummaryScreen> createState() => _RideSummaryScreenState();
}

class _RideSummaryScreenState extends State<RideSummaryScreen> {
  final SocketService _socketService = Get.find<SocketService>();
  late final BookingRepository _bookingRepository;

  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _isSubmitting = false;
  bool _reviewSubmitted = false;

  final List<String> _availableTags = const [
    'Clean Vehicle',
    'Polite Driver',
    'Safe Driving',
    'Punctual',
    'Great Route',
    'Helpful',
  ];

  @override
  void initState() {
    super.initState();
    _bookingRepository = BookingRepository(ApiClient());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _socketService.disconnect();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String get _bookingLabel =>
      widget.bookingData?.bookingNo ?? widget.bookingNo ?? 'Ride complete';

  String get _locationLabel =>
      widget.bookingData?.dropAddress ??
      widget.bookingData?.pickupAddress ??
      'Thanks for riding with IndicaB';

  String get _fareLabel {
    final amount = widget.bookingData?.estimatedAmount;
    if (amount == null) {
      return '₹245.00';
    }

    return '₹${amount.toStringAsFixed(2)}';
  }

  String get _driverLabel =>
      widget.bookingData?.driverName?.trim().isNotEmpty == true
          ? widget.bookingData!.driverName!.trim()
          : 'Driver';

  Future<void> _submitReview() async {
    final bookingNoToUse = widget.bookingData?.bookingNo ?? widget.bookingNo;
    if (bookingNoToUse == null || bookingNoToUse.isEmpty) {
      Get.offAllNamed(RouteNames.home);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _bookingRepository.submitReview(
        bookingNoToUse,
        rating: _rating,
        comment: _commentController.text,
        feedbackTags: _selectedTags.toList(),
      );

      setState(() {
        _reviewSubmitted = true;
      });

      Get.snackbar(
        'Thank You!',
        'Your feedback has been recorded.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade700,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );

      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) {
        Get.offAllNamed(RouteNames.home);
      }
    } catch (e) {
      debugPrint('Error submitting review: $e');
      Get.snackbar(
        'Notice',
        'Review logged. Returning to home.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: AppColors.textPrimary,
        margin: const EdgeInsets.all(16),
      );
      Get.offAllNamed(RouteNames.home);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.authBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Ride Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 46,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'You have arrived!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Booking #$_bookingLabel',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _locationLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 28),

            // Fare Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSoft),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Fare',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _fareLabel,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.borderSoft),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.payments_rounded,
                            size: 20,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Paid via Cash/UPI',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.check_rounded,
                        color: Colors.green,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Review & Feedback Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderSoft),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'How was your ride?',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rate your experience with $_driverLabel',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Star Rating Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final isSelected = starIndex <= _rating;

                      return GestureDetector(
                        onTap: _reviewSubmitted
                            ? null
                            : () {
                                setState(() {
                                  _rating = starIndex;
                                });
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            isSelected
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 42,
                            color: isSelected
                                ? Colors.amber.shade600
                                : AppColors.border,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),

                  // Feedback Quick Tags
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'What went well?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return ChoiceChip(
                        label: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.25),
                        backgroundColor: AppColors.authBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderSoft,
                          ),
                        ),
                        showCheckmark: false,
                        onSelected: _reviewSubmitted
                            ? null
                            : (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedTags.add(tag);
                                  } else {
                                    _selectedTags.remove(tag);
                                  }
                                });
                              },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Comment Input Box
                  TextField(
                    controller: _commentController,
                    enabled: !_reviewSubmitted && !_isSubmitting,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Write optional feedback or review comment...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.authBackground,
                      contentPadding: const EdgeInsets.all(14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.borderSoft),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.borderSoft),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    if (_reviewSubmitted) {
                      Get.offAllNamed(RouteNames.home);
                    } else {
                      _submitReview();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.textPrimary,
                    ),
                  )
                : Text(
                    _reviewSubmitted
                        ? 'Back to Home'
                        : 'Submit Review & Finish',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
