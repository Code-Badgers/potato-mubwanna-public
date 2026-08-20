package com.gamjamubwatna.push.application;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

@Component
public class PushRequestedEventListener {

    private static final Logger log = LoggerFactory.getLogger(PushRequestedEventListener.class);

    private final PushNotificationService pushNotificationService;

    public PushRequestedEventListener(PushNotificationService pushNotificationService) {
        this.pushNotificationService = pushNotificationService;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void sendAfterCommit(PushRequestedEvent event) {
        try {
            pushNotificationService.sendToUser(event.userId(), event.message());
        } catch (RuntimeException exception) {
            log.warn("Push delivery failed after transaction commit for user {}", event.userId(), exception);
        }
    }
}
