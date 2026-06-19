package com.gamjamubwatna.auth.application;

import static org.assertj.core.api.Assertions.assertThat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamjamubwatna.auth.api.AuthLoginResponse;
import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.auth.infrastructure.KakaoUserClient;
import com.gamjamubwatna.auth.infrastructure.KakaoUserInfo;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.Test;

class AuthServiceTest {

    @Test
    void loginWithKakaoExchangesKakaoUserForServiceTokens() {
        KakaoUserClient kakaoUserClient = accessToken -> new KakaoUserInfo(
            123L,
            "user@email.com",
            "감자러버",
            "https://example.com/profile.png"
        );
        JwtTokenProvider jwtTokenProvider = new JwtTokenProvider(
            new ObjectMapper(),
            Clock.fixed(Instant.parse("2026-06-19T00:00:00Z"), ZoneOffset.UTC),
            "test-jwt-secret-must-be-long-enough",
            3600,
            7200
        );

        AuthLoginResponse response = new AuthService(
            kakaoUserClient,
            jwtTokenProvider
        ).loginWithKakao("kakao-access-token");

        assertThat(response.accessToken()).isNotBlank();
        assertThat(response.refreshToken()).isNotBlank();
        assertThat(response.accessToken().split("\\.")).hasSize(3);
        assertThat(response.refreshToken().split("\\.")).hasSize(3);
        assertThat(response.user().id()).isEqualTo(123L);
        assertThat(response.user().email()).isEqualTo("user@email.com");
        assertThat(response.user().nickname()).isEqualTo("감자러버");
        assertThat(response.user().profileImage()).isEqualTo("https://example.com/profile.png");
    }
}
