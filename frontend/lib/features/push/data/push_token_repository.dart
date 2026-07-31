import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_exception.dart';

class PushTokenRepository {
  const PushTokenRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<void> register({
    required String token,
    required String platform,
    String? previousToken,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.myPushTokens,
      data: {
        'token': token,
        'platform': platform,
        if (previousToken != null && previousToken != token)
          'previousToken': previousToken,
      },
    );
    _validateSuccess(response, '푸시 토큰 등록에 실패했습니다.');
  }

  Future<void> delete(String token) async {
    final response = await _dio.delete<Map<String, dynamic>>(
      ApiPaths.myPushTokens,
      data: {'token': token},
    );
    _validateSuccess(response, '푸시 토큰 삭제에 실패했습니다.');
  }

  void _validateSuccess(
    Response<Map<String, dynamic>> response,
    String fallbackMessage,
  ) {
    final data = response.data ?? const <String, dynamic>{};
    if (data['success'] == true) {
      return;
    }
    throw ApiException(
      message: data['message'] as String? ?? fallbackMessage,
      code: data['code'] as String?,
      statusCode: response.statusCode,
    );
  }
}
