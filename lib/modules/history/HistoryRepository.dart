import 'package:indicab/core/models/booking_response.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/network/endpoints.dart';

class HistoryPaginatedResponse {
  HistoryPaginatedResponse({
    required this.bookings,
    required this.currentPage,
    required this.lastPage,
    required this.hasMore,
    required this.total,
  });

  final List<BookingDataModel> bookings;
  final int currentPage;
  final int lastPage;
  final bool hasMore;
  final int total;
}

class HistoryRepository {
  HistoryRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<HistoryPaginatedResponse> getBookingHistory(Map<String, dynamic> queryParams) async {
    final response = await _apiClient.get(
      ApiEndpoints.bookingsHistory,
      queryParameters: queryParams,
    );

    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      final dataList = payload['data'] as List<dynamic>? ?? [];
      final bookings = dataList
          .whereType<Map<String, dynamic>>()
          .map((json) => BookingDataModel.fromJson(json))
          .toList();

      final meta = payload['meta'] as Map<String, dynamic>? ?? {};
      final currentPage = meta['current_page'] as int? ?? 1;
      final lastPage = meta['last_page'] as int? ?? 1;
      final hasMore = meta['has_more'] as bool? ?? false;
      final total = meta['total'] as int? ?? bookings.length;

      return HistoryPaginatedResponse(
        bookings: bookings,
        currentPage: currentPage,
        lastPage: lastPage,
        hasMore: hasMore,
        total: total,
      );
    }

    throw Exception('Failed to fetch booking history.');
  }
}
