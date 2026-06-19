package com.gamjamubwatna.auth.infrastructure;

public record KakaoUserInfo(
    long id,
    String email,
    String nickname,
    String profileImage
) {
}
