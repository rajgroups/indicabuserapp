import 'package:indicab/core/models/Vehicle.dart';
import 'package:indicab/core/models/NearbyVehicle.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/network/endpoints.dart';

class VehicleRespository {
  final ApiClient _apiService;

  VehicleRespository(this._apiService);

  Future<List<NearbyVehicle>> getNearbyVehicles({
    required int vehicleCategoryId,
    required double latitude,
    required double longitude,
    double radius = 5.0,
  }) async {
    final Map<String, dynamic> queryParameters = {
      'vehicle_category_id': vehicleCategoryId,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };

    final response = await _apiService.get(
      '/vehicles/nearby',
      queryParameters: queryParameters,
    );

    final List data = response.data['data']['vehicles'] ?? [];

    return data
        .map((e) => NearbyVehicle.fromJson(e))
        .toList();
  }

  Future<List<VehicleModel>>  getTypeVehicles({
    double lat = 1,
    double lng = 10,
    int radius = 400,
    int? category,
    String? search,
  }) async {
    final Map<String, dynamic> queryParameters = {
      'lat': lat,
      'lng': lng,
      'radius': radius,
    };

    if (category != null) queryParameters['category'] = category;
    if (search != null && search.isNotEmpty) queryParameters['search'] = search;

    final response = await _apiService.get(
      ApiEndpoints.vehicletypelist,
      queryParameters: queryParameters,
    );

  final List data = response.data['data'];

  return data
      .map((e) => VehicleModel.fromJson(e))
      .toList();
  }
}