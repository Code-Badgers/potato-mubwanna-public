import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_response.dart';
import '../domain/audio_guide.dart';

class AudioGuideRepository {
  const AudioGuideRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<AudioGuide> fetchAudioGuide(String spotId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.spotAudioGuide(spotId),
      );
      final result = ApiResponse<AudioGuide>.fromJson(
        response.data ?? const <String, dynamic>{},
        AudioGuide.fromJson,
      );
      if (!result.success || result.data == null) {
        throw AudioGuideException.fromStatus(
          response.statusCode,
          result.message,
        );
      }
      if (result.data!.audioUrl.trim().isEmpty) {
        throw const AudioGuideException(
          type: AudioGuideFailureType.unavailable,
          message: '이 관광지의 오디오 가이드를 찾을 수 없습니다.',
        );
      }
      return result.data!;
    } on DioException catch (error) {
      final data = error.response?.data;
      final message =
          data is Map<String, dynamic> ? data['message'] as String? ?? '' : '';
      throw AudioGuideException.fromStatus(
        error.response?.statusCode,
        message,
      );
    }
  }
}

enum AudioGuideFailureType { unavailable, serviceUnavailable, unknown }

class AudioGuideException implements Exception {
  const AudioGuideException({required this.type, required this.message});

  factory AudioGuideException.fromStatus(int? statusCode, String message) {
    if (statusCode == 404) {
      return AudioGuideException(
        type: AudioGuideFailureType.unavailable,
        message: message.isEmpty ? '이 관광지의 오디오 가이드를 찾을 수 없습니다.' : message,
      );
    }
    if (statusCode == 503) {
      return AudioGuideException(
        type: AudioGuideFailureType.serviceUnavailable,
        message: message.isEmpty ? '오디오 가이드 제공 서비스에 연결할 수 없습니다.' : message,
      );
    }
    return AudioGuideException(
      type: AudioGuideFailureType.unknown,
      message: message.isEmpty ? '오디오 가이드를 불러오지 못했습니다.' : message,
    );
  }

  final AudioGuideFailureType type;
  final String message;

  @override
  String toString() => message;
}
