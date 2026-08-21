import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/models/booking_response.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/layout/app.dart';

import '../HistoryController.dart';
import 'ride_history_filter.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  late final HistoryController _controller;
  final ScrollController _scrollController = ScrollController();

  static const List<String> _dateFilters = [
    'All',
    'Today',
    'This Week',
    'This Month',
  ];

  static const List<String> _statusTabs = [
    'All',
    'Ongoing',
    'Completed',
    'Cancelled',
    'Missed',
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.put(HistoryController());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _controller.loadMore();
    }
  }

  Future<void> _openFilters() async {
    final result = await Get.to<RideHistoryFilterResult>(
      () => RideHistoryFilterScreen(
        dateFilters: _dateFilters,
        typeFilters: const ['All', 'Cab', 'Auto', 'Bike', 'Parcel'],
        paymentFilters: const ['All', 'cash', 'upi', 'card', 'wallet'],
        initialDateFilter: _controller.selectedDateFilter.value,
        initialTypeFilter: _controller.selectedTypeFilter.value,
        initialPaymentFilter: _controller.selectedPaymentFilter.value,
        statusFilters: _statusTabs,
        initialStatusFilter: _controller.selectedStatusTab.value,
        initialPriceRange: _controller.selectedPriceRange.value,
        initialSortBy: _controller.selectedSortBy.value,
      ),
      fullscreenDialog: true,
    );

    if (result == null) return;

    _controller.selectedDateFilter.value = result.dateFilter;
    _controller.selectedTypeFilter.value = result.typeFilter;
    _controller.selectedPaymentFilter.value = result.paymentFilter;
    _controller.selectedPriceRange.value = result.priceRange;
    _controller.selectedSortBy.value = result.sortBy;

    if (result.statusFilter != _controller.selectedStatusTab.value) {
      _controller.selectedStatusTab.value = result.statusFilter;
    }

    _controller.fetchHistory(refresh: true);
  }

  void _onBookingTap(BookingDataModel booking) {
    final status = booking.status?.trim().toLowerCase() ?? '';

    if (status == 'accepted' || status == 'arrived' || status == 'started') {
      Get.offAllNamed(
        RouteNames.activeRide,
        arguments: <String, dynamic>{
          'booking_no': booking.bookingNo,
          'booking_data': booking,
        },
      );
      return;
    }

    if (status == 'pending' || status == 'requested') {
      Get.offAllNamed(
        RouteNames.findingDriver,
        arguments: <String, dynamic>{
          'booking_no': booking.bookingNo,
          'booking_data': booking,
          'vehicle_type': booking.categoryName,
        },
      );
      return;
    }

    Get.toNamed(RouteNames.rideDetails, arguments: booking);
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      backgroundColor: const Color(0xFFF5F6FA),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Obx(() => _HistoryHeader(
                onBack: Get.back,
                onOpenFilters: _openFilters,
                activeFilterCount: _controller.activeFilterCount,
              )),

          // ── Status pill tabs ─────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Obx(
                () => Row(
                  children: _statusTabs.map((tab) {
                    final selected =
                        _controller.selectedStatusTab.value == tab;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _StatusPillTab(
                        label: tab,
                        selected: selected,
                        onTap: () => _controller.changeStatusTab(tab),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Container(height: 1, color: const Color(0xFFEEEFF3)),

          // ── Main list ────────────────────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _controller.fetchHistory(refresh: true),
              color: const Color(0xFF00C853),
              child: Obx(() {
                if (_controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF1A1A2E),
                    ),
                  );
                }

                final bookingsList = _controller.bookings;

                return ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
                  itemCount: bookingsList.isEmpty
                      ? 3
                      : bookingsList.length +
                          3 +
                          (_controller.isLoadingMore.value ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _StatsCard(
                        totalRides: _controller.totalRides,
                        totalSpent: _controller.totalSpent,
                        averageRating: _controller.averageRating,
                      );
                    }

                    if (index == 1) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16, bottom: 12),
                        child: _FilterSummaryCard(
                          activeFilterCount: _controller.activeFilterCount,
                          selectedDateFilter:
                              _controller.selectedDateFilter.value,
                          selectedTypeFilter:
                              _controller.selectedTypeFilter.value,
                          selectedPaymentFilter:
                              _controller.selectedPaymentFilter.value,
                          selectedStatusFilter:
                              _controller.selectedStatusTab.value,
                          selectedPriceRange:
                              _controller.selectedPriceRange.value,
                          selectedSortBy: _controller.selectedSortBy.value,
                          onReset: _controller.resetFilters,
                        ),
                      );
                    }

                    if (index == 2) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Trips (${_controller.selectedStatusTab.value})',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                            Obx(() => Text(
                                  '${_controller.bookings.length} found',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFB0B3C1),
                                  ),
                                )),
                          ],
                        ),
                      );
                    }

                    if (bookingsList.isEmpty) {
                      return _EmptyFilterState(
                          onReset: _controller.resetFilters);
                    }

                    final bookingIndex = index - 3;
                    if (bookingIndex < bookingsList.length) {
                      final booking = bookingsList[bookingIndex];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _RideBookingCard(
                          booking: booking,
                          onTap: () => _onBookingTap(booking),
                        ),
                      );
                    }

                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rapido-style status pill tab ───────────────────────────────────────────────
