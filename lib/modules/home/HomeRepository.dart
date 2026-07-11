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
  }) async {
    final response = await _client.get(
      ApiEndpoints.vehicletype,
      queryParameters: {
        'page': page,
        'limit': limit,
        'search': search,
      },
    );

    return VehicleTypeResponse.fromJson(response.data);
  }
}