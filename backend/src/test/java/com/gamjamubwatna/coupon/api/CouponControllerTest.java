package com.gamjamubwatna.coupon.api;

import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamjamubwatna.auth.infrastructure.JwtTokenProvider;
import com.gamjamubwatna.coupon.application.CouponNotFoundException;
import com.gamjamubwatna.coupon.application.CouponCommandService;
import com.gamjamubwatna.coupon.application.CouponConflictException;
import com.gamjamubwatna.coupon.application.CouponQueryService;
import com.gamjamubwatna.coupon.domain.CouponDisplayStatus;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

@WebMvcTest(CouponController.class)
class CouponControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private CouponQueryService couponQueryService;

    @MockitoBean
    private CouponCommandService couponCommandService;

    @MockitoBean
    private JwtTokenProvider jwtTokenProvider;

    @Test
    void getMyCouponsReturnsAuthenticatedUsersCoupons() throws Exception {
        when(couponQueryService.getMyCoupons(eq(1L))).thenReturn(new CouponListResponse(List.of(
            new CouponSummaryResponse(
                1L,
                "감자빵 1개 교환권",
                "제휴 매장에서 사용할 수 있습니다.",
                5000,
                CouponDisplayStatus.AVAILABLE,
                Instant.parse("2026-12-31T23:59:59Z")
            )
        )));

        mockMvc.perform(get("/coupons/me").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data.coupons[0].userCouponId").value(1))
            .andExpect(jsonPath("$.data.coupons[0].name").value("감자빵 1개 교환권"))
            .andExpect(jsonPath("$.data.coupons[0].status").value("AVAILABLE"));
    }

    @Test
    void getCouponReturnsOwnedCouponDetail() throws Exception {
        when(couponQueryService.getCoupon(1L, 3L)).thenReturn(new CouponDetailResponse(
            3L,
            "감자빵 1개 교환권",
            "제휴 매장에서 사용할 수 있습니다.",
            5000,
            CouponDisplayStatus.USED,
            Instant.parse("2026-08-01T00:00:00Z"),
            "감자마을 제휴점",
            Instant.parse("2026-07-01T00:00:00Z"),
            Instant.parse("2026-07-12T00:00:00Z")
        ));

        mockMvc.perform(get("/coupons/3").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.userCouponId").value(3))
            .andExpect(jsonPath("$.data.usagePlace").value("감자마을 제휴점"))
            .andExpect(jsonPath("$.data.usedAt").value("2026-07-12T00:00:00Z"));
    }

    @Test
    void getCouponReturnsNotFoundForCouponNotOwnedByUser() throws Exception {
        when(couponQueryService.getCoupon(1L, 9L))
            .thenThrow(new CouponNotFoundException("쿠폰을 찾을 수 없습니다."));

        mockMvc.perform(get("/coupons/9").with(user("user:1")))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void getMyCouponsRejectsUnauthenticatedRequest() throws Exception {
        mockMvc.perform(get("/coupons/me"))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void getMyCouponsRejectsMalformedUserPrincipal() throws Exception {
        mockMvc.perform(get("/coupons/me").with(user("admin:1")))
            .andExpect(status().isUnauthorized())
            .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void getCouponQrReturnsSignedPayload() throws Exception {
        when(couponCommandService.getQr(1L, 3L)).thenReturn(new CouponQrResponse(
            3L,
            "signed-payload",
            Instant.parse("2026-07-15T00:05:00Z")
        ));

        mockMvc.perform(get("/coupons/3/qr").with(user("user:1")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.userCouponId").value(3))
            .andExpect(jsonPath("$.data.payload").value("signed-payload"))
            .andExpect(jsonPath("$.data.expiresAt").value("2026-07-15T00:05:00Z"));
    }

    @Test
    void useCouponReturnsUpdatedCouponAndRejectsConflict() throws Exception {
        CouponDetailResponse usedCoupon = new CouponDetailResponse(
            3L,
            "감자빵 1개 교환권",
            "제휴 매장에서 사용할 수 있습니다.",
            5000,
            CouponDisplayStatus.USED,
            Instant.parse("2026-08-01T00:00:00Z"),
            "감자마을 제휴점",
            Instant.parse("2026-07-01T00:00:00Z"),
            Instant.parse("2026-07-15T00:00:00Z")
        );
        when(couponCommandService.useCoupon(1L, 3L, "signed-payload"))
            .thenReturn(usedCoupon);

        mockMvc.perform(post("/coupons/3/use")
                .with(user("user:1"))
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"payload\":\"signed-payload\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.status").value("USED"))
            .andExpect(jsonPath("$.data.usedAt").value("2026-07-15T00:00:00Z"));

        when(couponCommandService.useCoupon(1L, 3L, "expired-payload"))
            .thenThrow(new CouponConflictException("쿠폰 QR payload가 유효하지 않거나 만료되었습니다."));

        mockMvc.perform(post("/coupons/3/use")
                .with(user("user:1"))
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"payload\":\"expired-payload\"}"))
            .andExpect(status().isConflict())
            .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void useCouponRejectsBlankPayload() throws Exception {
        mockMvc.perform(post("/coupons/3/use")
                .with(user("user:1"))
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"payload\":\"\"}"))
            .andExpect(status().isBadRequest());
    }
}
