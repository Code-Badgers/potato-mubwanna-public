package com.gamjamubwatna.push.application;

import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Component;

@Component
public class SpringPushEventPublisher implements PushEventPublisher {

    private final ApplicationEventPublisher applicationEventPublisher;

    public SpringPushEventPublisher(ApplicationEventPublisher applicationEventPublisher) {
        this.applicationEventPublisher = applicationEventPublisher;
    }

    @Override
    public void publish(Long userId, PushNotificationMessage message) {
        applicationEventPublisher.publishEvent(new PushRequestedEvent(userId, message));
    }
}
