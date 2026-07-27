import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/travel_record.dart';

class TravelRecordRepository {
  const TravelRecordRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<TravelRecord>> fetchTravelRecords() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.myVisits);
    final result = ApiResponse<List<TravelRecord>>.fromJson(
      response.data ?? const <String, dynamic>{},
      (json) {
        final values = json as List<dynamic>? ?? const [];
        return values
            .whereType<Map<String, dynamic>>()
            .map(TravelRecord.fromJson)
            .where((record) => record.visitId > 0 && record.spotId > 0)
            .toList(growable: false);
      },
    );

    if (!result.success || result.data == null) {
      throw ApiException(
        message: result.message.isEmpty ? '여행 기록을 불러오지 못했습니다.' : result.message,
        code: result.code,
        statusCode: response.statusCode,
      );
    }
    return result.data!;
  }
}
