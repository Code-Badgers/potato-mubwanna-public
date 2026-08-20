package com.gamjamubwatna.push.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

import com.gamjamubwatna.push.domain.PushDestination;
import java.lang.reflect.Method;
import org.junit.jupiter.api.Test;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

class PushRequestedEventListenerTest {

    @Test
    void sendsRequestedPushAfterCommit() throws Exception {
        PushNotificationService pushNotificationService = mock(PushNotificationService.class);
        PushRequestedEventListener listener =
            new PushRequestedEventListener(pushNotificationService);
        PushRequestedEvent event = event();

        listener.sendAfterCommit(event);

        verify(pushNotificationService).sendToUser(event.userId(), event.message());
        Method listenerMethod = PushRequestedEventListener.class.getMethod(
            "sendAfterCommit",
            PushRequestedEvent.class
        );
        TransactionalEventListener annotation =
            listenerMethod.getAnnotation(TransactionalEventListener.class);
        assertThat(annotation).isNotNull();
        assertThat(annotation.phase()).isEqualTo(TransactionPhase.AFTER_COMMIT);
    }

    @Test
    void isolatesPushFailureFromCommittedBusinessAction() {
        PushNotificationService pushNotificationService = mock(PushNotificationService.class);
        PushRequestedEventListener listener =
            new PushRequestedEventListener(pushNotificationService);
        PushRequestedEvent event = event();
        doThrow(new IllegalStateException("firebase unavailable"))
            .when(pushNotificationService)
            .sendToUser(event.userId(), event.message());

        assertThatCode(() -> listener.sendAfterCommit(event)).doesNotThrowAnyException();
    }

    private PushRequestedEvent event() {
        return new PushRequestedEvent(
            1L,
            new PushNotificationMessage(
                "미션 완료",
                "미션을 완료했어요.",
                PushDestination.MISSIONS,
                null
            )
        );
    }
}
