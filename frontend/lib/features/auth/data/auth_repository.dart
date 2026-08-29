import 'package:dio/dio.dart';

import '../../../core/constants/api_paths.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/storage/token_storage.dart';

class AuthRepository {
  const AuthRepository({required Dio dio, required TokenStorage tokenStorage})
      : _dio = dio,
        _tokenStorage = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<void> loginWithKakaoToken(String kakaoAccessToken) async {
    await _login(ApiPaths.authKakao, {'accessToken': kakaoAccessToken});
  }

  Future<void> loginWithKakaoAuthorizationCode({
    required String authorizationCode,
    required String redirectUri,
  }) async {
    await _login(ApiPaths.authKakaoCode, {
      'authorizationCode': authorizationCode,
      'redirectUri': redirectUri,
    });
  }

  Future<void> _login(String path, Map<String, String> data) async {
    final tokens = await _requestTokens(
      path,
      data,
      fallbackMessage: '카카오 로그인에 실패했습니다.',
    );
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  Future<void> refreshSession() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      throw const ApiException(message: '저장된 refresh token이 없습니다.');
    }

    final tokens = await _requestTokens(
        ApiPaths.authRefresh,
        {
          'refreshToken': refreshToken,
        },
        fallbackMessage: '로그인 세션 갱신에 실패했습니다.');
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _dio.post<Map<String, dynamic>>(
          ApiPaths.authLogout,
          data: {'refreshToken': refreshToken},
        );
      }
    } finally {
      await _tokenStorage.clearTokens();
    }
  }

  Future<void> withdrawAccount() async {
    final response = await _dio.delete<Map<String, dynamic>>(
      ApiPaths.myProfile,
    );
    final data = response.data ?? const <String, dynamic>{};
    if (data['success'] != true) {
      throw ApiException(
        message: data['message'] as String? ?? '회원 탈퇴에 실패했습니다.',
        code: data['code'] as String?,
        statusCode: response.statusCode,
      );
    }

    await _tokenStorage.clearTokens();
  }

  Future<AuthTokens> _requestTokens(
    String path,
    Map<String, String> data, {
    required String fallbackMessage,
  }) async {
    late final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(path, data: data);
    } on DioException catch (error) {
      // 인증 payload에는 외부 access token이 포함되므로 응답의 안전한
      // message/code/status만 상위 계층에 전달하고 요청 본문은 남기지 않는다.
      throw _mapLoginRequestError(error, fallbackMessage);
    }
    final apiResponse = ApiResponse<AuthTokens>.fromJson(
      response.data ?? const <String, dynamic>{},
      AuthTokens.fromJson,
    );

    if (!apiResponse.success || apiResponse.data == null) {
      throw ApiException(
        message:
            apiResponse.message.isEmpty ? fallbackMessage : apiResponse.message,
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

    return apiResponse.data!;
  }

  ApiException _mapLoginRequestError(
    DioException error,
    String fallbackMessage,
  ) {
    final response = error.response;
    final responseData = response?.data;
    final body = responseData is Map<String, dynamic> ? responseData : null;
    final backendMessage = body?['message'];
    final backendCode = body?['code'];

    return ApiException(
      message: backendMessage is String && backendMessage.trim().isNotEmpty
          ? backendMessage
          : _networkFallbackMessage(error, fallbackMessage),
      code: backendCode is String ? backendCode : null,
      statusCode: response?.statusCode,
    );
  }

  String _networkFallbackMessage(
    DioException error,
    String fallbackMessage,
  ) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        '서버 응답이 지연되고 있습니다. 잠시 후 다시 시도해주세요.',
      DioExceptionType.connectionError => '서버에 연결할 수 없습니다. 네트워크를 확인해주세요.',
      _ => fallbackMessage,
    };
  }
}

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

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