class _StatusPillTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StatusPillTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(50),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF5C5E6E),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.onBack,
    required this.onOpenFilters,
    required this.activeFilterCount,
  });

  final VoidCallback onBack;
  final VoidCallback onOpenFilters;
  final int activeFilterCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          Material(
            color: const Color(0xFFF3F4F6),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onBack,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Center(
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ride History',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Your ongoing & past trips',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFB0B3C1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Filter button with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: const Color(0xFFF3F4F6),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onOpenFilters,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Center(
                      child: Icon(
                        Icons.tune_rounded,
                        size: 20,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                  ),
                ),
              ),
              if (activeFilterCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$activeFilterCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stats card ────────────────────────────────────────────────────────────────
class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.totalRides,
    required this.totalSpent,
    required this.averageRating,
  });

  final int totalRides;
  final double totalSpent;
  final double averageRating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              value: '$totalRides',
              label: 'Total Rides',
              accent: const Color(0xFF00C853),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.12)),
          Expanded(
            child: _StatItem(
              value: '₹${totalSpent.toStringAsFixed(0)}',
              label: 'Total Spent',
              accent: const Color(0xFFFFCC00),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.12)),
          Expanded(
            child: _StatItem(
              value: '${averageRating.toStringAsFixed(1)}★',
              label: 'Avg Rating',
              accent: const Color(0xFFE53935),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: accent,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

// ── Filter summary card ───────────────────────────────────────────────────────
class _FilterSummaryCard extends StatelessWidget {
  const _FilterSummaryCard({
    required this.activeFilterCount,
    required this.selectedDateFilter,
    required this.selectedTypeFilter,
    required this.selectedPaymentFilter,
    required this.selectedStatusFilter,
    required this.selectedPriceRange,
    required this.selectedSortBy,
    required this.onReset,
  });

  final int activeFilterCount;
  final String selectedDateFilter;
  final String selectedTypeFilter;
  final String selectedPaymentFilter;
  final String selectedStatusFilter;
  final RangeValues selectedPriceRange;
  final String selectedSortBy;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEEEFF3)),
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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Applied Filters',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
              if (activeFilterCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    '$activeFilterCount active',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AppliedFilterChip(
                  label: 'Status',
                  value: selectedStatusFilter,
                  icon: Icons.data_usage_rounded),
              if (selectedSortBy != 'Date: Newest')
                _AppliedFilterChip(
                    label: 'Sort',
                    value: selectedSortBy,
                    icon: Icons.sort_rounded),
              if (selectedDateFilter != 'All')
                _AppliedFilterChip(
                    label: 'Date',
                    value: selectedDateFilter,
                    icon: Icons.calendar_month_rounded),
              if (selectedPaymentFilter != 'All')
                _AppliedFilterChip(
                    label: 'Payment',
                    value: selectedPaymentFilter,
                    icon: Icons.account_balance_wallet_rounded),
            ],
          ),
          if (activeFilterCount > 0) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onReset,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.restart_alt_rounded,
                      size: 14, color: const Color(0xFFE53935)),
                  const SizedBox(width: 4),
                  const Text(
                    'Clear all filters',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFE53935),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppliedFilterChip extends StatelessWidget {
  const _AppliedFilterChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: const Color(0xFFEEEFF3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF5C5E6E)),
          const SizedBox(width: 5),
          Text(
            '$label: $value',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEFF3)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.filter_alt_off_rounded,
                color: Color(0xFFB0B3C1),
                size: 26,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No trips found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try selecting another filter or create a new booking.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFB0B3C1),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onReset,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1A1A2E),
            ),
            child: const Text(
              'Reset filters',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ride booking card (Rapido-style) ──────────────────────────────────────────
class _RideBookingCard extends StatelessWidget {
  const _RideBookingCard({
    required this.booking,
    required this.onTap,
  });

  final BookingDataModel booking;
  final VoidCallback onTap;

  Color get _statusColor {
    final status = booking.status?.trim().toLowerCase() ?? '';
    switch (status) {
      case 'accepted':
      case 'arrived':
      case 'started':
      case 'pending':
      case 'requested':
        return const Color(0xFF1565C0);
      case 'completed':
        return const Color(0xFF00C853);
      case 'cancelled':
        return const Color(0xFFE53935);
      case 'expired':
      case 'no_driver_available':
        return const Color(0xFFFF8F00);
      default:
        return const Color(0xFFB0B3C1);
    }
  }

  String get _statusLabel {
    final status = booking.status?.trim().toLowerCase() ?? '';
    switch (status) {
      case 'accepted':
        return 'Driver Accepted';
      case 'arrived':
        return 'Driver Arrived';
      case 'started':
        return 'Ride Started';
      case 'pending':
      case 'requested':
        return 'Finding Driver';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'expired':
      case 'no_driver_available':
        return 'Missed';
      default:
        return status;
    }
  }

  bool get _isOngoing {
    final status = booking.status?.trim().toLowerCase() ?? '';
    return ['accepted', 'arrived', 'started', 'pending', 'requested']
        .contains(status);
  }

  @override
  Widget build(BuildContext context) {
    final category = booking.categoryName ?? 'Ride';
    final amount = booking.estimatedAmount != null
        ? '₹${booking.estimatedAmount!.toStringAsFixed(0)}'
        : '₹0';
    final pickup = booking.pickupAddress ?? 'Pickup Location';
    final drop = booking.dropAddress ?? 'Drop Location';
    final bookingNo = booking.bookingNo ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isOngoing
                  ? const Color(0xFF1A1A2E).withValues(alpha: 0.30)
                  : const Color(0xFFEEEFF3),
              width: _isOngoing ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Top row: vehicle icon + name/status + amount ──────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        _isOngoing
                            ? Icons.directions_car_filled_rounded
                            : Icons.local_taxi_rounded,
                        color: _statusColor,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                            ),
                            Text(
                              amount,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            // Status badge pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: _statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                _statusLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _statusColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '#$bookingNo',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFB0B3C1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: _isOngoing
                        ? const Color(0xFF1A1A2E)
                        : const Color(0xFFB0B3C1),
                    size: 22,
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Container(height: 1, color: const Color(0xFFEEEFF3)),
              const SizedBox(height: 14),

              // ── Rapido route row ──────────────────────────────────────
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Left rail: green dot → dashed line → red teardrop
                    SizedBox(
                      width: 20,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C853),
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00C853)
                                      .withValues(alpha: 0.35),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: CustomPaint(
                              painter: _DashedLinePainter(),
                            ),
                          ),
                          const Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFFE53935),
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Right: pickup + destination text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pickup,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Divider(
                            height: 16,
                            thickness: 1,
                            color: const Color(0xFFEEEFF3),
                          ),
                          Text(
                            drop,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Ongoing ride CTA ──────────────────────────────────────
              if (_isOngoing) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.navigation_rounded,
                          size: 14, color: Color(0xFF00C853)),
                      SizedBox(width: 6),
                      Text(
                        'Tap to view live tracking',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Dashed vertical connector line
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashH = 3.5;
    const gapH = 2.5;
    final paint = Paint()
      ..color = const Color(0xFFCDD0D8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, (y + dashH).clamp(0, size.height)),
        paint,
      );
      y += dashH + gapH;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
