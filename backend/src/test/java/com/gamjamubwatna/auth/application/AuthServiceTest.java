package com.gamjamubwatna.auth.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
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
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import org.junit.jupiter.api.Test;
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
        User savedUser = new User(
            AuthProvider.KAKAO,
            "123",
            "user@email.com",
            "감자러버",
            "https://example.com/profile.png",
            now
        );
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
            Clock.fixed(now, ZoneOffset.UTC)
        ).loginWithKakao("kakao-access-token");

        assertThat(response.accessToken()).isNotBlank();
        assertThat(response.refreshToken()).isNotBlank();
        assertThat(response.accessToken().split("\\.")).hasSize(3);
        assertThat(response.refreshToken().split("\\.")).hasSize(3);
        assertThat(response.user().email()).isEqualTo("user@email.com");
        assertThat(response.user().nickname()).isEqualTo("감자러버");
        assertThat(response.user().profileImage()).isEqualTo("https://example.com/profile.png");
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
            Clock.fixed(now, ZoneOffset.UTC)
        ).loginWithKakaoAuthorizationCode(
            "authorization-code",
            "http://localhost:54631/"
        );

        assertThat(response.accessToken()).isNotBlank();
        assertThat(response.user().nickname()).isEqualTo("감자러버");
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
            Clock.fixed(now, ZoneOffset.UTC)
        ).refresh(oldRefreshToken);

        assertThat(storedRefreshToken.isRevoked()).isTrue();
        assertThat(response.accessToken()).isNotBlank();
        assertThat(response.refreshToken()).isNotBlank();
        assertThat(response.refreshToken()).isNotEqualTo(oldRefreshToken);
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
