import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/mission_challenge.dart';

class MissionRepository {
  const MissionRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<MissionChallenge>> fetchMissions() async {
    final response = await _request(
      () => _dio.get<Map<String, dynamic>>(ApiPaths.missions),
    );
    final apiResponse = ApiResponse<List<MissionChallenge>>.fromJson(
      response.data ?? const <String, dynamic>{},
      (json) {
        final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
        final missions = data['missions'] as List<dynamic>? ?? const [];
        return missions.map(MissionChallenge.fromJson).toList();
      },
    );

    return _requireData(apiResponse, statusCode: response.statusCode);
  }

  Future<MissionCompletionResult> completeMission(String missionId) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '${ApiPaths.missions}/$missionId/complete',
      ),
    );
    final apiResponse = ApiResponse<MissionCompletionResult>.fromJson(
      response.data ?? const <String, dynamic>{},
      (json) => MissionCompletionResult.fromJson(json),
    );

    return _requireData(apiResponse, statusCode: response.statusCode);
  }

  Future<MissionCompletionResult> verifyMission(
    String missionId,
    MissionVerificationPayload payload,
  ) async {
    final response = await _request(
      () => _dio.post<Map<String, dynamic>>(
        '${ApiPaths.missions}/$missionId/verify',
        data: payload.toJson(),
      ),
    );
    final apiResponse = ApiResponse<MissionCompletionResult>.fromJson(
      response.data ?? const <String, dynamic>{},
      (json) => MissionCompletionResult.fromJson(json),
    );

    return _requireData(apiResponse, statusCode: response.statusCode);
  }

  T _requireData<T>(ApiResponse<T> response, {required int? statusCode}) {
    if (!response.success || response.data == null) {
      throw ApiException(
        message:
            response.message.isEmpty ? '미션 정보를 불러오지 못했습니다.' : response.message,
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
          message: data['message'] as String? ?? '미션 요청에 실패했습니다.',
          code: data['code'] as String?,
          statusCode: error.response?.statusCode,
        );
      }
      rethrow;
    }
  }
}

class MissionVerificationPayload {
  const MissionVerificationPayload({
    required this.type,
    this.answer,
    this.stepCount,
    this.uploadKey,
    this.qrCode,
    this.latitude,
    this.longitude,
  });

  final MissionType type;
  final String? answer;
  final int? stepCount;
  final String? uploadKey;
  final String? qrCode;
  final double? latitude;
  final double? longitude;

  Map<String, Object?> toJson() {
    return {
      'type': _missionTypeToApi(type),
      if (answer != null) 'answer': answer,
      if (stepCount != null) 'stepCount': stepCount,
      if (uploadKey != null) 'uploadKey': uploadKey,
      if (qrCode != null) 'qrCode': qrCode,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }
}

class MissionCompletionResult {
  const MissionCompletionResult({
    required this.id,
    required this.rewardType,
    required this.rewardLabel,
  });

  final String id;
  final MissionRewardType rewardType;
  final String rewardLabel;

  factory MissionCompletionResult.fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    return MissionCompletionResult(
      id: data['missionId']?.toString() ?? '',
      rewardType: missionRewardTypeFromApi(data['rewardType'] as String?),
      rewardLabel: data['rewardLabel'] as String? ?? '',
    );
  }
}

String _missionTypeToApi(MissionType type) {
  return switch (type) {
    MissionType.visit => 'VISIT',
    MissionType.visitAndStep => 'VISIT_AND_STEP',
    MissionType.photo => 'PHOTO',
    MissionType.photoOcr => 'PHOTO_OCR',
    MissionType.qrScan => 'QR_SCAN',
    MissionType.quiz => 'QUIZ',
    MissionType.stamp => 'STAMP',
    MissionType.collection => 'COLLECTION',
  };
}
