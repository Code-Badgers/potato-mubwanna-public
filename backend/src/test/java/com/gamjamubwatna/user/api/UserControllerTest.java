package com.gamjamubwatna.user.api;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.doThrow;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.user.application.UserAccountService;
import com.gamjamubwatna.user.application.UserActivitySummaryService;
import com.gamjamubwatna.user.application.UserProfileAuthenticationException;
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
    private UserActivitySummaryService userActivitySummaryService;

    @MockitoBean
    private UserAccountService userAccountService;

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
    void getMyActivitySummaryReturnsAuthenticatedUserSummary() throws Exception {
        when(userActivitySummaryService.getActivitySummary(eq(1L)))
            .thenReturn(new UserActivitySummaryResponse(256_842L, 12, 7L));

        mockMvc.perform(get("/users/me/activity-summary").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.totalSteps").value(256842))
            .andExpect(jsonPath("$.data.stampCount").value(12))
            .andExpect(jsonPath("$.data.ownedPotatoCount").value(7));
    }

    @Test
    void getMyActivitySummaryRejectsUnauthenticatedRequest() throws Exception {
        mockMvc.perform(get("/users/me/activity-summary"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void getMyActivitySummaryRejectsDeletedUser() throws Exception {
        doThrow(new UserProfileAuthenticationException("사용자를 찾을 수 없습니다."))
            .when(userActivitySummaryService).getActivitySummary(1L);

        mockMvc.perform(get("/users/me/activity-summary").with(user("user:1")))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증 정보를 확인할 수 없습니다."));
    }

    @Test
    void getMyProfileDoesNotHideUnexpectedServiceFailure() {
        doThrow(new IllegalStateException("database unavailable"))
            .when(userProfileService).getProfile(1L);

        assertThatThrownBy(() -> mockMvc.perform(get("/users/me").with(user("user:1"))))
            .hasCauseInstanceOf(IllegalStateException.class);
    }

    @Test
    void withdrawDeletesAuthenticatedUserAccount() throws Exception {
        mockMvc.perform(delete("/users/me").with(user("user:1")).with(csrf()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.message").value("요청이 성공했습니다."))
            .andExpect(jsonPath("$.data").doesNotExist());

        verify(userAccountService).withdraw(1L);
    }

    @Test
    void withdrawRejectsUnauthenticatedRequest() throws Exception {
        mockMvc.perform(delete("/users/me").with(csrf()))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void withdrawRejectsDeletedUser() throws Exception {
        doThrow(new UserProfileAuthenticationException("사용자를 찾을 수 없습니다."))
            .when(userAccountService).withdraw(1L);

        mockMvc.perform(delete("/users/me").with(user("user:1")).with(csrf()))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증 정보를 확인할 수 없습니다."));
    }
}
