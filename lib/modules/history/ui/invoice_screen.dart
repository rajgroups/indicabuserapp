import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Strings.dart';
import '../models/ride_history_item.dart';

const _kNavy   = Color(0xFF1A1A2E);
const _kGreen  = Color(0xFF00C853);
const _kBg     = Color(0xFFF5F6FA);
const _kBorder = Color(0xFFEEEFF3);
const _kMuted  = Color(0xFFB0B3C1);

class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key, required this.ride});

  final RideHistoryItem ride;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Rapido-style top bar ──────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
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
                        child: Icon(Icons.close_rounded,
                            size: 20, color: _kNavy),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Tax Invoice',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _kNavy,
                  ),
                ),
              ],
            ),
          ),

          // ── Invoice body ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Invoice header (navy band) ─────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 24, horizontal: 24),
                          decoration: const BoxDecoration(
                            color: _kNavy,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                AppStrings.appName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _kGreen.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Text(
                                  'TAX INVOICE / RECEIPT',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _kGreen,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Invoice content ────────────────────────
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Meta row: date + booking ID
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetaBlock(
                                      icon: Icons.calendar_today_rounded,
                                      label: 'Date & Time',
                                      value: ride.dateLabel,
                                    ),
                                  ),
                                  Expanded(
                                    child: _MetaBlock(
                                      icon: Icons.confirmation_number_rounded,
                                      label: 'Booking ID',
                                      value: ride.bookingId,
                                      alignRight: true,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MetaBlock(
                                      icon: Icons.directions_car_rounded,
                                      label: 'Vehicle Type',
                                      value: ride.type,
                                    ),
                                  ),
                                  Expanded(
                                    child: _MetaBlock(
                                      icon: Icons.pin_rounded,
                                      label: 'Vehicle Number',
                                      value: ride.vehicleNumber,
                                      alignRight: true,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),
                              _SectionDivider(label: 'TRIP DETAILS'),
                              const SizedBox(height: 14),

                              // Route rail
                              _InvoiceRouteRail(
                                  pickup: ride.pickup, drop: ride.drop),
                              const SizedBox(height: 10),
                              Text(
                                'Distance: ${ride.distance}  •  Duration: ${ride.duration}',
                                style: const TextStyle(
                                    fontSize: 12, color: _kMuted),
                              ),

                              const SizedBox(height: 20),
                              _SectionDivider(label: 'FARE BREAKDOWN'),
                              const SizedBox(height: 14),

                              _FareRow(
                                  label: 'Ride Fare',
                                  value:
                                      '₹${(ride.amountValue * 0.85).toStringAsFixed(2)}'),
                              const SizedBox(height: 8),
                              _FareRow(
                                  label: 'Taxes & Fees (15%)',
                                  value:
                                      '₹${(ride.amountValue * 0.15).toStringAsFixed(2)}'),
                              const SizedBox(height: 16),
                              Container(height: 1.5, color: _kNavy),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'TOTAL AMOUNT',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        color: _kNavy,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₹${ride.amountValue.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: _kGreen,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),
                              Container(height: 1, color: _kBorder),
                              const SizedBox(height: 16),

                              // Footer
                              Center(
                                child: Text(
                                  'Paid via ${ride.paymentMethod}\nThank you for riding with ${AppStrings.appName}.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: _kMuted,
                                      height: 1.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      // ── Print FAB ─────────────────────────────────────────────────────
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomPad),
        child: FloatingActionButton.extended(
          onPressed: () => Get.snackbar('Saving',
              'Invoice saved to documents.'),
          icon: const Icon(Icons.print_rounded),
          label: const Text('Print / Save',
              style: TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: _kNavy,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _MetaBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool alignRight;
  const _MetaBlock({
    required this.icon,
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment:
            alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                alignRight ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!alignRight) ...[
                Icon(icon, size: 12, color: _kGreen),
                const SizedBox(width: 4),
              ],
              Text(label,
                  style: const TextStyle(fontSize: 11, color: _kMuted)),
              if (alignRight) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 12, color: _kGreen),
              ],
            ],
          ),
          const SizedBox(height: 3),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kNavy)),
        ],
      );
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(child: Container(height: 1, color: _kBorder)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: _kGreen,
                letterSpacing: 0.8,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: _kBorder)),
        ],
      );
}

class _InvoiceRouteRail extends StatelessWidget {
  final String pickup;
  final String drop;
  const _InvoiceRouteRail({required this.pickup, required this.drop});

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 20,
              child: Column(
                children: [
                  Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: _kGreen,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                  Expanded(child: CustomPaint(painter: _DashPainter())),
                  const Icon(Icons.location_on_rounded,
                      color: Color(0xFFE53935), size: 16),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pickup,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kNavy)),
                  const Divider(height: 18, color: _kBorder),
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

class _FareRow extends StatelessWidget {
  final String label;
  final String value;
  const _FareRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13, color: _kNavy))),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kNavy)),
        ],
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