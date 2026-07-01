package com.gamjamubwatna.mission.api;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.mission.application.MissionAlreadyCompletedException;
import com.gamjamubwatna.mission.application.MissionService;
import com.gamjamubwatna.mission.domain.MissionGroup;
import com.gamjamubwatna.mission.domain.MissionRewardType;
import com.gamjamubwatna.mission.domain.MissionStatus;
import com.gamjamubwatna.mission.domain.MissionType;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(MissionController.class)
class MissionControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private MissionService missionService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void returnsAuthenticatedUsersMissions() throws Exception {
        when(missionService.getMissions(eq(1L))).thenReturn(new MissionListResponse(
            1,
            0,
            List.of(missionResponse(false))
        ));

        mockMvc.perform(get("/missions").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.totalCount").value(1))
            .andExpect(jsonPath("$.data.completedCount").value(0))
            .andExpect(jsonPath("$.data.missions[0].title").value("정선 5일장 곤드레 퀴즈"))
            .andExpect(jsonPath("$.data.missions[0].new").value(true))
            .andExpect(jsonPath("$.data.missions[0].completed").value(false));
    }

    @Test
    void returnsMissionDetail() throws Exception {
        when(missionService.getMission(eq(1L), eq(1L))).thenReturn(missionResponse(false));

        mockMvc.perform(get("/missions/1").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.missionId").value(1))
            .andExpect(jsonPath("$.data.code").value("MISSION_JEONGSEON_MARKET_QUIZ"));
    }

    @Test
    void completesMission() throws Exception {
        when(missionService.completeMission(eq(1L), eq(1L))).thenReturn(new MissionCompleteResponse(
            1L,
            true,
            Instant.parse("2026-07-01T00:00:00Z"),
            MissionRewardType.ITEM,
            "황금감자 성장 아이템"
        ));

        mockMvc.perform(post("/missions/1/complete").with(user("user:1")).with(csrf()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.completed").value(true))
            .andExpect(jsonPath("$.data.rewardLabel").value("황금감자 성장 아이템"));
    }

    @Test
    void rejectsDuplicateCompletion() throws Exception {
        when(missionService.completeMission(eq(1L), eq(1L)))
            .thenThrow(new MissionAlreadyCompletedException("이미 완료한 미션입니다."));

        mockMvc.perform(post("/missions/1/complete").with(user("user:1")).with(csrf()))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("이미 완료한 미션입니다."));
    }

    @Test
    void rejectsMalformedUserPrincipal() throws Exception {
        mockMvc.perform(get("/missions").with(user("admin:1")))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증 정보를 확인할 수 없습니다."));
    }

    private MissionItemResponse missionResponse(boolean completed) {
        return new MissionItemResponse(
            1L,
            "MISSION_JEONGSEON_MARKET_QUIZ",
            MissionGroup.JUMSOONI,
            MissionType.QUIZ,
            completed ? MissionStatus.COMPLETED : MissionStatus.READY,
            "정선 5일장 곤드레 퀴즈",
            "정선 5일장",
            "정선군",
            "정선 장터에서 점순이가 내는 향토 음식 퀴즈를 풀어보세요.",
            "여까지 왔네?",
            "퀴즈 1개 정답",
            MissionRewardType.ITEM,
            "황금감자 성장 아이템",
            completed ? 1 : 0,
            1,
            true,
            true,
            completed,
            completed ? Instant.parse("2026-07-01T00:00:00Z") : null
        );
    }
}
