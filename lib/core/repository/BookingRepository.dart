import 'package:indicab/core/models/booking_request.dart';
import 'package:indicab/core/models/booking_response.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/network/endpoints.dart';

class BookingRepository {
  BookingRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<BookingResponseModel> createBooking(
    BookingCreateRequest request,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.bookings,
      data: request.toJson(),
    );

    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return BookingResponseModel.fromJson(payload);
    }

    throw Exception('Unexpected booking response format.');
  }

  Future<BookingResponseModel> getBooking(
    String bookingNo, {
    bool includeOtp = true,
  }) async {
    final response = await _apiClient.get(
      '${ApiEndpoints.bookings}/$bookingNo',
      queryParameters: {if (includeOtp) 'include_otp': 1},
    );

    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return BookingResponseModel.fromJson(payload);
    }

    throw Exception('Unexpected booking response format.');
  }

  Future<BookingResponseModel> retryBooking(String bookingNo) async {
    final response = await _apiClient.post(
      '${ApiEndpoints.bookings}/$bookingNo/retry',
    );

    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return BookingResponseModel.fromJson(payload);
    }

    throw Exception('Unexpected booking response format.');
  }

  Future<BookingResponseModel> getActiveRide() async {
    final response = await _apiClient.get(ApiEndpoints.bookingActive);

    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      return BookingResponseModel.fromJson(payload);
    }

    throw Exception('Unexpected booking response format.');
  }
}
