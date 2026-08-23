import 'package:flutter/foundation.dart';

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

  static const legalBusinessName = String.fromEnvironment(
    'LEGAL_BUSINESS_NAME',
    defaultValue: '운영자 이름 입력',
  );

  static const legalRepresentativeName = String.fromEnvironment(
    'LEGAL_REPRESENTATIVE_NAME',
    defaultValue: '운영자 이름 입력',
  );

  static const legalContactEmail = String.fromEnvironment(
    'LEGAL_CONTACT_EMAIL',
    defaultValue: '출시 설정 필요',
  );

  static const legalContactPhone = String.fromEnvironment(
    'LEGAL_CONTACT_PHONE',
    defaultValue: '출시 설정 필요',
  );

  static const legalEffectiveDate = String.fromEnvironment(
    'LEGAL_EFFECTIVE_DATE',
    defaultValue: '2026-08-14',
  );

  static bool get hasKakaoLoginKey => kakaoNativeAppKey.isNotEmpty;

  static bool get hasFirebaseMessagingConfig {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

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
