package com.gamjamubwatna.user.api;

import java.time.Instant;

public record UserProfileResponse(
    Long userId,
    String nickname,
    String email,
    String profileImage,
    Instant createdAt
) {
}
