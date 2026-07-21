import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:indicab/core/models/booking_response.dart';
import 'HistoryService.dart';

class HistoryController extends GetxController {
  HistoryController();

  final HistoryService _historyService = HistoryService();

  final RxList<BookingDataModel> bookings = <BookingDataModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = false.obs;

  int _currentPage = 1;
  final int perPage = 15;

  // Filter States
  final RxString selectedStatusTab = 'All'.obs; // All, Ongoing, Completed, Cancelled, Missed
  final RxString selectedDateFilter = 'All'.obs; // All, Today, This Week, This Month
  final RxString selectedTypeFilter = 'All'.obs;
  final RxString selectedPaymentFilter = 'All'.obs;
  final Rx<RangeValues> selectedPriceRange = const RangeValues(0, 2000).obs;
  final RxString selectedSortBy = 'Date: Newest'.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
  }

  /// Convert tab label to status query parameter for API
  String _mapTabToStatusParam(String tab) {
    switch (tab.toLowerCase()) {
      case 'ongoing':
        return 'ongoing';
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      case 'missed':
        return 'missed';
      default:
        return 'all';
    }
  }

  /// Map sort label to query parameter
  String _mapSortByParam(String sort) {
    switch (sort) {
      case 'Price: High to Low':
        return 'amount_high';
      case 'Price: Low to High':
        return 'amount_low';
      case 'Date: Oldest':
        return 'oldest';
      default:
        return 'newest';
    }
  }

  Map<String, dynamic> _buildQueryParams({required int page}) {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      'status': _mapTabToStatusParam(selectedStatusTab.value),
      'sort_by': _mapSortByParam(selectedSortBy.value),
    };

    if (selectedDateFilter.value != 'All') {
      params['date_filter'] = selectedDateFilter.value.toLowerCase().replaceAll(' ', '_');
    }

    if (selectedPaymentFilter.value != 'All') {
      params['payment_method'] = selectedPaymentFilter.value.toLowerCase();
    }

    if (searchQuery.value.trim().isNotEmpty) {
      params['search'] = searchQuery.value.trim();
    }

    return params;
  }

  Future<void> fetchHistory({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      hasMore.value = false;
    } else {
      isLoading.value = true;
    }

    try {
      final response = await _historyService.fetchBookingHistory(
        _buildQueryParams(page: 1),
      );

      _currentPage = response.currentPage;
      hasMore.value = response.hasMore;
      bookings.assignAll(response.bookings);
    } catch (e) {
      debugPrint('HistoryController.fetchHistory error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    final nextPage = _currentPage + 1;

    try {
      final response = await _historyService.fetchBookingHistory(
        _buildQueryParams(page: nextPage),
      );

      _currentPage = response.currentPage;
      hasMore.value = response.hasMore;
      bookings.addAll(response.bookings);
    } catch (e) {
      debugPrint('HistoryController.loadMore error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void changeStatusTab(String tab) {
    if (selectedStatusTab.value == tab) return;
    selectedStatusTab.value = tab;
    fetchHistory(refresh: true);
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    fetchHistory(refresh: true);
  }

  void resetFilters() {
    selectedDateFilter.value = 'All';
    selectedTypeFilter.value = 'All';
    selectedPaymentFilter.value = 'All';
    selectedPriceRange.value = const RangeValues(0, 2000);
    selectedSortBy.value = 'Date: Newest';
    searchQuery.value = '';
    fetchHistory(refresh: true);
  }

  int get activeFilterCount {
    int count = 0;
    if (selectedDateFilter.value != 'All') count++;
    if (selectedTypeFilter.value != 'All') count++;
    if (selectedPaymentFilter.value != 'All') count++;
    if (selectedPriceRange.value.start > 0 || selectedPriceRange.value.end < 2000) count++;
    if (selectedSortBy.value != 'Date: Newest') count++;
    if (searchQuery.value.trim().isNotEmpty) count++;
    return count;
  }

  int get totalRides => bookings.length;

  double get totalSpent {
    return bookings.fold<double>(
      0,
      (sum, booking) => sum + (booking.estimatedAmount ?? 0.0),
    );
  }

  double get averageRating => 4.85;
}
