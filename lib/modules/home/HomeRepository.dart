import 'package:dio/dio.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/network/endpoints.dart';
import 'package:indicab/modules/home/models/VehicleTypeResponse.dart';

class VehicleCategoryRepository {
  final ApiClient _client = ApiClient();

  Future<VehicleTypeResponse> getAllvehicleCategory({
    int page = 1,
    int limit = 10,
    String? search,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    double? distanceKm,
  }) async {
    final Map<String, dynamic> queryParameters = {
      'page': page,
      'limit': limit,
      if (search != null && search.isNotEmpty) 'search': search,
      if (pickupLat != null) 'pickup_lat': pickupLat,
      if (pickupLng != null) 'pickup_lng': pickupLng,
      if (dropLat != null) 'drop_lat': dropLat,
      if (dropLng != null) 'drop_lng': dropLng,
      if (distanceKm != null && distanceKm > 0) 'distance_km': distanceKm,
    };

    final response = await _client.get(
      ApiEndpoints.vehicletype,
      queryParameters: queryParameters,
    );

    return VehicleTypeResponse.fromJson(response.data);
  }
}