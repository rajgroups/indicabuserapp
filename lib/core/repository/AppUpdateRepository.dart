import 'package:flutter/foundation.dart';
import 'package:indicab/core/models/app_update_model.dart';
import 'package:indicab/core/network/client.dart';
import 'package:indicab/core/network/endpoints.dart';

class AppUpdateRepository {
  AppUpdateRepository([ApiClient? apiClient])
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// Check app update status against backend.
  ///
  /// Passes current [appVersion] and optional target [platform] (android / ios).
  Future<AppUpdateModel> checkUpdate({
    required String appVersion,
    String? platform,
  }) async {
    final targetPlatform = platform ??
        (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');

    final response = await _apiClient.get(
      ApiEndpoints.checkUpdate,
      queryParameters: {
        'app_version': appVersion,
        'platform': targetPlatform,
      },
    );

    final payload = response.data;
    if (payload is Map<String, dynamic> && payload['data'] != null) {
      return AppUpdateModel.fromJson(payload['data'] as Map<String, dynamic>);
    }

    throw Exception('Unexpected app update response format.');
  }
}
