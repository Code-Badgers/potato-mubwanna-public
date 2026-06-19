package com.gamjamubwatna.auth.infrastructure;

public interface KakaoUserClient {

    KakaoUserInfo fetchUser(String accessToken);
}
