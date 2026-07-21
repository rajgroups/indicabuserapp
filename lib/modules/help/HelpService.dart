import 'package:indicab/core/models/FaqModel.dart';
import 'package:indicab/core/models/SupportTicketModel.dart';
import 'package:indicab/core/network/client.dart';
import 'HelpRepository.dart';

class HelpService {
  HelpService({HelpRepository? repository})
      : _repository = repository ?? HelpRepository(ApiClient());

  final HelpRepository _repository;

  Future<List<FaqModel>> fetchFaqs({String? category}) async {
    return await _repository.getFaqs(category: category);
  }

  Future<List<SupportTicketModel>> fetchSupportTickets() async {
    return await _repository.getSupportTickets();
  }

  Future<SupportTicketModel> submitSupportTicket(Map<String, dynamic> data) async {
    return await _repository.createSupportTicket(data);
  }
}
