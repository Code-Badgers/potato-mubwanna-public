package com.gamjamubwatna.user.api;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.doThrow;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.user.application.UserProfileService;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserProfileService userProfileService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void getMyProfileReturnsAuthenticatedUserProfile() throws Exception {
        when(userProfileService.getProfile(eq(1L)))
            .thenReturn(new UserProfileResponse(
                1L,
                "감자여행자",
                "user@example.com",
                "https://example.com/profile.png",
                Instant.parse("2026-06-23T00:00:00Z")
            ));

        mockMvc.perform(get("/users/me").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.message").value("요청이 성공했습니다."))
            .andExpect(jsonPath("$.data.userId").value(1))
            .andExpect(jsonPath("$.data.nickname").value("감자여행자"))
            .andExpect(jsonPath("$.data.email").value("user@example.com"))
            .andExpect(jsonPath("$.data.profileImage").value("https://example.com/profile.png"))
            .andExpect(jsonPath("$.data.createdAt").value("2026-06-23T00:00:00Z"));
    }

    @Test
    void getMyProfileRejectsUnauthenticatedRequest() throws Exception {
        mockMvc.perform(get("/users/me"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void getMyProfileRejectsMalformedUserPrincipal() throws Exception {
        mockMvc.perform(get("/users/me").with(user("admin:1")))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void getMyProfileDoesNotHideUnexpectedServiceFailure() {
        doThrow(new IllegalStateException("database unavailable"))
            .when(userProfileService).getProfile(1L);

        assertThatThrownBy(() -> mockMvc.perform(get("/users/me").with(user("user:1"))))
            .hasCauseInstanceOf(IllegalStateException.class);
    }
}
