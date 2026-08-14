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

  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');

  static const firebaseAndroidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );

  static const firebaseIosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
  );

  static const firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );

  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );

  static const legalBusinessName = String.fromEnvironment(
    'LEGAL_BUSINESS_NAME',
    defaultValue: '운영자 이름 입력',
  );

  static const legalRepresentativeName = String.fromEnvironment(
    'LEGAL_REPRESENTATIVE_NAME',
    defaultValue: '운영자 이름 입력',
  );

  static const legalBusinessRegistrationNumber = String.fromEnvironment(
    'LEGAL_BUSINESS_REGISTRATION_NUMBER',
    defaultValue: '출시 설정 필요',
  );

  static const legalBusinessAddress = String.fromEnvironment(
    'LEGAL_BUSINESS_ADDRESS',
    defaultValue: '출시 설정 필요',
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
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    return firebaseApiKey.isNotEmpty &&
        firebaseAppId.isNotEmpty &&
        firebaseMessagingSenderId.isNotEmpty &&
        firebaseProjectId.isNotEmpty;
  }

  static String get firebaseAppId {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => firebaseAndroidAppId,
      TargetPlatform.iOS => firebaseIosAppId,
      _ => '',
    };
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
