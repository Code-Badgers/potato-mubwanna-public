import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/spot_detail.dart';

class SpotDetailRepository {
  const SpotDetailRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<SpotDetail> fetchSpotDetail(String spotId) async {
    return SpotDetail.fromJson(await fetchSpotDetailPayload(spotId));
  }

  Future<Map<String, dynamic>> fetchSpotDetailPayload(
    String spotId, {
    bool basic = false,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        basic ? ApiPaths.spotBasicDetail(spotId) : ApiPaths.spotDetail(spotId),
      );
      final result = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data ?? const <String, dynamic>{},
        (value) => value is Map
            ? Map<String, dynamic>.from(value)
            : <String, dynamic>{},
      );
      if (!result.success || result.data == null || result.data!.isEmpty) {
        throw ApiException(
          message:
              result.message.isEmpty ? '관광지 정보를 불러오지 못했습니다.' : result.message,
          code: result.code,
          statusCode: response.statusCode,
        );
      }
      return result.data!;
    } on DioException catch (error) {
      final data = error.response?.data;
      throw ApiException(
        message: data is Map<String, dynamic>
            ? data['message'] as String? ?? '관광지 정보를 불러오지 못했습니다.'
            : '관광지 정보를 불러오지 못했습니다.',
        code: data is Map<String, dynamic> ? data['code'] as String? : null,
        statusCode: error.response?.statusCode,
      );
    }
  }
}
