import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/potato_collection.dart';
import '../domain/step_count_reader.dart';

class PotatoRepository {
  const PotatoRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<PotatoCollection> fetchMyPotatoes() async {
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>(ApiPaths.myPotatoes),
    );
    final apiResponse = ApiResponse<PotatoCollection>.fromJson(
      response.data ?? const <String, dynamic>{},
      PotatoCollection.fromJson,
    );

    return _requireData(apiResponse, statusCode: response.statusCode);
  }

  Future<PotatoGrowthSummary> fetchGrowthSummary() async {
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>(ApiPaths.potatoGrowthSummary),
    );
    final apiResponse = ApiResponse<PotatoGrowthSummary>.fromJson(
      response.data ?? const <String, dynamic>{},
      PotatoGrowthSummary.fromJson,
    );

    return _requireData(apiResponse, statusCode: response.statusCode);
  }

  Future<PotatoGrowthResult?> syncDailyActivity(
    StepCountSnapshot snapshot,
  ) async {
    final response = await _request(
      () => _dio.put<Map<String, dynamic>>(
        ApiPaths.potatoDailyActivity,
        data: {
          'activityDate': _formatDate(snapshot.activityDate),
          'steps': snapshot.steps,
          'distanceMeters': snapshot.distanceMeters,
          'source': activitySyncSourceToApi(snapshot.source),
        },
      ),
    );
    final apiResponse = ApiResponse<PotatoActivitySyncResult>.fromJson(
      response.data ?? const <String, dynamic>{},
      PotatoActivitySyncResult.fromJson,
    );

    return _requireData(
      apiResponse,
      statusCode: response.statusCode,
    ).growthResult;
  }

  Future<PotatoRepresentativeResult> updateRepresentativePotato(
    String potatoId,
  ) async {
    final response = await _request(
      () => _dio.patch<Map<String, dynamic>>(
        ApiPaths.representativePotato,
        data: {'potatoId': int.tryParse(potatoId)},
      ),
    );
    final apiResponse = ApiResponse<PotatoRepresentativeResult>.fromJson(
      response.data ?? const <String, dynamic>{},
      PotatoRepresentativeResult.fromJson,
    );

    return _requireData(apiResponse, statusCode: response.statusCode);
  }

  T _requireData<T>(ApiResponse<T> response, {required int? statusCode}) {
    if (!response.success || response.data == null) {
      throw ApiException(
        message:
            response.message.isEmpty ? '감자 도감을 불러오지 못했습니다.' : response.message,
        code: response.code,
        statusCode: statusCode,
      );
    }

    return response.data!;
  }

  Future<Response<Map<String, dynamic>>> _request(
    Future<Response<Map<String, dynamic>>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        throw ApiException(
          message: data['message'] as String? ?? '감자 도감 요청에 실패했습니다.',
          code: data['code'] as String?,
          statusCode: error.response?.statusCode,
        );
      }
      rethrow;
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }
}
