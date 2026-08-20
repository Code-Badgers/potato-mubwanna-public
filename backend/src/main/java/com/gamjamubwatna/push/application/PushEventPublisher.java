package com.gamjamubwatna.push.application;

@FunctionalInterface
public interface PushEventPublisher {

    void publish(Long userId, PushNotificationMessage message);

    static PushEventPublisher noop() {
        return (userId, message) -> {
        };
    }
}
