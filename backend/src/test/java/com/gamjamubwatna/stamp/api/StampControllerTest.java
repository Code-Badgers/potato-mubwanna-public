package com.gamjamubwatna.stamp.api;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.stamp.application.StampQueryService;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(StampController.class)
class StampControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private StampQueryService stampQueryService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void returnsAuthenticatedUsersStampBook() throws Exception {
        when(stampQueryService.getStampBook(eq(1L))).thenReturn(new StampBookResponse(
            18,
            1,
            List.of(new StampItemResponse(
                1L,
                "강릉시",
                "하지감자",
                null,
                true,
                Instant.parse("2026-06-30T00:00:00Z")
            ))
        ));

        mockMvc.perform(get("/stamps/me").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.message").value("요청이 성공했습니다."))
            .andExpect(jsonPath("$.data.totalCount").value(18))
            .andExpect(jsonPath("$.data.acquiredCount").value(1))
            .andExpect(jsonPath("$.data.stamps[0].cityName").value("강릉시"))
            .andExpect(jsonPath("$.data.stamps[0].acquired").value(true));
    }

    @Test
    void returnsAuthenticatedUsersNextRewardStatus() throws Exception {
        when(stampQueryService.getRewardStatus(eq(1L)))
            .thenReturn(new StampRewardStatusResponse(8, 12, 4, false));

        mockMvc.perform(get("/stamps/rewards/check").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.acquiredCount").value(8))
            .andExpect(jsonPath("$.data.nextTargetCount").value(12))
            .andExpect(jsonPath("$.data.remainingCount").value(4))
            .andExpect(jsonPath("$.data.completed").value(false));
    }

    @Test
    void rejectsMalformedUserPrincipal() throws Exception {
        mockMvc.perform(get("/stamps/me").with(user("admin:1")))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증 정보를 확인할 수 없습니다."));
    }

    @Test
    void doesNotHideUnexpectedServiceFailure() {
        doThrow(new IllegalStateException("database unavailable"))
            .when(stampQueryService).getStampBook(1L);

        assertThatThrownBy(() -> mockMvc.perform(get("/stamps/me").with(user("user:1"))))
            .hasCauseInstanceOf(IllegalStateException.class);
    }
}
