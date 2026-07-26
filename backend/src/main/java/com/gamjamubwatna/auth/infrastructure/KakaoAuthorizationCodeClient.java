package com.gamjamubwatna.auth.infrastructure;

public interface KakaoAuthorizationCodeClient {

    String exchange(String authorizationCode, String redirectUri);
}
