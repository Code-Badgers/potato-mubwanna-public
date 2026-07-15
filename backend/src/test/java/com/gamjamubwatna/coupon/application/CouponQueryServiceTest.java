package com.gamjamubwatna.coupon.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.coupon.api.CouponDetailResponse;
import com.gamjamubwatna.coupon.api.CouponListResponse;
import com.gamjamubwatna.coupon.domain.Coupon;
import com.gamjamubwatna.coupon.domain.CouponDisplayStatus;
import com.gamjamubwatna.coupon.domain.UserCoupon;
import com.gamjamubwatna.coupon.domain.UserCouponRepository;
import com.gamjamubwatna.coupon.domain.UserCouponStatus;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class CouponQueryServiceTest {

    private static final Instant NOW = Instant.parse("2026-07-15T00:00:00Z");

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserCouponRepository userCouponRepository;

    private CouponQueryService couponQueryService;

    @BeforeEach
    void setUp() {
        couponQueryService = new CouponQueryService(
            userRepository,
            userCouponRepository,
            Clock.fixed(NOW, ZoneOffset.UTC)
        );
    }

    @Test
    void returnsAuthenticatedUsersCouponsWithDisplayStatus() {
        UserCoupon available = userCoupon(
            2L,
            UserCouponStatus.AVAILABLE,
            Instant.parse("2026-07-10T00:00:00Z"),
            Instant.parse("2026-08-10T00:00:00Z"),
            null
        );
        UserCoupon expired = userCoupon(
            1L,
            UserCouponStatus.AVAILABLE,
            Instant.parse("2026-06-01T00:00:00Z"),
            Instant.parse("2026-06-30T00:00:00Z"),
            null
        );
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userCouponRepository.findByUserIdOrderByIssuedAtDesc(1L))
            .thenReturn(List.of(available, expired));

        CouponListResponse result = couponQueryService.getMyCoupons(1L);

        assertThat(result.coupons()).hasSize(2);
        assertThat(result.coupons().get(0).userCouponId()).isEqualTo(2L);
        assertThat(result.coupons().get(0).status()).isEqualTo(CouponDisplayStatus.AVAILABLE);
        assertThat(result.coupons().get(1).status()).isEqualTo(CouponDisplayStatus.EXPIRED);
    }

    @Test
    void returnsOnlyCouponOwnedByAuthenticatedUser() {
        UserCoupon coupon = userCoupon(
            3L,
            UserCouponStatus.USED,
            Instant.parse("2026-07-01T00:00:00Z"),
            Instant.parse("2026-08-01T00:00:00Z"),
            Instant.parse("2026-07-12T00:00:00Z")
        );
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userCouponRepository.findByIdAndUserId(3L, 1L)).thenReturn(Optional.of(coupon));

        CouponDetailResponse result = couponQueryService.getCoupon(1L, 3L);

        assertThat(result.userCouponId()).isEqualTo(3L);
        assertThat(result.name()).isEqualTo("감자빵 1개 교환권");
        assertThat(result.benefitAmount()).isEqualTo(5000);
        assertThat(result.status()).isEqualTo(CouponDisplayStatus.USED);
        assertThat(result.usagePlace()).isEqualTo("감자마을 제휴점");
        assertThat(result.usedAt()).isEqualTo(Instant.parse("2026-07-12T00:00:00Z"));
    }

    @Test
    void hidesCouponNotOwnedByAuthenticatedUser() {
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userCouponRepository.findByIdAndUserId(9L, 1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> couponQueryService.getCoupon(1L, 9L))
            .isInstanceOf(CouponNotFoundException.class);
    }

    @Test
    void rejectsJwtSubjectForDeletedUser() {
        when(userRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> couponQueryService.getMyCoupons(99L))
            .isInstanceOf(CouponAuthenticationException.class);
    }

    private UserCoupon userCoupon(
        Long id,
        UserCouponStatus status,
        Instant issuedAt,
        Instant expiresAt,
        Instant usedAt
    ) {
        Coupon coupon = new Coupon(
            "감자빵 1개 교환권",
            "제휴 매장에서 사용할 수 있습니다.",
            5000,
            "감자마을 제휴점"
        );
        ReflectionTestUtils.setField(coupon, "id", 10L);
        UserCoupon userCoupon = new UserCoupon(
            mock(User.class),
            coupon,
            status,
            issuedAt,
            expiresAt,
            usedAt
        );
        ReflectionTestUtils.setField(userCoupon, "id", id);
        return userCoupon;
    }
}
