package com.gamjamubwatna.push.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.push.domain.PushPlatform;
import com.gamjamubwatna.push.domain.UserPushToken;
import com.gamjamubwatna.push.domain.UserPushTokenRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class PushTokenServiceTest {

    private static final Instant NOW = Instant.parse("2026-07-31T00:00:00Z");

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserPushTokenRepository pushTokenRepository;

    private PushTokenService service;

    @BeforeEach
    void setUp() {
        service = new PushTokenService(
            userRepository,
            pushTokenRepository,
            60,
            Clock.fixed(NOW, ZoneOffset.UTC)
        );
    }

    @Test
    void registersNewTokenAndCleansStaleTokens() {
        User user = user(1L);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(pushTokenRepository.findByToken("current-token")).thenReturn(Optional.empty());
        when(pushTokenRepository.save(org.mockito.ArgumentMatchers.any(UserPushToken.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

        PushTokenRegistration result = service.register(
            1L,
            "current-token",
            PushPlatform.ANDROID,
            null
        );

        assertThat(result.platform()).isEqualTo(PushPlatform.ANDROID);
        assertThat(result.registeredAt()).isEqualTo(NOW);
        verify(pushTokenRepository).deleteByUpdatedAtBefore(
            Instant.parse("2026-06-01T00:00:00Z")
        );
        verify(pushTokenRepository).save(org.mockito.ArgumentMatchers.argThat(token ->
            token.getUser() == user
                && token.getToken().equals("current-token")
                && token.getPlatform() == PushPlatform.ANDROID
        ));
    }

    @Test
    void replacesOwnedPreviousTokenAndTransfersCurrentToken() {
        User previousUser = user(2L);
        User currentUser = user(1L);
        UserPushToken existing = new UserPushToken(
            previousUser,
            "current-token",
            PushPlatform.IOS,
            Instant.parse("2026-07-01T00:00:00Z")
        );
        when(userRepository.findById(1L)).thenReturn(Optional.of(currentUser));
        when(pushTokenRepository.findByToken("current-token"))
            .thenReturn(Optional.of(existing));
        when(pushTokenRepository.save(existing)).thenReturn(existing);

        service.register(
            1L,
            "current-token",
            PushPlatform.ANDROID,
            "previous-token"
        );

        verify(pushTokenRepository).deleteByUserIdAndToken(1L, "previous-token");
        assertThat(existing.getUser()).isSameAs(currentUser);
        assertThat(existing.getPlatform()).isEqualTo(PushPlatform.ANDROID);
        assertThat(existing.getUpdatedAt()).isEqualTo(NOW);
    }

    @Test
    void doesNotDeleteCurrentTokenWhenPreviousTokenMatches() {
        User user = user(1L);
        UserPushToken existing = new UserPushToken(
            user,
            "same-token",
            PushPlatform.IOS,
            NOW
        );
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(pushTokenRepository.findByToken("same-token"))
            .thenReturn(Optional.of(existing));
        when(pushTokenRepository.save(existing)).thenReturn(existing);

        service.register(1L, "same-token", PushPlatform.IOS, "same-token");

        verify(pushTokenRepository, never()).deleteByUserIdAndToken(1L, "same-token");
    }

    @Test
    void rejectsMalformedTokenBeforeRepositoryAccess() {
        assertThatThrownBy(() ->
            service.register(1L, " token with spaces ", PushPlatform.ANDROID, null)
        )
            .isInstanceOf(PushTokenValidationException.class)
            .hasMessage("푸시 토큰을 확인해주세요.");

        verifyNoInteractions(userRepository, pushTokenRepository);
    }

    @Test
    void deletesOnlyAuthenticatedUsersTokenIdempotently() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));

        service.delete(1L, "current-token");

        verify(pushTokenRepository).deleteByUserIdAndToken(1L, "current-token");
    }

    @Test
    void rejectsDeletedUser() {
        when(userRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() ->
            service.register(99L, "current-token", PushPlatform.ANDROID, null)
        ).isInstanceOf(PushTokenAuthenticationException.class);

        verify(pushTokenRepository, never()).save(
            org.mockito.ArgumentMatchers.any(UserPushToken.class)
        );
    }

    private User user(Long id) {
        User user = new User(
            AuthProvider.KAKAO,
            "push-user-" + id,
            null,
            "푸시 사용자",
            null,
            NOW
        );
        ReflectionTestUtils.setField(user, "id", id);
        return user;
    }
}
