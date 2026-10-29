package com.gamjamubwatna.auth.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamjamubwatna.auth.application.AuthService;
import com.gamjamubwatna.auth.application.InvalidRefreshTokenException;
import com.gamjamubwatna.auth.infrastructure.JwtAuthenticationFilter;
import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.global.config.SecurityConfig;
import jakarta.servlet.DispatcherType;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

@WebMvcTest(AuthController.class)
@AutoConfigureMockMvc
@Import({SecurityConfig.class, JwtAuthenticationFilter.class})
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockitoBean
    private AuthService authService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void loginWithKakaoReturnsJwtTokens() throws Exception {
        when(authService.loginWithKakao(eq("kakao-access-token")))
            .thenReturn(new AuthLoginResponse(
                "jwt-access-token",
                "jwt-refresh-token",
                new AuthUserResponse(
                    1L,
                    "user@email.com",
                    "감자러버",
                    "https://example.com/profile.png"
                )
            ));

        mockMvc.perform(post("/auth/kakao")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(
                    new KakaoLoginRequest("kakao-access-token")
                )))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.message").value("요청이 성공했습니다."))
            .andExpect(jsonPath("$.data.accessToken").value("jwt-access-token"))
            .andExpect(jsonPath("$.data.refreshToken").value("jwt-refresh-token"))
            .andExpect(jsonPath("$.data.user.id").value(1))
            .andExpect(jsonPath("$.data.user.email").value("user@email.com"))
            .andExpect(jsonPath("$.data.user.nickname").value("감자러버"))
            .andExpect(jsonPath("$.data.user.profileImage").value("https://example.com/profile.png"));
    }

    @Test
    void loginWithKakaoRejectsBlankAccessToken() throws Exception {
        mockMvc.perform(post("/auth/kakao")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(
                    new KakaoLoginRequest("")
                )))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.data.accessToken").doesNotExist());
    }

    @Test
    void errorDispatchDoesNotReplaceLoginFailureWithAuthenticationError() throws Exception {
        var response = mockMvc.perform(get("/error")
                .with(request -> {
                    request.setDispatcherType(DispatcherType.ERROR);
                    return request;
                }))
            .andReturn()
            .getResponse();

        assertThat(response.getStatus()).isNotEqualTo(401);
        assertThat(response.getContentAsString()).doesNotContain("인증이 필요합니다.");
    }

    @Test
    void loginWithKakaoAuthorizationCodeReturnsJwtTokens() throws Exception {
        when(authService.loginWithKakaoAuthorizationCode(
            eq("authorization-code"),
            eq("http://localhost:54631/")
        )).thenReturn(new AuthLoginResponse(
            "jwt-access-token",
            "jwt-refresh-token",
            new AuthUserResponse(1L, null, "감자러버", null)
        ));

        mockMvc.perform(post("/auth/kakao/code")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(
                    new KakaoAuthorizationCodeRequest(
                        "authorization-code",
                        "http://localhost:54631/"
                    )
                )))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.accessToken").value("jwt-access-token"))
            .andExpect(jsonPath("$.data.refreshToken").value("jwt-refresh-token"));
    }

    @Test
    void loginWithKakaoAuthorizationCodeRejectsBlankCode() throws Exception {
        mockMvc.perform(post("/auth/kakao/code")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(
                    new KakaoAuthorizationCodeRequest("", "http://localhost:54631/")
                )))
            .andExpect(status().isBadRequest());
    }

    @Test
    void securityFiltersStillProtectAuthenticatedEndpoints() throws Exception {
        mockMvc.perform(get("/users/me"))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증이 필요합니다."));

        verifyNoInteractions(authService);
    }

    @Test
    void refreshReturnsRotatedJwtTokens() throws Exception {
        when(authService.refresh(eq("old-refresh-token")))
            .thenReturn(new AuthLoginResponse(
                "new-access-token",
                "new-refresh-token",
                new AuthUserResponse(
                    1L,
                    "user@email.com",
                    "감자러버",
                    "https://example.com/profile.png"
                )
            ));

        mockMvc.perform(post("/auth/refresh")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(
                    new RefreshTokenRequest("old-refresh-token")
                )))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.accessToken").value("new-access-token"))
            .andExpect(jsonPath("$.data.refreshToken").value("new-refresh-token"));
    }

    @Test
    void refreshReturnsUnauthorizedForAnInvalidRefreshToken() throws Exception {
        when(authService.refresh("invalid-token")).thenThrow(new InvalidRefreshTokenException());

        mockMvc.perform(post("/auth/refresh")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(new RefreshTokenRequest("invalid-token"))))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("로그인 세션이 만료되었습니다. 다시 로그인해주세요."))
            .andExpect(jsonPath("$.data").doesNotExist());
    }
}
