import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import '../../../app/config/app_environment.dart';
import 'kakao_login_exception.dart';
import 'kakao_login_result.dart';

class KakaoLoginService {
  const KakaoLoginService();

  Future<void> preload() async {}

  Future<KakaoLoginResult> login() async {
    if (!AppEnvironment.hasKakaoLoginKey) {
      throw const KakaoLoginUnsupportedException(
        'KAKAO_NATIVE_APP_KEY가 설정되지 않았습니다.',
      );
    }

    final token = await _loginWithAvailableMethod();
    return KakaoAccessTokenLoginResult(token.accessToken);
  }

  KakaoAuthorizationCallback? readAuthorizationCallback() => null;

  void clearAuthorizationCallback() {}

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
