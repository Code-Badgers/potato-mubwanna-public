import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/storage/token_storage.dart';

class AuthRepository {
  const AuthRepository({
    required Dio dio,
    required TokenStorage tokenStorage,
  })  : _dio = dio,
        _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<void> loginWithKakaoToken(String kakaoAccessToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.authKakao,
      data: {'accessToken': kakaoAccessToken},
    );
    final apiResponse = ApiResponse<AuthTokens>.fromJson(
      response.data ?? const <String, dynamic>{},
      AuthTokens.fromJson,
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message: apiResponse.message.isEmpty
            ? '카카오 로그인에 실패했습니다.'
            : apiResponse.message,
        code: apiResponse.code,
        statusCode: response.statusCode,
      );
    }

    if (apiResponse.data!.accessToken.isEmpty ||
        apiResponse.data!.refreshToken.isEmpty) {
      throw ApiException(
        message: '인증 토큰 응답이 올바르지 않습니다.',
        statusCode: response.statusCode,
      );
    }

    await _tokenStorage.saveTokens(
      accessToken: apiResponse.data!.accessToken,
      refreshToken: apiResponse.data!.refreshToken,
    );
  }
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  static AuthTokens fromJson(Object? json) {
    final data = json as Map<String, dynamic>? ?? const <String, dynamic>{};
    return AuthTokens(
      accessToken: data['accessToken'] as String? ?? '',
      refreshToken: data['refreshToken'] as String? ?? '',
    );
  }
}
