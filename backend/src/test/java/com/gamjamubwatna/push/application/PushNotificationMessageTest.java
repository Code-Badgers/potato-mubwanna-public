package com.gamjamubwatna.push.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.gamjamubwatna.push.domain.PushDestination;
import java.util.Map;
import org.junit.jupiter.api.Test;

class PushNotificationMessageTest {

    @Test
    void createsWhitelistedSpotPayload() {
        PushNotificationMessage message = new PushNotificationMessage(
            "감자 스팟",
            "새로운 장소를 확인해보세요.",
            PushDestination.SPOT,
            17L
        );

        assertThat(message.data()).isEqualTo(Map.of(
            "destination",
            "SPOT",
            "destinationId",
            "17"
        ));
    }

    @Test
    void rejectsSpotWithoutDestinationId() {
        assertThatThrownBy(() -> new PushNotificationMessage(
            "감자 스팟",
            "새로운 장소를 확인해보세요.",
            PushDestination.SPOT,
            null
        )).isInstanceOf(IllegalArgumentException.class);
    }

    @Test
    void rejectsDestinationIdForListDestination() {
        assertThatThrownBy(() -> new PushNotificationMessage(
            "미션",
            "미션을 확인해보세요.",
            PushDestination.MISSIONS,
            1L
        )).isInstanceOf(IllegalArgumentException.class);
    }
}
