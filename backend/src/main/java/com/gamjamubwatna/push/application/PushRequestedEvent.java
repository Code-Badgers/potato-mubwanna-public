package com.gamjamubwatna.push.application;

public record PushRequestedEvent(
    Long userId,
    PushNotificationMessage message
) {

    public PushRequestedEvent {
        if (userId == null || userId < 1) {
            throw new IllegalArgumentException("Push user id must be positive");
        }
        if (message == null) {
            throw new IllegalArgumentException("Push message is required");
        }
    }
}
