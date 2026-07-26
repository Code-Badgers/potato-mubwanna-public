import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/user_activity_summary.dart';

class UserActivitySummaryRepository {
  const UserActivitySummaryRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<UserActivitySummary> fetchActivitySummary() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.myActivitySummary,
    );
    final apiResponse = ApiResponse<UserActivitySummary>.fromJson(
      response.data ?? const <String, dynamic>{},
      UserActivitySummary.fromJson,
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message.isEmpty
            ? '활동 요약을 불러오지 못했습니다.'
            : apiResponse.message,
        code: apiResponse.code,
        statusCode: response.statusCode,
      );
    }

    return apiResponse.data!;
  }
}
