import 'package:indicab/core/network/client.dart';
import 'HistoryRepository.dart';

class HistoryService {
  HistoryService({HistoryRepository? repository})
      : _repository = repository ?? HistoryRepository(ApiClient());

  final HistoryRepository _repository;

  Future<HistoryPaginatedResponse> fetchBookingHistory(Map<String, dynamic> queryParams) async {
    return await _repository.getBookingHistory(queryParams);
  }
}
