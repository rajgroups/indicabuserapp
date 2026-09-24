import 'package:dio/dio.dart';
import 'package:indicab/core/network/client.dart';

class ReferralService {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> getSummary() async {
    try {
      final response = await _apiClient.get('/referrals/summary');
      final data = response.data;
      if (data is Map && data['status'] == true && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> getReferralCode() async {
    try {
      final response = await _apiClient.get('/referrals/code');
      final data = response.data;
      if (data is Map && data['status'] == true && data['data'] is Map) {
        return Map<String, dynamic>.from(data['data'] as Map);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<List<dynamic>> getHistory() async {
    try {
      final response = await _apiClient.get('/referrals/history');
      final data = response.data;
      if (data is Map && data['status'] == true && data['data'] is List) {
        return List<dynamic>.from(data['data'] as List);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> validateCode(String code) async {
    try {
      final response = await _apiClient.post(
        '/referrals/validate',
        data: {'referral_code': code},
      );
      return response.data is Map
          ? Map<String, dynamic>.from(response.data as Map)
          : {'status': false, 'message': 'Validation failed'};
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        return e.response!.data;
      }
      return {'status': false, 'message': 'Validation failed'};
    }
  }
}
