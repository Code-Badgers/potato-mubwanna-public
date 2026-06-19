package com.gamjamubwatna.auth.api;

public record AuthLoginResponse(
    String accessToken,
    String refreshToken,
    AuthUserResponse user
) {
}
