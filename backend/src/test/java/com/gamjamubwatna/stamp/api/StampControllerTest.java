package com.gamjamubwatna.stamp.api;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.stamp.application.StampQueryService;
import com.gamjamubwatna.stamp.application.StampRewardConfigurationException;
import com.gamjamubwatna.stamp.application.StampRewardConflictException;
import com.gamjamubwatna.stamp.application.StampRewardInvalidTargetException;
import com.gamjamubwatna.stamp.application.StampRewardService;
import java.math.BigDecimal;
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
    private StampRewardService stampRewardService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void returnsAuthenticatedUsersStampBook() throws Exception {
        when(stampQueryService.getStampBook(eq(1L))).thenReturn(new StampBookResponse(
            29,
            1,
            List.of(new StampItemResponse(
                1L,
                101L,
                "강릉시",
                "경포대",
                null,
                true,
                Instant.parse("2026-06-30T00:00:00Z")
            ))
        ));

        mockMvc.perform(get("/stamps/me").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.message").value("요청이 성공했습니다."))
            .andExpect(jsonPath("$.data.totalCount").value(29))
            .andExpect(jsonPath("$.data.acquiredCount").value(1))
            .andExpect(jsonPath("$.data.stamps[0].spotId").value(101))
            .andExpect(jsonPath("$.data.stamps[0].stampName").value("경포대"))
            .andExpect(jsonPath("$.data.stamps[0].cityName").value("강릉시"))
            .andExpect(jsonPath("$.data.stamps[0].acquired").value(true));
    }

    @Test
    void returnsAuthenticatedUsersNextRewardStatus() throws Exception {
        when(stampQueryService.getRewardStatus(eq(1L)))
            .thenReturn(new StampRewardStatusResponse(8, 12, 4, false, true, 6));

        mockMvc.perform(get("/stamps/rewards/check").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.acquiredCount").value(8))
            .andExpect(jsonPath("$.data.nextTargetCount").value(12))
            .andExpect(jsonPath("$.data.remainingCount").value(4))
            .andExpect(jsonPath("$.data.completed").value(false))
            .andExpect(jsonPath("$.data.claimable").value(true))
            .andExpect(jsonPath("$.data.claimableTargetCount").value(6));
    }

    @Test
    void returnsAuthenticatedUsersNextTargets() throws Exception {
        when(stampQueryService.getNextTargets(eq(1L))).thenReturn(List.of(
            new StampNextTargetResponse(
                101L,
                "정선 5일장",
                "정선군",
                com.gamjamubwatna.spot.domain.SpotCategory.POTATO_MARKET,
                "강원특별자치도 정선군",
                "https://example.com/101.jpg"
            )
        ));

        mockMvc.perform(get("/stamps/me/next-targets").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data[0].spotId").value(101))
            .andExpect(jsonPath("$.data[0].spotName").value("정선 5일장"))
            .andExpect(jsonPath("$.data[0].cityName").value("정선군"))
            .andExpect(jsonPath("$.data[0].category").value("POTATO_MARKET"));
    }

    @Test
    void returnsRallybookSpotsWithOfficialCoordinates() throws Exception {
        when(stampQueryService.getRallybookSpots(eq(1L))).thenReturn(List.of(
            new RallybookSpotResponse(
                101L,
                "남이섬",
                "춘천시",
                com.gamjamubwatna.spot.domain.SpotCategory.POTATO_TOUR,
                new BigDecimal("37.7962651"),
                new BigDecimal("127.5254892"),
                "강원특별자치도 춘천시 남이섬길 1 남이섬",
                "https://example.com/101.jpg"
            )
        ));

        mockMvc.perform(get("/stamps/rallybook-spots").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data[0].spotId").value(101))
            .andExpect(jsonPath("$.data[0].spotName").value("남이섬"))
            .andExpect(jsonPath("$.data[0].cityName").value("춘천시"))
            .andExpect(jsonPath("$.data[0].latitude").value(37.7962651))
            .andExpect(jsonPath("$.data[0].longitude").value(127.5254892));
    }

    @Test
    void claimsAchievedStampReward() throws Exception {
        when(stampRewardService.claimReward(eq(1L), eq(6)))
            .thenReturn(new StampRewardClaimResponse(
                6,
                10L,
                21L,
                "강원 감자 제휴점 3,000원 할인권",
                Instant.parse("2026-08-16T00:00:00Z")
            ));

        mockMvc.perform(post("/stamps/rewards/claim")
                .with(user("user:1"))
                .with(csrf())
                .contentType("application/json")
                .content("""
                    {"targetCount": 6}
                    """))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.targetCount").value(6))
            .andExpect(jsonPath("$.data.rewardHistoryId").value(10))
            .andExpect(jsonPath("$.data.userCouponId").value(21))
            .andExpect(jsonPath("$.data.couponName")
                .value("강원 감자 제휴점 3,000원 할인권"))
            .andExpect(jsonPath("$.data.expiresAt").value("2026-08-16T00:00:00Z"));
    }

    @Test
    void rejectsUnsupportedRewardTarget() throws Exception {
        when(stampRewardService.claimReward(eq(1L), eq(7)))
            .thenThrow(new StampRewardInvalidTargetException(
                "지원하지 않는 스탬프 보상 기준입니다."
            ));

        mockMvc.perform(post("/stamps/rewards/claim")
                .with(user("user:1"))
                .with(csrf())
                .contentType("application/json")
                .content("""
                    {"targetCount": 7}
                    """))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void rejectsMissingRewardTarget() throws Exception {
        when(stampRewardService.claimReward(eq(1L), org.mockito.ArgumentMatchers.isNull()))
            .thenThrow(new StampRewardInvalidTargetException(
                "지원하지 않는 스탬프 보상 기준입니다."
            ));

        mockMvc.perform(post("/stamps/rewards/claim")
                .with(user("user:1"))
                .with(csrf())
                .contentType("application/json")
                .content("{}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void mapsDuplicateRewardClaimToConflict() throws Exception {
        when(stampRewardService.claimReward(eq(1L), eq(6)))
            .thenThrow(new StampRewardConflictException("이미 수령한 스탬프 보상입니다."));

        mockMvc.perform(post("/stamps/rewards/claim")
                .with(user("user:1"))
                .with(csrf())
                .contentType("application/json")
                .content("""
                    {"targetCount": 6}
                    """))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message").value("이미 수령한 스탬프 보상입니다."));
    }

    @Test
    void mapsMissingPolicyCouponToServerError() throws Exception {
        when(stampRewardService.claimReward(eq(1L), eq(6)))
            .thenThrow(new StampRewardConfigurationException(
                "스탬프 보상 쿠폰 정보를 찾을 수 없습니다."
            ));

        mockMvc.perform(post("/stamps/rewards/claim")
                .with(user("user:1"))
                .with(csrf())
                .contentType("application/json")
                .content("""
                    {"targetCount": 6}
                    """))
            .andExpect(status().isInternalServerError())
            .andExpect(jsonPath("$.success").value(false))
            .andExpect(jsonPath("$.message")
                .value("스탬프 보상 쿠폰 정보를 찾을 수 없습니다."));
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
