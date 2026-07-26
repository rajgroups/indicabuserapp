import 'package:indicab/core/models/sos_alert_model.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/network/endpoints.dart';

class SosRepository {
  SosRepository(this._apiClient);

  final ApiClient _apiClient;

  /// Trigger an SOS alert for an active booking.
  ///
  /// [bookingNo] — the booking's unique identifier (ulid)
  /// [type]      — one of: police | ambulance | emergency_contact | safety_team
  /// [latitude]  — optional current latitude
  /// [longitude] — optional current longitude
  /// [message]   — optional extra context
  Future<SosAlertModel> sendSosAlert({
    required String bookingNo,
    required String type,
    double? latitude,
    double? longitude,
    String? message,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.bookingSos(bookingNo),
      data: {
        'type': type,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (message != null && message.isNotEmpty) 'message': message,
      },
    );

    final payload = response.data;
    if (payload is Map<String, dynamic> && payload['data'] != null) {
      return SosAlertModel.fromJson(payload['data'] as Map<String, dynamic>);
    }

    throw Exception('Unexpected SOS response format.');
  }

  /// Fetch all SOS alerts for a booking.
  Future<List<SosAlertModel>> getSosAlerts(String bookingNo) async {
    final response = await _apiClient.get(
      ApiEndpoints.bookingSos(bookingNo),
    );

    final payload = response.data;
    if (payload is Map<String, dynamic> && payload['data'] is List) {
      return (payload['data'] as List)
          .map((e) => SosAlertModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }
}
