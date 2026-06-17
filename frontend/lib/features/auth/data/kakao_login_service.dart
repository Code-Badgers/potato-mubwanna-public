import 'package:flutter/foundation.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../../../app/config/app_environment.dart';

class KakaoLoginUnsupportedException implements Exception {
  const KakaoLoginUnsupportedException(this.message);

  final String message;

  @override
  String toString() => message;
}

class KakaoLoginService {
  const KakaoLoginService();

  Future<String> loginAndReadAccessToken() async {
    if (!AppEnvironment.hasKakaoLoginKey) {
      throw const KakaoLoginUnsupportedException(
        'KAKAO_NATIVE_APP_KEY가 설정되지 않았습니다.',
      );
    }

    if (kIsWeb) {
      throw const KakaoLoginUnsupportedException(
        '현재 Flutter용 Kakao SDK는 Web 로그인을 지원하지 않습니다.',
      );
    }

    final token = await _loginWithAvailableMethod();
    return token.accessToken;
  }

  Future<OAuthToken> _loginWithAvailableMethod() async {
    if (await isKakaoTalkInstalled()) {
      try {
        return await UserApi.instance.loginWithKakaoTalk();
      } catch (_) {
        return await UserApi.instance.loginWithKakaoAccount();
      }
    }

    return UserApi.instance.loginWithKakaoAccount();
  }
}
