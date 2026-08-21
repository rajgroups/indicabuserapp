import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/models/booking_response.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/layout/app.dart';

import '../models/ride_history_item.dart';

const _kNavy   = Color(0xFF1A1A2E);
const _kGreen  = Color(0xFF00C853);
const _kRed    = Color(0xFFE53935);
const _kBg     = Color(0xFFF5F6FA);
const _kBorder = Color(0xFFEEEFF3);
const _kMuted  = Color(0xFFB0B3C1);

class RideDetailsScreen extends StatelessWidget {
  const RideDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rawArg = Get.arguments;

    BookingDataModel? bookingData;
    RideHistoryItem? rideItem;

    if (rawArg is BookingDataModel) {
      bookingData = rawArg;
    } else if (rawArg is RideHistoryItem) {
      rideItem = rawArg;
    }

    if (bookingData == null && rideItem == null) {
      return AppScreen(
        backgroundColor: _kBg,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: _kMuted),
              const SizedBox(height: 14),
              const Text('Ride details unavailable',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _kNavy)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: Get.back,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kNavy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back to History'),
              ),
            ],
          ),
        ),
      );
    }

    final category =
        bookingData?.categoryName ?? rideItem?.type ?? 'Ride';
    final amountText = bookingData != null
        ? (bookingData.estimatedAmount != null
            ? '₹${bookingData.estimatedAmount!.toStringAsFixed(2)}'
            : '₹0.00')
        : (rideItem?.amountLabel ?? '₹0.00');
    final amountValue =
        bookingData?.estimatedAmount ?? rideItem?.amountValue ?? 0.0;
    final dateLabel =
        bookingData?.scheduledAt ?? rideItem?.dateLabel ?? 'Recent';
    final pickup =
        bookingData?.pickupAddress ?? rideItem?.pickup ?? 'Pickup Address';
    final drop =
        bookingData?.dropAddress ?? rideItem?.drop ?? 'Drop Address';
    final status = bookingData?.status ?? rideItem?.status ?? 'Completed';
    final driverName =
        bookingData?.driverName ?? rideItem?.driverName ?? 'Assigned Driver';
    final vehicleNumber =
        bookingData?.vehicleNumber ?? rideItem?.vehicleNumber ?? 'N/A';
    final bookingId =
        bookingData?.bookingNo ?? rideItem?.bookingId ?? 'N/A';
    final paymentMethod =
        bookingData?.bookingMode ?? rideItem?.paymentMethod ?? 'UPI / Cash';

    return AppScreen(
      backgroundColor: _kBg,
      scrollable: true,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // ── Header bar ────────────────────────────────────────────────
          _RapidoBar(
            title: 'Ride Details',
            subtitle: 'Fare breakdown & trip summary',
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero card: category + amount ─────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _kNavy,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _kNavy.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.directions_car_filled_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              dateLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        amountText,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _kGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Status pill
                _StatusPill(status: status),
                const SizedBox(height: 18),

                // ── Route section ─────────────────────────────────────
                _CardSection(
                  title: 'Trip Route',
                  child: _RouteRail(pickup: pickup, drop: drop),
                ),
                const SizedBox(height: 14),

                // ── Ride summary ──────────────────────────────────────
                _CardSection(
                  title: 'Ride Summary',
                  child: Column(
                    children: [
                      _InfoRow(label: 'Status', value: status.toUpperCase(), accent: _kGreen),
                      _InfoRow(label: 'Rating', value: '4.9 / 5 ⭐'),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Driver & vehicle ──────────────────────────────────
                _CardSection(
                  title: 'Driver & Vehicle',
                  child: Column(
                    children: [
                      _InfoRow(label: 'Driver', value: driverName),
                      _InfoRow(label: 'Vehicle No.', value: vehicleNumber),
                      _InfoRow(label: 'Booking ID', value: '#$bookingId'),
                      _InfoRow(label: 'Payment', value: paymentMethod),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ── Fare breakdown ────────────────────────────────────
                _CardSection(
                  title: 'Fare Breakdown',
                  child: Column(
                    children: [
                      _InfoRow(
                          label: 'Base fare',
                          value:
                              '₹${(amountValue * 0.70).toStringAsFixed(0)}'),
                      _InfoRow(
                          label: 'Taxes & fees',
                          value:
                              '₹${(amountValue * 0.30).toStringAsFixed(0)}'),
                      const Divider(color: _kBorder),
                      _InfoRow(
                        label: 'Total paid',
                        value: amountText,
                        bold: true,
                        accent: _kNavy,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ── Action buttons ────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Get.snackbar(
                          'Receipt',
                          'Invoice saved to documents.',
                        ),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Invoice'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _kNavy,
                          side: const BorderSide(color: _kBorder, width: 1.5),
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Get.offAllNamed(RouteNames.home),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Book Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kNavy,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared header bar ────────────────────────────────────────────────────────
class _RapidoBar extends StatelessWidget {
  final String title;
  final String subtitle;
  const _RapidoBar({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFF3F4F6),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: Get.back,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Center(
                  child: Icon(Icons.arrow_back_rounded,
                      size: 20, color: _kNavy),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _kNavy)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, color: _kMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Status pill ───────────────────────────────────────────────────────────────
class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'completed':
        return _kGreen;
      case 'cancelled':
        return _kRed;
      default:
        return const Color(0xFF1565C0);
    }
  }

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: _color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: _color),
                const SizedBox(width: 6),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _color,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

// ── White card section ────────────────────────────────────────────────────────
class _CardSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _CardSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: _kGreen,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

// ── Rapido route rail ─────────────────────────────────────────────────────────
class _RouteRail extends StatelessWidget {
  final String pickup;
  final String drop;
  const _RouteRail({required this.pickup, required this.drop});

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 22,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _kGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: _kGreen.withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: CustomPaint(painter: _DashPainter())),
                  const Icon(Icons.location_on_rounded,
                      color: _kRed, size: 18),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pickup,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kNavy)),
                  const Divider(height: 20, color: _kBorder),
                  Text(drop,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kNavy)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? accent;
  const _InfoRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.accent,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: _kMuted)),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: accent ?? _kNavy,
              ),
            ),
          ],
        ),
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
