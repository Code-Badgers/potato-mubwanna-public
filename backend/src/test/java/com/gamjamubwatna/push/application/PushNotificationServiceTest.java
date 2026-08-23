package com.gamjamubwatna.push.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.push.domain.PushDestination;
import com.gamjamubwatna.push.domain.PushPlatform;
import com.gamjamubwatna.push.domain.UserPushToken;
import com.gamjamubwatna.push.domain.UserPushTokenRepository;
import java.time.Instant;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class PushNotificationServiceTest {

    @Mock
    private UserPushTokenRepository pushTokenRepository;

    @Mock
    private PushMessageGateway pushMessageGateway;

    @Test
    void returnsDisabledWithoutReadingTokens() {
        when(pushMessageGateway.isEnabled()).thenReturn(false);
        PushNotificationService service = new PushNotificationService(
            pushTokenRepository,
            pushMessageGateway
        );

        PushSendResult result = service.sendToUser(1L, message());

        assertThat(result.enabled()).isFalse();
        verifyNoInteractions(pushTokenRepository);
    }

    @Test
    void sendsToEveryTokenAndDeletesInvalidOnes() {
        User user = user();
        UserPushToken first = token(user, "first-token", PushPlatform.ANDROID);
        UserPushToken second = token(user, "second-token", PushPlatform.IOS);
        when(pushMessageGateway.isEnabled()).thenReturn(true);
        when(pushTokenRepository.findAllByUserId(1L)).thenReturn(List.of(first, second));
        when(pushMessageGateway.send(
            List.of("first-token", "second-token"),
            message()
        )).thenReturn(new PushDeliveryResult(1, 1, Set.of("second-token")));
        when(pushTokenRepository.deleteByTokenIn(Set.of("second-token"))).thenReturn(1L);
        PushNotificationService service = new PushNotificationService(
            pushTokenRepository,
            pushMessageGateway
        );

        PushSendResult result = service.sendToUser(1L, message());

        assertThat(result).isEqualTo(new PushSendResult(true, 2, 1, 1, 1));
        verify(pushTokenRepository).deleteByTokenIn(Set.of("second-token"));
    }

    @Test
    void returnsEnabledWithNoRecipients() {
        when(pushMessageGateway.isEnabled()).thenReturn(true);
        when(pushTokenRepository.findAllByUserId(1L)).thenReturn(List.of());
        PushNotificationService service = new PushNotificationService(
            pushTokenRepository,
            pushMessageGateway
        );

        PushSendResult result = service.sendToUser(1L, message());

        assertThat(result).isEqualTo(new PushSendResult(true, 0, 0, 0, 0));
    }

    @Test
    void propagatesGatewayFailureWithoutDeletingTokens() {
        User user = user();
        UserPushToken token = token(user, "first-token", PushPlatform.ANDROID);
        PushNotificationMessage message = message();
        when(pushMessageGateway.isEnabled()).thenReturn(true);
        when(pushTokenRepository.findAllByUserId(1L)).thenReturn(List.of(token));
        when(pushMessageGateway.send(List.of("first-token"), message))
            .thenThrow(new PushDeliveryException("Firebase send failed", null));
        PushNotificationService service = new PushNotificationService(
            pushTokenRepository,
            pushMessageGateway
        );

        assertThatThrownBy(() -> service.sendToUser(1L, message))
            .isInstanceOf(PushDeliveryException.class)
            .hasMessage("Firebase send failed");
        verify(pushTokenRepository, never()).deleteByTokenIn(Set.of("first-token"));
    }

    private PushNotificationMessage message() {
        return new PushNotificationMessage(
            "미션 완료",
            "새 보상이 도착했습니다.",
            PushDestination.MISSIONS,
            null
        );
    }

    private UserPushToken token(User user, String value, PushPlatform platform) {
        return new UserPushToken(
            user,
            value,
            platform,
            Instant.parse("2026-07-31T00:00:00Z")
        );
    }

    private User user() {
        return new User(
            AuthProvider.KAKAO,
            "push-user",
            null,
            "푸시 사용자",
            null,
            Instant.parse("2026-07-31T00:00:00Z")
        );
    }
}
