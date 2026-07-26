import 'kakao_login_exception.dart';
import 'kakao_login_result.dart';

class KakaoLoginService {
  const KakaoLoginService();

  Future<void> preload() async {}

  Future<KakaoLoginResult> login() {
    throw const KakaoLoginUnsupportedException(
      '현재 플랫폼에서는 카카오 로그인을 사용할 수 없습니다.',
    );
  }

  KakaoAuthorizationCallback? readAuthorizationCallback() => null;

  void clearAuthorizationCallback() {}
}
