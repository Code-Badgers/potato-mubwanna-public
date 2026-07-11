package com.gamjamubwatna.reward.api;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.mission.domain.MissionRewardType;
import com.gamjamubwatna.reward.application.RewardHistoryService;
import com.gamjamubwatna.reward.domain.RewardSourceType;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(RewardController.class)
class RewardControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private RewardHistoryService rewardHistoryService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void getRewardHistoryReturnsAuthenticatedUsersRewards() throws Exception {
        when(rewardHistoryService.getRewardHistory(eq(1L)))
            .thenReturn(new RewardHistoryListResponse(List.of(
                new RewardHistoryResponse(
                    1L,
                    MissionRewardType.POTATO,
                    "수미감자 씨앗",
                    RewardSourceType.MISSION,
                    1001L,
                    Instant.parse("2026-07-11T09:00:00Z")
                )
            )));

        mockMvc.perform(get("/rewards/history").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.rewards[0].rewardHistoryId").value(1))
            .andExpect(jsonPath("$.data.rewards[0].rewardType").value("POTATO"))
            .andExpect(jsonPath("$.data.rewards[0].rewardName").value("수미감자 씨앗"))
            .andExpect(jsonPath("$.data.rewards[0].sourceType").value("MISSION"))
            .andExpect(jsonPath("$.data.rewards[0].sourceId").value(1001))
            .andExpect(jsonPath("$.data.rewards[0].createdAt").value("2026-07-11T09:00:00Z"));
    }

    @Test
    void getRewardHistoryRejectsUnauthenticatedRequest() throws Exception {
        mockMvc.perform(get("/rewards/history"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void getRewardHistoryRejectsMalformedUserPrincipal() throws Exception {
        mockMvc.perform(get("/rewards/history").with(user("admin:1")))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false));
    }
}
