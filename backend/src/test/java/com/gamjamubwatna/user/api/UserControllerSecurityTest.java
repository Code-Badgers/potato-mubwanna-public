package com.gamjamubwatna.user.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.user.application.UserActivitySummaryService;
import com.gamjamubwatna.user.application.UserProfileAuthenticationException;
import com.gamjamubwatna.user.application.UserProfileService;
import java.nio.charset.StandardCharsets;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:user_controller_security;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
@AutoConfigureMockMvc
class UserControllerSecurityTest {

    private static final String JWT_SECRET = "test-jwt-secret-must-be-long-enough";

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @MockitoBean
    private UserProfileService userProfileService;

    @MockitoBean
    private UserActivitySummaryService userActivitySummaryService;

    @Test
    void returnsProfileThroughJwtSecurityFilter() throws Exception {
        when(userProfileService.getProfile(1L)).thenReturn(new UserProfileResponse(
            1L,
            "감자러버",
            "user@email.com",
            "https://example.com/profile.png",
            Instant.parse("2026-06-29T00:00:00Z")
        ));

        mockMvc.perform(get("/users/me")
                .header(HttpHeaders.AUTHORIZATION, bearerTokenFor(1L)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.userId").value(1))
            .andExpect(jsonPath("$.data.nickname").value("감자러버"));

        verify(userProfileService).getProfile(1L);
    }

    @Test
    void returnsUnauthorizedResponseWhenJwtUserNoLongerExists() throws Exception {
        doThrow(new UserProfileAuthenticationException("사용자를 찾을 수 없습니다."))
            .when(userProfileService).getProfile(1L);

        mockMvc.perform(get("/users/me")
                .header(HttpHeaders.AUTHORIZATION, bearerTokenFor(1L)))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증 정보를 확인할 수 없습니다."))
            .andExpect(jsonPath("$.data").doesNotExist());
    }

    @Test
    void rejectsRequestWithoutBearerTokenAsUnauthorized() throws Exception {
        mockMvc.perform(get("/users/me"))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증이 필요합니다."))
            .andExpect(header().string(
                HttpHeaders.CONTENT_TYPE,
                "application/json;charset=UTF-8"
            ))
            .andExpect(result -> assertThat(result.getResponse().getCharacterEncoding())
                .isEqualTo(StandardCharsets.UTF_8.name()));

        verifyNoInteractions(userProfileService);
    }

    @Test
    void rejectsInvalidBearerTokenAsUnauthorized() throws Exception {
        mockMvc.perform(get("/users/me")
                .header(HttpHeaders.AUTHORIZATION, "Bearer invalid-token"))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증이 필요합니다."));

        verifyNoInteractions(userProfileService);
    }

    @Test
    void rejectsExpiredBearerTokenAsUnauthorized() throws Exception {
        mockMvc.perform(get("/users/me")
                .header(HttpHeaders.AUTHORIZATION, expiredBearerTokenFor(1L)))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증이 필요합니다."));

        verifyNoInteractions(userProfileService);
    }

    private String bearerTokenFor(Long userId) {
        return "Bearer " + jwtTokenProvider.createAccessToken("user:" + userId);
    }

    private String expiredBearerTokenFor(Long userId) {
        JwtTokenProvider expiredTokenProvider = new JwtTokenProvider(
            new ObjectMapper(),
            Clock.fixed(Instant.parse("2020-01-01T00:00:00Z"), ZoneOffset.UTC),
            JWT_SECRET,
            1,
            1
        );
        return "Bearer " + expiredTokenProvider.createAccessToken("user:" + userId);
    }
}
