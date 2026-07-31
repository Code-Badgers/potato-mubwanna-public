package com.gamjamubwatna.push.api;

import com.gamjamubwatna.push.application.PushTokenRegistration;
import com.gamjamubwatna.push.domain.PushPlatform;
import java.time.Instant;

public record PushTokenResponse(
    boolean registered,
    PushPlatform platform,
    Instant registeredAt
) {

    public static PushTokenResponse from(PushTokenRegistration registration) {
        return new PushTokenResponse(
            true,
            registration.platform(),
            registration.registeredAt()
        );
    }
}
