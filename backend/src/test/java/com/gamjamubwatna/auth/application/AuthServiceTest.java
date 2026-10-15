package com.gamjamubwatna.auth.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamjamubwatna.auth.api.AuthLoginResponse;
import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.RefreshToken;
import com.gamjamubwatna.auth.domain.RefreshTokenRepository;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.auth.infrastructure.KakaoAuthorizationCodeClient;
import com.gamjamubwatna.auth.infrastructure.KakaoUserClient;
import com.gamjamubwatna.auth.infrastructure.KakaoUserInfo;
import com.gamjamubwatna.potato.application.StarterPotatoGrantService;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.test.util.ReflectionTestUtils;

class AuthServiceTest {

    @Test
    void loginWithKakaoSavesUserAndRefreshToken() {
        Instant now = Instant.parse("2026-06-19T00:00:00Z");
        KakaoUserClient kakaoUserClient = accessToken -> new KakaoUserInfo(
            123L,
            "user@email.com",
            "감자러버",
            "https://example.com/profile.png"
        );
        UserRepository userRepository = mock(UserRepository.class);
        RefreshTokenRepository refreshTokenRepository = mock(RefreshTokenRepository.class);
        StarterPotatoGrantService starterPotatoGrantService =
            mock(StarterPotatoGrantService.class);
        when(userRepository.findByProviderAndProviderUserId(AuthProvider.KAKAO, "123"))
            .thenReturn(Optional.empty());
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            ReflectionTestUtils.setField(user, "id", 1L);
            return user;
        });
        when(refreshTokenRepository.save(any(RefreshToken.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

        AuthLoginResponse response = new AuthService(
            kakaoUserClient,
            (authorizationCode, redirectUri) -> "unused",
            jwtTokenProvider(now),
            userRepository,
            refreshTokenRepository,
            starterPotatoGrantService,
            Clock.fixed(now, ZoneOffset.UTC)
        ).loginWithKakao("kakao-access-token");

        assertThat(response.accessToken()).isNotBlank();
        assertThat(response.refreshToken()).isNotBlank();
        assertThat(response.accessToken().split("\\.")).hasSize(3);
        assertThat(response.refreshToken().split("\\.")).hasSize(3);
        assertThat(response.user().email()).isEqualTo("user@email.com");
        assertThat(response.user().nickname()).isEqualTo("감자러버");
        assertThat(response.user().profileImage()).isEqualTo("https://example.com/profile.png");
        verify(starterPotatoGrantService).grantIfNeeded(any(User.class), eq(now));
    }

    @Test
    void loginWithKakaoAuthorizationCodeExchangesCodeBeforeFetchingUser() {
        Instant now = Instant.parse("2026-06-19T00:00:00Z");
        KakaoAuthorizationCodeClient codeClient = (authorizationCode, redirectUri) -> {
            assertThat(authorizationCode).isEqualTo("authorization-code");
            assertThat(redirectUri).isEqualTo("http://localhost:54631/");
            return "kakao-access-token";
        };
        KakaoUserClient userClient = accessToken -> {
            assertThat(accessToken).isEqualTo("kakao-access-token");
            return new KakaoUserInfo(123L, null, null, null);
        };
        UserRepository userRepository = mock(UserRepository.class);
        RefreshTokenRepository refreshTokenRepository = mock(RefreshTokenRepository.class);
        StarterPotatoGrantService starterPotatoGrantService =
            mock(StarterPotatoGrantService.class);
        when(userRepository.findByProviderAndProviderUserId(AuthProvider.KAKAO, "123"))
            .thenReturn(Optional.empty());
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> {
            User user = invocation.getArgument(0);
            ReflectionTestUtils.setField(user, "id", 1L);
            return user;
        });

        AuthLoginResponse response = new AuthService(
            userClient,
            codeClient,
            jwtTokenProvider(now),
            userRepository,
            refreshTokenRepository,
            starterPotatoGrantService,
            Clock.fixed(now, ZoneOffset.UTC)
        ).loginWithKakaoAuthorizationCode(
            "authorization-code",
            "http://localhost:54631/"
        );

        assertThat(response.accessToken()).isNotBlank();
        assertThat(response.user().nickname()).isEqualTo("감자러버");
        verify(starterPotatoGrantService).grantIfNeeded(any(User.class), any(Instant.class));
    }

    @Test
    void refreshRotatesRefreshToken() {
        Instant now = Instant.parse("2026-06-19T00:00:00Z");
        JwtTokenProvider jwtTokenProvider = jwtTokenProvider(now);
        User user = new User(
            AuthProvider.KAKAO,
            "123",
            "user@email.com",
            "감자러버",
            "https://example.com/profile.png",
            now
        );
        ReflectionTestUtils.setField(user, "id", 1L);
        String oldRefreshToken = jwtTokenProvider.createRefreshToken("user:1");
        RefreshToken storedRefreshToken = new RefreshToken(
            user,
            oldRefreshToken,
            now.plusSeconds(7200)
        );
        RefreshTokenRepository refreshTokenRepository = mock(RefreshTokenRepository.class);
        StarterPotatoGrantService starterPotatoGrantService =
            mock(StarterPotatoGrantService.class);
        when(refreshTokenRepository.findByToken(oldRefreshToken))
            .thenReturn(Optional.of(storedRefreshToken));
        when(refreshTokenRepository.save(any(RefreshToken.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

        AuthLoginResponse response = new AuthService(
            accessToken -> null,
            (authorizationCode, redirectUri) -> "unused",
            jwtTokenProvider,
            mock(UserRepository.class),
            refreshTokenRepository,
            starterPotatoGrantService,
            Clock.fixed(now, ZoneOffset.UTC)
        ).refresh(oldRefreshToken);

        assertThat(storedRefreshToken.isRevoked()).isTrue();
        assertThat(response.accessToken()).isNotBlank();
        assertThat(response.refreshToken()).isNotBlank();
        assertThat(response.refreshToken()).isNotEqualTo(oldRefreshToken);
        verify(starterPotatoGrantService).grantIfNeeded(user, now);
    }

    @ParameterizedTest
    @ValueSource(strings = {"missing", "expired", "revoked", "invalid-jwt", "wrong-type"})
    void refreshRejectsOnlyInvalidTokens(String reason) {
        Instant now = Instant.parse("2026-06-19T00:00:00Z");
        RefreshTokenRepository repository = mock(RefreshTokenRepository.class);
        StarterPotatoGrantService starterGrant = mock(StarterPotatoGrantService.class);
        JwtTokenProvider provider = mock(JwtTokenProvider.class);
        RefreshToken token = new RefreshToken(
            mock(User.class), "stored-token",
            reason.equals("expired") ? now.minusSeconds(1) : now.plusSeconds(7200)
        );
        if (reason.equals("revoked")) {
            token.revoke();
        }
        when(repository.findByToken("stored-token"))
            .thenReturn(reason.equals("missing") ? Optional.empty() : Optional.of(token));
        if (reason.equals("invalid-jwt")) {
            when(provider.parse("stored-token")).thenThrow(new IllegalArgumentException("invalid JWT"));
        } else if (reason.equals("wrong-type")) {
            when(provider.parse("stored-token"))
                .thenReturn(new JwtTokenProvider.JwtClaims("user:1", "access", now.plusSeconds(3600)));
        }
        AuthService service = new AuthService(
            accessToken -> null, (code, uri) -> "unused", provider,
            mock(UserRepository.class), repository, starterGrant, Clock.fixed(now, ZoneOffset.UTC)
        );

        assertThatThrownBy(() -> service.refresh("stored-token"))
            .isInstanceOf(InvalidRefreshTokenException.class);
        verifyNoInteractions(starterGrant);
        assertThat(token.isRevoked()).isEqualTo(reason.equals("revoked"));
    }

    @Test
    void refreshDoesNotTreatRewardFailureAsInvalidAuthentication() {
        Instant now = Instant.parse("2026-06-19T00:00:00Z");
        JwtTokenProvider provider = jwtTokenProvider(now);
        User user = mock(User.class);
        String value = provider.createRefreshToken("user:1");
        RefreshToken token = new RefreshToken(user, value, now.plusSeconds(7200));
        RefreshTokenRepository repository = mock(RefreshTokenRepository.class);
        when(repository.findByToken(value)).thenReturn(Optional.of(token));
        StarterPotatoGrantService starterGrant = mock(StarterPotatoGrantService.class);
        doThrow(new IllegalArgumentException("reward unavailable"))
            .when(starterGrant).grantIfNeeded(user, now);
        AuthService service = new AuthService(
            accessToken -> null, (code, uri) -> "unused", provider,
            mock(UserRepository.class), repository, starterGrant, Clock.fixed(now, ZoneOffset.UTC)
        );

        assertThatThrownBy(() -> service.refresh(value))
            .isExactlyInstanceOf(IllegalArgumentException.class)
            .hasMessage("reward unavailable");
        assertThat(token.isRevoked()).isFalse();
    }

    private JwtTokenProvider jwtTokenProvider(Instant now) {
        return new JwtTokenProvider(
            new ObjectMapper(),
            Clock.fixed(now, ZoneOffset.UTC),
            "test-jwt-secret-must-be-long-enough",
            3600,
            7200
        );
    }
}
