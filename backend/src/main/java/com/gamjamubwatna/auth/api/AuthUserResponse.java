package com.gamjamubwatna.auth.api;

public record AuthUserResponse(
    long id,
    String email,
    String nickname,
    String profileImage
) {
}
