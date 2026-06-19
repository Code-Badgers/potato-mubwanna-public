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

  static bool get hasKakaoLoginKey => kakaoNativeAppKey.isNotEmpty;
}
