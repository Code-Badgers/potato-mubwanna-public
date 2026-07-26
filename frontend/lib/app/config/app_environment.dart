class AppEnvironment {
  const AppEnvironment._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api',
  );

  static const kakaoNativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
  );

  static const kakaoJavaScriptKey = String.fromEnvironment(
    'KAKAO_JAVASCRIPT_KEY',
  );

  static const kakaoLoginRedirectUri = String.fromEnvironment(
    'KAKAO_LOGIN_REDIRECT_URI',
  );

  static bool get hasKakaoLoginKey => kakaoNativeAppKey.isNotEmpty;

  static bool get hasKakaoAuthorizationCallback =>
      Uri.base.queryParameters.containsKey('code') ||
      Uri.base.queryParameters.containsKey('error');

  static String get effectiveKakaoLoginRedirectUri {
    if (kakaoLoginRedirectUri.isNotEmpty) {
      return kakaoLoginRedirectUri;
    }
    return Uri.base.replace(query: '', fragment: '').toString();
  }
}
