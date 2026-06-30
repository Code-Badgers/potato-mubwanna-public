import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/stamp_book.dart';

class StampRepository {
  const StampRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<StampBook> fetchStampBook() async {
    final responses = await Future.wait([
      _dio.get<Map<String, dynamic>>(ApiPaths.myStamps),
      _dio.get<Map<String, dynamic>>(ApiPaths.stampRewardCheck),
    ]);

    final progressResponse = ApiResponse<StampProgress>.fromJson(
      responses[0].data ?? const <String, dynamic>{},
      StampProgress.fromJson,
    );
    final rewardResponse = ApiResponse<NextStampReward>.fromJson(
      responses[1].data ?? const <String, dynamic>{},
      NextStampReward.fromJson,
    );

    final progress = _requireData(
      progressResponse,
      statusCode: responses[0].statusCode,
    );
    final reward = _requireData(
      rewardResponse,
      statusCode: responses[1].statusCode,
    );

    return StampBook(progress: progress, nextReward: reward);
  }

  T _requireData<T>(ApiResponse<T> response, {required int? statusCode}) {
    if (!response.success || response.data == null) {
      throw ApiException(
        message:
            response.message.isEmpty ? '랠리북을 불러오지 못했습니다.' : response.message,
        code: response.code,
        statusCode: statusCode,
      );
    }

    return response.data!;
  }
}
