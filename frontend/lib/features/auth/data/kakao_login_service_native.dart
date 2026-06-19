import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../../../app/config/app_environment.dart';
import 'kakao_login_exception.dart';

class KakaoLoginService {
  const KakaoLoginService();

  static const _profileConsentScopes = [
    'profile_nickname',
    'account_email',
  ];

  Future<String> loginAndReadAccessToken() async {
    if (!AppEnvironment.hasKakaoLoginKey) {
      throw const KakaoLoginUnsupportedException(
        'KAKAO_NATIVE_APP_KEY가 설정되지 않았습니다.',
      );
    }

    final token = await _requestProfileScopesIfNeeded(
      await _loginWithAvailableMethod(),
    );
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

  Future<OAuthToken> _requestProfileScopesIfNeeded(OAuthToken token) async {
    final grantedScopes = token.scopes ?? const <String>[];
    final missingScopes = _profileConsentScopes
        .where((scope) => !grantedScopes.contains(scope))
        .toList(growable: false);
    if (missingScopes.isEmpty) {
      return token;
    }

    try {
      return await UserApi.instance.loginWithNewScopes(missingScopes);
    } catch (_) {
      return token;
    }
  }
}
