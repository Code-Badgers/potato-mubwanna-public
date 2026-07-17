import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/reward_history.dart';

class RewardHistoryRepository {
  const RewardHistoryRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<RewardHistory>> fetchRewardHistory() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.rewardHistory,
    );
    final result = ApiResponse<List<RewardHistory>>.fromJson(
      response.data ?? const <String, dynamic>{},
      (json) {
        final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
        final values = data['rewards'] as List<dynamic>? ?? const [];
        return values
            .whereType<Map<String, dynamic>>()
            .map(RewardHistory.fromJson)
            .toList(growable: false);
      },
    );
    return _requireData(result, statusCode: response.statusCode);
  }

  T _requireData<T>(ApiResponse<T> response, {required int? statusCode}) {
    if (!response.success || response.data == null) {
      throw ApiException(
        message:
            response.message.isEmpty ? '보상 내역을 불러오지 못했습니다.' : response.message,
        code: response.code,
        statusCode: statusCode,
      );
    }
    return response.data!;
  }
}
