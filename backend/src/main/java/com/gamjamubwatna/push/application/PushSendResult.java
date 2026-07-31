package com.gamjamubwatna.push.application;

public record PushSendResult(
    boolean enabled,
    int requestedCount,
    int successfulCount,
    int failedCount,
    int removedInvalidTokenCount
) {

    public static PushSendResult disabled() {
        return new PushSendResult(false, 0, 0, 0, 0);
    }
}
