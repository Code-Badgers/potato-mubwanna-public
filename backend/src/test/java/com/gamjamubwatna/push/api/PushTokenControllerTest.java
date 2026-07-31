package com.gamjamubwatna.push.api;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.push.application.PushTokenRegistration;
import com.gamjamubwatna.push.application.PushTokenService;
import com.gamjamubwatna.push.application.PushTokenValidationException;
import com.gamjamubwatna.push.domain.PushPlatform;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(PushTokenController.class)
class PushTokenControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private PushTokenService pushTokenService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void registersAuthenticatedUsersPushToken() throws Exception {
        when(pushTokenService.register(
            1L,
            "current-token",
            PushPlatform.ANDROID,
            "previous-token"
        )).thenReturn(new PushTokenRegistration(
            PushPlatform.ANDROID,
            Instant.parse("2026-07-31T03:30:00Z")
        ));

        mockMvc.perform(post("/users/me/push-tokens")
                .with(user("user:1"))
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "token": "current-token",
                      "platform": "ANDROID",
                      "previousToken": "previous-token"
                    }
                    """))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.registered").value(true))
            .andExpect(jsonPath("$.data.platform").value("ANDROID"))
            .andExpect(jsonPath("$.data.registeredAt")
                .value("2026-07-31T03:30:00Z"));
    }

    @Test
    void rejectsUnauthenticatedRegistration() throws Exception {
        mockMvc.perform(post("/users/me/push-tokens")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "token": "current-token",
                      "platform": "ANDROID"
                    }
                    """))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void rejectsMalformedPrincipal() throws Exception {
        mockMvc.perform(post("/users/me/push-tokens")
                .with(user("admin:1"))
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "token": "current-token",
                      "platform": "ANDROID"
                    }
                    """))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void mapsInvalidTokenToBadRequest() throws Exception {
        doThrow(new PushTokenValidationException("푸시 토큰을 확인해주세요."))
            .when(pushTokenService).register(
                eq(1L),
                eq("bad token"),
                eq(PushPlatform.ANDROID),
                org.mockito.ArgumentMatchers.isNull()
            );

        mockMvc.perform(post("/users/me/push-tokens")
                .with(user("user:1"))
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "token": "bad token",
                      "platform": "ANDROID"
                    }
                    """))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.message").value("푸시 토큰을 확인해주세요."));
    }

    @Test
    void deletesAuthenticatedUsersPushToken() throws Exception {
        mockMvc.perform(delete("/users/me/push-tokens")
                .with(user("user:1"))
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {
                      "token": "current-token"
                    }
                    """))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data").doesNotExist());

        verify(pushTokenService).delete(1L, "current-token");
    }
}
