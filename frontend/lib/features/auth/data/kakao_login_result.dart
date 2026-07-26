sealed class KakaoLoginResult {
  const KakaoLoginResult();
}

class KakaoAccessTokenLoginResult extends KakaoLoginResult {
  const KakaoAccessTokenLoginResult(this.accessToken);

  final String accessToken;
}

class KakaoAuthorizationRedirectResult extends KakaoLoginResult {
  const KakaoAuthorizationRedirectResult();
}

class KakaoAuthorizationCallback {
  const KakaoAuthorizationCallback({
    required this.authorizationCode,
    required this.redirectUri,
  });

  final String authorizationCode;
  final String redirectUri;
}
