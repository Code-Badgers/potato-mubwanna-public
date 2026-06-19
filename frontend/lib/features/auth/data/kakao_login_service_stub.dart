import 'kakao_login_exception.dart';

class KakaoLoginService {
  const KakaoLoginService();

  Future<String> loginAndReadAccessToken() {
    throw const KakaoLoginUnsupportedException(
      '현재 플랫폼에서는 카카오 로그인을 사용할 수 없습니다.',
    );
  }
}
