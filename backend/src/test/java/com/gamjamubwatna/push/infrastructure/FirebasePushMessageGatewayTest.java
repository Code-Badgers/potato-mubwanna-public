package com.gamjamubwatna.push.infrastructure;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.AndroidNotification;
import com.google.firebase.messaging.BatchResponse;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.MulticastMessage;
import com.gamjamubwatna.push.application.PushNotificationMessage;
import com.gamjamubwatna.push.domain.PushDestination;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.test.util.ReflectionTestUtils;

class FirebasePushMessageGatewayTest {

    @Test
    void sendsAndroidPushWithBrandedHeadsUpConfiguration() throws Exception {
        FirebaseMessaging firebaseMessaging = mock(FirebaseMessaging.class);
        BatchResponse response = mock(BatchResponse.class);
        ArgumentCaptor<MulticastMessage> messageCaptor =
            ArgumentCaptor.forClass(MulticastMessage.class);
        when(firebaseMessaging.sendEachForMulticast(messageCaptor.capture()))
            .thenReturn(response);

        FirebasePushMessageGateway gateway =
            new FirebasePushMessageGateway(firebaseMessaging);
        gateway.send(
            java.util.List.of("registration-token"),
            new PushNotificationMessage(
                "감자 성장 완료",
                "대표 감자가 한 단계 성장했어요.",
                PushDestination.POTATOES,
                null
            )
        );

        AndroidConfig androidConfig = (AndroidConfig) ReflectionTestUtils.getField(
            messageCaptor.getValue(),
            "androidConfig"
        );
        assertThat(androidConfig).isNotNull();
        assertThat(ReflectionTestUtils.getField(androidConfig, "priority"))
            .isEqualTo("high");

        AndroidNotification notification = (AndroidNotification)
            ReflectionTestUtils.getField(androidConfig, "notification");
        assertThat(notification).isNotNull();
        assertThat(ReflectionTestUtils.getField(notification, "channelId"))
            .isEqualTo("potato_updates");
        assertThat(ReflectionTestUtils.getField(notification, "icon"))
            .isEqualTo("ic_stat_potato");
        assertThat(ReflectionTestUtils.getField(notification, "color"))
            .isEqualTo("#56C787");
        assertThat(ReflectionTestUtils.getField(notification, "defaultSound"))
            .isEqualTo(true);
        assertThat(ReflectionTestUtils.getField(notification, "defaultVibrateTimings"))
            .isEqualTo(true);
    }
}
