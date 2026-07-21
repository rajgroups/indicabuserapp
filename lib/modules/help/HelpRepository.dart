import 'package:indicab/core/models/FaqModel.dart';
import 'package:indicab/core/models/SupportTicketModel.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/network/endpoints.dart';

class HelpRepository {
  HelpRepository(this._apiClient);

  final ApiClient _apiClient;

  Future<List<FaqModel>> getFaqs({String? category}) async {
    final response = await _apiClient.get(
      ApiEndpoints.faqs,
      queryParameters: {
        if (category != null && category != 'All') 'category': category,
      },
    );

    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      final dataList = payload['data'] as List<dynamic>? ?? [];
      return dataList
          .whereType<Map<String, dynamic>>()
          .map((json) => FaqModel.fromJson(json))
          .toList();
    }

    return [];
  }

  Future<List<SupportTicketModel>> getSupportTickets() async {
    final response = await _apiClient.get(ApiEndpoints.supportTickets);

    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      final dataList = payload['data'] as List<dynamic>? ?? [];
      return dataList
          .whereType<Map<String, dynamic>>()
          .map((json) => SupportTicketModel.fromJson(json))
          .toList();
    }

    return [];
  }

  Future<SupportTicketModel> createSupportTicket(Map<String, dynamic> ticketData) async {
    final response = await _apiClient.post(
      ApiEndpoints.supportTickets,
      data: ticketData,
    );

    final payload = response.data;
    if (payload is Map<String, dynamic>) {
      final data = payload['data'];
      if (data is Map<String, dynamic>) {
        return SupportTicketModel.fromJson(data);
      }
    }

    throw Exception('Failed to submit support ticket.');
  }
}
