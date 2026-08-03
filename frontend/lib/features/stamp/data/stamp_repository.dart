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

  Future<List<StampNextTarget>> fetchNextTargets() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.stampNextTargets,
    );
    final apiResponse = ApiResponse<List<StampNextTarget>>.fromJson(
      response.data ?? const <String, dynamic>{},
      (json) {
        final values = json as List<dynamic>? ?? const [];
        return values
            .whereType<Map<String, dynamic>>()
            .map(StampNextTarget.fromJson)
            .where((target) => target.spotId > 0)
            .toList(growable: false);
      },
    );

    return _requireData(apiResponse, statusCode: response.statusCode);
  }

  Future<StampRewardClaimResult> claimReward(
    StampRewardClaimRequest request,
  ) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        ApiPaths.stampRewardClaim,
        data: request.toJson(),
      ),
    );
    final apiResponse = ApiResponse<StampRewardClaimResult>.fromJson(
      response.data ?? const <String, dynamic>{},
      StampRewardClaimResult.fromJson,
    );

    return _requireData(apiResponse, statusCode: response.statusCode);
  }

  T _requireData<T>(ApiResponse<T> response, {required int? statusCode}) {
    if (!response.success || response.data == null) {
      throw ApiException(
        message:
            response.message.isEmpty ? '스탬프 투어를 불러오지 못했습니다.' : response.message,
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
          message: data['message'] as String? ?? '보상 수령에 실패했습니다.',
          code: data['code'] as String?,
          statusCode: error.response?.statusCode,
        );
      }
      rethrow;
    }
  }
}

class StampRewardClaimRequest {
  const StampRewardClaimRequest({required this.targetCount});

  final int targetCount;

  Map<String, Object?> toJson() => {'targetCount': targetCount};
}

class StampRewardClaimResult {
  const StampRewardClaimResult({
    required this.targetCount,
    required this.rewardHistoryId,
    required this.userCouponId,
    required this.couponName,
    required this.expiresAt,
  });

  final int targetCount;
  final int rewardHistoryId;
  final int userCouponId;
  final String couponName;
  final DateTime expiresAt;

  factory StampRewardClaimResult.fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    return StampRewardClaimResult(
      targetCount: data['targetCount'] as int? ?? 0,
      rewardHistoryId: data['rewardHistoryId'] as int? ?? 0,
      userCouponId: data['userCouponId'] as int? ?? 0,
      couponName: data['couponName'] as String? ?? '',
      expiresAt: DateTime.parse(data['expiresAt'] as String? ?? ''),
    );
  }
}
