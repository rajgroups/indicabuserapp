import 'package:indicab/modules/home/HomeRepository.dart';
import 'package:indicab/modules/home/models/VehicleTypeResponse.dart';

class VehicleCategoryService {
  final VehicleCategoryRepository _repo =
      VehicleCategoryRepository();

  Future<VehicleTypeResponse> getAllvehicleCategory({
    int page = 1,
    int limit = 10,
    String? search,
  }) async {
    return await _repo.getAllvehicleCategory(
      page: page,
      limit: limit,
      search: search,
    );
  }
}