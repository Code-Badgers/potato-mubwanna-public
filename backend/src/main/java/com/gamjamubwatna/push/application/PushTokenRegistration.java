package com.gamjamubwatna.push.application;

import com.gamjamubwatna.push.domain.PushPlatform;
import java.time.Instant;

public record PushTokenRegistration(
    PushPlatform platform,
    Instant registeredAt
) {
}
