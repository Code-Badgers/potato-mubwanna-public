package com.gamjamubwatna.potato.api;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.potato.application.PotatoActivityException;
import com.gamjamubwatna.potato.application.PotatoCommandService;
import com.gamjamubwatna.potato.application.PotatoInteractionCooldownException;
import com.gamjamubwatna.potato.application.PotatoInteractionException;
import com.gamjamubwatna.potato.application.PotatoQueryService;
import com.gamjamubwatna.potato.application.PotatoRepresentativeException;
import com.gamjamubwatna.potato.domain.ActivitySource;
import com.gamjamubwatna.potato.domain.PotatoInteractionAction;
import com.gamjamubwatna.potato.domain.PotatoRarity;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(PotatoController.class)
class PotatoControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private PotatoQueryService potatoQueryService;

    @MockitoBean
    private PotatoCommandService potatoCommandService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void returnsPotatoCatalog() throws Exception {
        when(potatoQueryService.getPotatoes()).thenReturn(new PotatoCatalogResponse(
            1,
            List.of(catalogItem())
        ));

        mockMvc.perform(get("/potatoes").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.totalCount").value(1))
            .andExpect(jsonPath("$.data.items[0].potatoId").value(1))
            .andExpect(jsonPath("$.data.items[0].name").value("하지감자"))
            .andExpect(jsonPath("$.data.items[0].rarity").value("COMMON"));
    }

    @Test
    void returnsAuthenticatedUsersPotatoCollection() throws Exception {
        when(potatoQueryService.getMyPotatoes(eq(1L))).thenReturn(new UserPotatoCollectionResponse(
            1,
            1,
            List.of(collectionItem())
        ));

        mockMvc.perform(get("/potatoes/me").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.acquiredCount").value(1))
            .andExpect(jsonPath("$.data.items[0].acquired").value(true))
            .andExpect(jsonPath("$.data.items[0].level").value(2))
            .andExpect(jsonPath("$.data.items[0].representative").value(true));
    }

    @Test
    void returnsAuthenticatedUsersPotatoGrowthSummary() throws Exception {
        when(potatoQueryService.getGrowthSummary(eq(1L)))
            .thenReturn(new PotatoGrowthSummaryResponse(7842, 10000, 28.4, 116.8, 1.5));

        mockMvc.perform(get("/potatoes/me/growth-summary").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.todaySteps").value(7842))
            .andExpect(jsonPath("$.data.dailyStepGoal").value(10000))
            .andExpect(jsonPath("$.data.weeklyDistanceKm").value(28.4))
            .andExpect(jsonPath("$.data.monthlyDistanceKm").value(116.8))
            .andExpect(jsonPath("$.data.remainingDistanceKmForRepresentative").value(1.5));
    }

    @Test
    void rejectsMalformedUserPrincipal() throws Exception {
        mockMvc.perform(get("/potatoes/me").with(user("admin:1")))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("인증 정보를 확인할 수 없습니다."));
    }

    @Test
    void syncsDailyActivity() throws Exception {
        when(potatoCommandService.syncDailyActivity(
            eq(1L),
            eq(new PotatoDailyActivitySyncRequest(
                LocalDate.parse("2026-07-21"),
                8420,
                5894.0,
                ActivitySource.HEALTH_CONNECT
            ))
        )).thenReturn(new PotatoDailyActivitySyncResponse(
            LocalDate.parse("2026-07-21"),
            8420,
            5894.0,
            ActivitySource.HEALTH_CONNECT,
            Instant.parse("2026-07-21T00:00:00Z"),
            new PotatoGrowthResultResponse(1L, "하지감자", 2, 3, true, false)
        ));

        mockMvc.perform(put("/potatoes/me/activity/daily")
                .with(user("user:1"))
                .with(csrf())
                .contentType("application/json")
                .content("""
                    {
                      "activityDate": "2026-07-21",
                      "steps": 8420,
                      "distanceMeters": 5894.0,
                      "source": "HEALTH_CONNECT"
                    }
                    """))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.activityDate").value("2026-07-21"))
            .andExpect(jsonPath("$.data.steps").value(8420))
            .andExpect(jsonPath("$.data.distanceMeters").value(5894.0))
            .andExpect(jsonPath("$.data.source").value("HEALTH_CONNECT"))
            .andExpect(jsonPath("$.data.growthResult.potatoId").value(1))
            .andExpect(jsonPath("$.data.growthResult.potatoName").value("하지감자"))
            .andExpect(jsonPath("$.data.growthResult.previousLevel").value(2))
            .andExpect(jsonPath("$.data.growthResult.currentLevel").value(3))
            .andExpect(jsonPath("$.data.growthResult.leveledUp").value(true))
            .andExpect(jsonPath("$.data.growthResult.fullyGrown").value(false));
    }

    @Test
    void rejectsInvalidDailyActivity() throws Exception {
        when(potatoCommandService.syncDailyActivity(
            eq(1L),
            eq(new PotatoDailyActivitySyncRequest(
                LocalDate.parse("2026-07-21"),
                -1,
                10.0,
                ActivitySource.HEALTH_CONNECT
            ))
        )).thenThrow(new PotatoActivityException("걸음 수가 허용 범위를 벗어났습니다."));

        mockMvc.perform(put("/potatoes/me/activity/daily")
                .with(user("user:1"))
                .with(csrf())
                .contentType("application/json")
                .content("""
                    {
                      "activityDate": "2026-07-21",
                      "steps": -1,
                      "distanceMeters": 10.0,
                      "source": "HEALTH_CONNECT"
                    }
                    """))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("걸음 수가 허용 범위를 벗어났습니다."));
    }

    @Test
    void updatesRepresentativePotato() throws Exception {
        when(potatoCommandService.updateRepresentativePotato(eq(1L), eq(2L)))
            .thenReturn(new PotatoRepresentativeResponse(2L, true));

        mockMvc.perform(patch("/potatoes/me/representative")
                .with(user("user:1"))
                .with(csrf())
                .contentType("application/json")
                .content("{\"potatoId\":2}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.potatoId").value(2))
            .andExpect(jsonPath("$.data.representative").value(true));
    }

    @Test
    void rejectsUnacquiredRepresentativePotato() throws Exception {
        when(potatoCommandService.updateRepresentativePotato(eq(1L), eq(99L)))
            .thenThrow(new PotatoRepresentativeException("획득한 감자만 대표 감자로 설정할 수 있습니다."));

        mockMvc.perform(patch("/potatoes/me/representative")
                .with(user("user:1"))
                .with(csrf())
                .contentType("application/json")
                .content("{\"potatoId\":99}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("획득한 감자만 대표 감자로 설정할 수 있습니다."));
    }

    @Test
    void interactsWithRepresentativePotato() throws Exception {
        when(potatoCommandService.interactWithRepresentativePotato(
            eq(1L),
            eq(new PotatoInteractionRequest(PotatoInteractionAction.PAT))
        )).thenReturn(new PotatoInteractionResponse(
            1L,
            "새싹감자",
            PotatoInteractionAction.PAT,
            50.0,
            1800,
            Instant.parse("2026-07-21T10:30:00Z"),
            new PotatoCareStatusResponse(
                70,
                66,
                100,
                Instant.parse("2026-07-21T10:00:00Z")
            ),
            new PotatoGrowthResultResponse(1L, "새싹감자", 2, 3, true, true)
        ));

        mockMvc.perform(post("/potatoes/me/representative/interactions")
                .with(user("user:1"))
                .with(csrf())
                .contentType("application/json")
                .content("{\"action\":\"PAT\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.potatoId").value(1))
            .andExpect(jsonPath("$.data.potatoName").value("새싹감자"))
            .andExpect(jsonPath("$.data.action").value("PAT"))
            .andExpect(jsonPath("$.data.growthDistanceAdded").value(50.0))
            .andExpect(jsonPath("$.data.cooldownSeconds").value(1800))
            .andExpect(jsonPath("$.data.nextAvailableAt").value("2026-07-21T10:30:00Z"))
            .andExpect(jsonPath("$.data.careStatus.mood").value(100))
            .andExpect(jsonPath("$.data.growthResult.currentLevel").value(3))
            .andExpect(jsonPath("$.data.growthResult.fullyGrown").value(true));
    }

    @Test
    void harvestsRepresentativePotato() throws Exception {
        when(potatoCommandService.harvestRepresentativePotato(eq(1L)))
            .thenReturn(new PotatoHarvestResponse(
                1L,
                "새싹감자",
                true,
                Instant.parse("2026-07-21T10:00:00Z")
            ));

        mockMvc.perform(post("/potatoes/me/representative/harvest")
                .with(user("user:1"))
                .with(csrf()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.potatoId").value(1))
            .andExpect(jsonPath("$.data.potatoName").value("새싹감자"))
            .andExpect(jsonPath("$.data.harvested").value(true))
            .andExpect(jsonPath("$.data.harvestedAt").value("2026-07-21T10:00:00Z"));
    }

    @Test
    void rejectsPotatoInteractionDuringCooldown() throws Exception {
        when(potatoCommandService.interactWithRepresentativePotato(
            eq(1L),
            eq(new PotatoInteractionRequest(PotatoInteractionAction.WATER))
        )).thenThrow(new PotatoInteractionCooldownException(
            "아직 다시 돌볼 수 없습니다. 잠시 후 다시 시도해주세요.",
            Instant.parse("2026-07-21T11:30:00Z")
        ));

        mockMvc.perform(post("/potatoes/me/representative/interactions")
                .with(user("user:1"))
                .with(csrf())
                .contentType("application/json")
                .content("{\"action\":\"WATER\"}"))
            .andExpect(status().isTooManyRequests())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("아직 다시 돌볼 수 없습니다. 잠시 후 다시 시도해주세요."));
    }

    @Test
    void rejectsInvalidPotatoInteraction() throws Exception {
        when(potatoCommandService.interactWithRepresentativePotato(
            eq(1L),
            eq(new PotatoInteractionRequest(PotatoInteractionAction.SNACK))
        )).thenThrow(new PotatoInteractionException("대표 감자를 먼저 설정해주세요."));

        mockMvc.perform(post("/potatoes/me/representative/interactions")
                .with(user("user:1"))
                .with(csrf())
                .contentType("application/json")
                .content("{\"action\":\"SNACK\"}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("대표 감자를 먼저 설정해주세요."));
    }

    private PotatoCatalogItemResponse catalogItem() {
        return new PotatoCatalogItemResponse(
            1L,
            "POTATO_HAJI_GANGNEUNG",
            "하지감자",
            "강릉시",
            PotatoRarity.COMMON,
            "강릉 여행길에서 처음 만나기 좋은 기본 감자입니다.",
            "강릉 감자 스팟 방문 인증",
            null,
            3000.0
        );
    }

    private UserPotatoCollectionItemResponse collectionItem() {
        return new UserPotatoCollectionItemResponse(
            1L,
            "POTATO_HAJI_GANGNEUNG",
            "하지감자",
            "강릉시",
            PotatoRarity.COMMON,
            "강릉 여행길에서 처음 만나기 좋은 기본 감자입니다.",
            "강릉 감자 스팟 방문 인증",
            null,
            true,
            Instant.parse("2026-07-01T00:00:00Z"),
            2,
            1500.0,
            3000.0,
            new PotatoCareStatusResponse(
                70,
                70,
                70,
                Instant.parse("2026-07-21T10:00:00Z")
            ),
            true,
            "GROWTH",
            false,
            true
        );
    }
}
