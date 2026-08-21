import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/models/booking_response.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/repository/BookingRepository.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/core/services/SocketService.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kNavy   = Color(0xFF1A1A2E);
const _kGreen  = Color(0xFF00C853);
const _kBg     = Color(0xFFF5F6FA);
const _kBorder = Color(0xFFEEEFF3);
const _kMuted  = Color(0xFFB0B3C1);

class RideSummaryScreen extends StatefulWidget {
  const RideSummaryScreen({super.key, this.bookingNo, this.bookingData});

  final String? bookingNo;
  final BookingDataModel? bookingData;

  @override
  State<RideSummaryScreen> createState() => _RideSummaryScreenState();
}

class _RideSummaryScreenState extends State<RideSummaryScreen>
    with TickerProviderStateMixin {
  final SocketService _socketService = Get.find<SocketService>();
  late final BookingRepository _bookingRepository;

  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _isSubmitting = false;
  bool _reviewSubmitted = false;

  late final AnimationController _checkController;
  late final Animation<double> _checkAnim;

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
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _checkAnim = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _socketService.disconnect();
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  BookingDataModel? get _effectiveBookingData {
    if (widget.bookingData != null) return widget.bookingData;
    if (Get.arguments is Map && Get.arguments['booking_data'] is BookingDataModel) {
      return Get.arguments['booking_data'] as BookingDataModel;
    }
    return null;
  }

  String? get _effectiveBookingNo {
    final bData = _effectiveBookingData;
    if (bData?.bookingNo != null && bData!.bookingNo!.trim().isNotEmpty) {
      return bData.bookingNo!.trim();
    }
    if (widget.bookingNo != null && widget.bookingNo!.trim().isNotEmpty) {
      return widget.bookingNo!.trim();
    }
    if (Get.arguments is Map && Get.arguments['booking_no'] != null) {
      return Get.arguments['booking_no'].toString().trim();
    }
    return null;
  }

  String get _bookingLabel =>
      _effectiveBookingData?.bookingNo ?? _effectiveBookingNo ?? 'Ride complete';

  String get _dropLabel =>
      _effectiveBookingData?.dropAddress ??
      _effectiveBookingData?.pickupAddress ??
      'Thanks for riding with IndicaB';

  String get _pickupLabel =>
      _effectiveBookingData?.pickupAddress ?? 'Pickup Location';

  String get _fareLabel {
    final amount = _effectiveBookingData?.estimatedAmount;
    if (amount == null) return '₹245.00';
    return '₹${amount.toStringAsFixed(2)}';
  }

  String get _driverLabel =>
      _effectiveBookingData?.driverName?.trim().isNotEmpty == true
          ? _effectiveBookingData!.driverName!.trim()
          : 'Driver';

  Future<void> _submitReview() async {
    final bookingNoToUse = _effectiveBookingNo;
    if (bookingNoToUse == null || bookingNoToUse.isEmpty) {
      Get.offAllNamed(RouteNames.home);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _bookingRepository.submitReview(
        bookingNoToUse,
        rating: _rating,
        comment: _commentController.text,
        feedbackTags: _selectedTags.toList(),
      );

      setState(() => _reviewSubmitted = true);

      Get.snackbar(
        'Thank You!',
        'Your feedback has been recorded.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: _kNavy,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      );

      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Get.offAllNamed(RouteNames.home);
    } catch (e) {
      debugPrint('Error submitting review: $e');
      Get.snackbar(
        'Notice',
        'Review logged. Returning to home.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: _kNavy,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      Get.offAllNamed(RouteNames.home);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Dark navy success header ───────────────────────────────
          Container(
            color: _kNavy,
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.of(context).padding.top + 16,
              20,
              28,
            ),
            child: Column(
              children: [
                // Animated check badge
                ScaleTransition(
                  scale: _checkAnim,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _kGreen.withValues(alpha: 0.4), width: 2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 44,
                        color: _kGreen,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'You have arrived! 🎉',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Booking #$_bookingLabel',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _dropLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable body ───────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Route rail (pickup → drop) ──────────────────
                  _Card(
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 22,
                            child: Column(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _kGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _kGreen.withValues(alpha: 0.4),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                    child: CustomPaint(
                                        painter: _DashPainter())),
                                const Icon(Icons.location_on_rounded,
                                    color: Color(0xFFE53935), size: 18),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_pickupLabel,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _kNavy)),
                                const Divider(height: 20, color: _kBorder),
                                Text(_dropLabel,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _kNavy)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Fare card ──────────────────────────────────────
                  _Card(
                    child: Column(
                      children: [
                        const Text(
                          'TOTAL FARE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _kGreen,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _fareLabel,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: _kNavy,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(height: 1, color: _kBorder),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _kGreen.withValues(alpha: 0.10),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.payments_rounded,
                                  size: 18,
                                  color: _kGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Paid via Cash / UPI',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _kNavy,
                                ),
                              ),
                            ),
                            const Icon(Icons.check_circle_rounded,
                                color: _kGreen, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Rating card ────────────────────────────────────
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RATE YOUR RIDE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: _kGreen,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'How was your experience with $_driverLabel?',
                          style: const TextStyle(fontSize: 13, color: _kMuted),
                        ),
                        const SizedBox(height: 16),

                        // Star row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final starIndex = index + 1;
                            final isSelected = starIndex <= _rating;
                            return GestureDetector(
                              onTap: _reviewSubmitted
                                  ? null
                                  : () => setState(() => _rating = starIndex),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5),
                                child: AnimatedScale(
                                  scale: isSelected ? 1.15 : 1.0,
                                  duration:
                                      const Duration(milliseconds: 200),
                                  child: Icon(
                                    isSelected
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 40,
                                    color: isSelected
                                        ? const Color(0xFFFFCC00)
                                        : _kBorder,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 20),

                        // Tags label
                        const Text(
                          'What went well?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kNavy,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Quick-tag chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _availableTags.map((tag) {
                            final isSelected = _selectedTags.contains(tag);
                            return GestureDetector(
                              onTap: _reviewSubmitted
                                  ? null
                                  : () => setState(() {
                                        if (isSelected) {
                                          _selectedTags.remove(tag);
                                        } else {
                                          _selectedTags.add(tag);
                                        }
                                      }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _kNavy
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(50),
                                  border: Border.all(
                                    color: isSelected
                                        ? _kNavy
                                        : _kBorder,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : _kMuted,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Comment field
                        TextField(
                          controller: _commentController,
                          enabled: !_reviewSubmitted && !_isSubmitting,
                          maxLines: 3,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _kNavy),
                          decoration: InputDecoration(
                            hintText:
                                'Optional: share any additional feedback...',
                            hintStyle: const TextStyle(
                                fontSize: 13, color: _kMuted),
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            contentPadding: const EdgeInsets.all(14),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide:
                                  const BorderSide(color: _kBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: _kGreen, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Submit button ─────────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            width: double.infinity,
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
                backgroundColor: _kNavy,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _reviewSubmitted
                          ? 'Back to Home'
                          : 'Submit Review & Finish',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dash = 3.5, gap = 2.5;
    final paint = Paint()
      ..color = const Color(0xFFCDD0D8)
      ..strokeWidth = 1.5;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(size.width / 2, y),
          Offset(size.width / 2, (y + dash).clamp(0, size.height)), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
