package com.gamjamubwatna.push.api;

import com.gamjamubwatna.push.domain.PushPlatform;

public record PushTokenRegisterRequest(
    String token,
    PushPlatform platform,
    String previousToken
) {
}
