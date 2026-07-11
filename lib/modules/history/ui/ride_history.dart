import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/constants/Colors.dart';
import 'package:indicab/core/routes/names.dart';
import 'package:indicab/layout/app.dart';

import '../data/ride_history_data.dart';
import '../models/ride_history_item.dart';
import 'ride_history_filter.dart';
import 'invoice_screen.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  static const List<String> _dateFilters = [
    'All',
    'Today',
    'This Week',
    'This Month',
  ];

  late final List<String> _typeFilters;
  late final List<String> _paymentFilters;
  late final List<String> _statusFilters;
  String _selectedDateFilter = 'All';
  String _selectedTypeFilter = 'All';
  String _selectedPaymentFilter = 'All';
  String _selectedStatusFilter = 'All';
  RangeValues _selectedPriceRange = const RangeValues(0, 2000);
  String _selectedSortBy = 'Date: Newest';

  @override
  void initState() {
    super.initState();
    _typeFilters = [
      'All',
      ...{for (final ride in rideHistory) ride.type},
    ];
    _paymentFilters = [
      'All',
      ...{for (final ride in rideHistory) ride.paymentMethod},
    ];
    _statusFilters = [
      'All',
      ...{for (final ride in rideHistory) ride.status},
    ];
  }

  List<RideHistoryItem> get _filteredRides {
    final filtered = rideHistory.where((ride) {
      final dateMatch =
          _selectedDateFilter == 'All' || ride.periodTag == _selectedDateFilter;
      final typeMatch =
          _selectedTypeFilter == 'All' || ride.type == _selectedTypeFilter;
      final paymentMatch =
          _selectedPaymentFilter == 'All' ||
          ride.paymentMethod == _selectedPaymentFilter;
      final statusMatch =
          _selectedStatusFilter == 'All' || ride.status == _selectedStatusFilter;
      final priceMatch = ride.amountValue >= _selectedPriceRange.start &&
          ride.amountValue <= _selectedPriceRange.end;

      return dateMatch && typeMatch && paymentMatch && statusMatch && priceMatch;
    }).toList();

    if (_selectedSortBy == 'Price: High to Low') {
      filtered.sort((a, b) => b.amountValue.compareTo(a.amountValue));
    } else if (_selectedSortBy == 'Price: Low to High') {
      filtered.sort((a, b) => a.amountValue.compareTo(b.amountValue));
    } else if (_selectedSortBy == 'Date: Oldest') {
      return filtered.reversed.toList();
    }

    return filtered;
  }

  int get _activeFilterCount => [
    _selectedDateFilter != 'All',
    _selectedTypeFilter != 'All',
    _selectedPaymentFilter != 'All',
        _selectedStatusFilter != 'All',
        _selectedPriceRange.start > 0 || _selectedPriceRange.end < 2000,
        _selectedSortBy != 'Date: Newest',
  ].where((isActive) => isActive).length;

  void _resetFilters() {
    setState(() {
      _selectedDateFilter = 'All';
      _selectedTypeFilter = 'All';
      _selectedPaymentFilter = 'All';
      _selectedStatusFilter = 'All';
      _selectedPriceRange = const RangeValues(0, 2000);
      _selectedSortBy = 'Date: Newest';
    });
  }

  Future<void> _openFilters() async {
    final result = await Get.to<RideHistoryFilterResult>(
      () => RideHistoryFilterScreen(
        dateFilters: _dateFilters,
        typeFilters: _typeFilters,
        paymentFilters: _paymentFilters,
        initialDateFilter: _selectedDateFilter,
        initialTypeFilter: _selectedTypeFilter,
        initialPaymentFilter: _selectedPaymentFilter,
        statusFilters: _statusFilters,
        initialStatusFilter: _selectedStatusFilter,
        initialPriceRange: _selectedPriceRange,
        initialSortBy: _selectedSortBy,
      ),
      fullscreenDialog: true,
    );

    if (result == null) return;

    setState(() {
      _selectedDateFilter = result.dateFilter;
      _selectedTypeFilter = result.typeFilter;
      _selectedPaymentFilter = result.paymentFilter;
      _selectedStatusFilter = result.statusFilter;
      _selectedPriceRange = result.priceRange;
      _selectedSortBy = result.sortBy;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredRides = _filteredRides;
    final totalSpent = filteredRides.fold<double>(
      0,
      (sum, ride) => sum + ride.amountValue,
    );
    final averageRating = filteredRides.isEmpty
        ? 0.0
        : filteredRides.fold<double>(0, (sum, ride) => sum + ride.rating) /
              filteredRides.length;

    return AppScreen(
      backgroundColor: AppColors.authBackground,
      child: Column(
        children: [
          _HistoryHeader(
            onBack: Get.back,
            onOpenFilters: _openFilters,
            activeFilterCount: _activeFilterCount,
          ),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
              children: [
                _StatsCard(
                  totalRides: filteredRides.length,
                  totalSpent: totalSpent,
                  averageRating: averageRating,
                ),
                const SizedBox(height: 18),
                _FilterSummaryCard(
                  activeFilterCount: _activeFilterCount,
                  selectedDateFilter: _selectedDateFilter,
                  selectedTypeFilter: _selectedTypeFilter,
                  selectedPaymentFilter: _selectedPaymentFilter,
                  selectedStatusFilter: _selectedStatusFilter,
                  selectedPriceRange: _selectedPriceRange,
                  selectedSortBy: _selectedSortBy,
                  onReset: _resetFilters,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Recent trips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Filter by date, ride type or payment method, then open any trip for full details.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                if (filteredRides.isEmpty)
                  _EmptyFilterState(
                    onReset: _resetFilters,
                  )
                else
                  ...filteredRides.map(
                    (ride) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _RideHistoryCard(ride: ride),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 18,
            offset: Offset(0, 10),
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
                  'Applied filters',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (activeFilterCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$activeFilterCount active',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Tap the filter icon in the header to refine rides by date, vehicle type, or payment method.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (selectedSortBy != 'Date: Newest')
                _AppliedFilterChip(
                  label: 'Sort',
                  value: selectedSortBy,
                  icon: Icons.sort_rounded,
                ),
              if (selectedDateFilter != 'All')
                _AppliedFilterChip(
                  label: 'Date',
                  value: selectedDateFilter,
                  icon: Icons.calendar_month_rounded,
                ),
              if (selectedTypeFilter != 'All')
                _AppliedFilterChip(
                  label: 'Ride',
                  value: selectedTypeFilter,
                  icon: Icons.local_taxi_rounded,
                ),
              if (selectedStatusFilter != 'All')
                _AppliedFilterChip(
                  label: 'Status',
                  value: selectedStatusFilter,
                  icon: Icons.data_usage_rounded,
                ),
              if (selectedPaymentFilter != 'All')
                _AppliedFilterChip(
                  label: 'Payment',
                  value: selectedPaymentFilter,
                  icon: Icons.account_balance_wallet_rounded,
                ),
              if (selectedPriceRange.start > 0 || selectedPriceRange.end < 2000)
                _AppliedFilterChip(
                  label: 'Price',
                  value: '₹${selectedPriceRange.start.toInt()} - ₹${selectedPriceRange.end.toInt()}',
                  icon: Icons.payments_rounded,
                ),
              if (activeFilterCount == 0)
                const _AppliedFilterChip(
                  label: 'Filters',
                  value: 'None active',
                  icon: Icons.tune_rounded,
                ),
            ],
          ),
          const SizedBox(height: 18),
          if (activeFilterCount > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Clear filters'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryDark,
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
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
    final isDefault = value == 'None active';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDefault
            ? AppColors.inputFill
            : AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault ? AppColors.borderSoft : AppColors.primaryDark,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
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
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderSoft)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.inputFill,
              foregroundColor: AppColors.textPrimary,
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ride History',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your completed trips and receipts',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: onOpenFilters,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.inputFill,
                  foregroundColor: AppColors.textPrimary,
                ),
                icon: const Icon(Icons.tune_rounded),
              ),
              if (activeFilterCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryDark,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$activeFilterCount',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
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

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.filter_alt_off_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No rides match these filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try another date, ride type or payment method.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(onPressed: onReset, child: const Text('Reset filters')),
        ],
      ),
    );
  }
}

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
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7D6), Color(0xFFFBE9A4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(value: '$totalRides', label: 'Total rides'),
          ),
          Expanded(
            child: _StatItem(
              value: '₹${totalSpent.toStringAsFixed(0)}',
              label: 'Total spent',
            ),
          ),
          Expanded(
            child: _StatItem(
              value: '${averageRating.toStringAsFixed(1)}★',
              label: 'Avg rating',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _RideHistoryCard extends StatelessWidget {
  const _RideHistoryCard({required this.ride});

  final RideHistoryItem ride;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Get.toNamed(RouteNames.rideDetails, arguments: ride),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: ride.iconColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(ride.icon, color: ride.iconColor),
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
                                ride.type,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Text(
                              ride.amountLabel,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _MetaChip(
                              icon: Icons.schedule_rounded,
                              label: ride.dateLabel,
                            ),
                            _MetaChip(
                              icon: Icons.route_rounded,
                              label: ride.distance,
                            ),
                            _MetaChip(
                              icon: Icons.star_rounded,
                              label: ride.rating.toStringAsFixed(1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF2A9D8F),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Container(width: 2, height: 34, color: AppColors.border),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE76F51),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.pickup,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          ride.drop,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppColors.borderSoft, height: 1),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A9D8F).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      ride.status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2A9D8F),
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => Get.to(() => InvoiceScreen(ride: ride)),
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Invoice'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
