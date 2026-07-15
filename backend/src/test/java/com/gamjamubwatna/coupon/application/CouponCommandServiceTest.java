package com.gamjamubwatna.coupon.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.coupon.api.CouponDetailResponse;
import com.gamjamubwatna.coupon.api.CouponQrResponse;
import com.gamjamubwatna.coupon.domain.Coupon;
import com.gamjamubwatna.coupon.domain.CouponDisplayStatus;
import com.gamjamubwatna.coupon.domain.UserCoupon;
import com.gamjamubwatna.coupon.domain.UserCouponRepository;
import com.gamjamubwatna.coupon.domain.UserCouponStatus;
import com.gamjamubwatna.coupon.infrastructure.CouponQrTokenProvider;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class CouponCommandServiceTest {

    private static final Instant NOW = Instant.parse("2026-07-15T00:00:00Z");

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserCouponRepository userCouponRepository;

    private CouponQrTokenProvider tokenProvider;
    private CouponCommandService service;

    @BeforeEach
    void setUp() {
        Clock clock = Clock.fixed(NOW, ZoneOffset.UTC);
        tokenProvider = new CouponQrTokenProvider(
            new ObjectMapper(),
            clock,
            "test-coupon-qr-secret-must-be-long-enough",
            300
        );
        service = new CouponCommandService(
            userRepository,
            userCouponRepository,
            tokenProvider,
            clock
        );
        org.mockito.Mockito.lenient().when(userRepository.existsById(1L)).thenReturn(true);
    }

    @Test
    void createsQrOnlyForAvailableOwnedCoupon() {
        UserCoupon coupon = userCoupon(3L, UserCouponStatus.AVAILABLE, NOW.plusSeconds(600), null);
        when(userCouponRepository.findByIdAndUserId(3L, 1L)).thenReturn(Optional.of(coupon));

        CouponQrResponse response = service.getQr(1L, 3L);

        assertThat(response.userCouponId()).isEqualTo(3L);
        assertThat(response.expiresAt()).isEqualTo(NOW.plusSeconds(300));
        assertThat(response.payload()).isNotBlank();
    }

    @Test
    void rejectsQrForExpiredCoupon() {
        UserCoupon coupon = userCoupon(3L, UserCouponStatus.AVAILABLE, NOW, null);
        when(userCouponRepository.findByIdAndUserId(3L, 1L)).thenReturn(Optional.of(coupon));

        assertThatThrownBy(() -> service.getQr(1L, 3L))
            .isInstanceOf(CouponConflictException.class)
            .hasMessage("사용 가능한 쿠폰만 QR을 확인할 수 있습니다.");
    }

    @Test
    void usesCouponOnceWithMatchingPayload() {
        UserCoupon coupon = userCoupon(3L, UserCouponStatus.AVAILABLE, NOW.plusSeconds(600), null);
        String payload = tokenProvider.create(3L, 1L, coupon.getExpiresAt()).payload();
        when(userCouponRepository.findByIdAndUserIdForUpdate(3L, 1L))
            .thenReturn(Optional.of(coupon));

        CouponDetailResponse response = service.useCoupon(1L, 3L, payload);

        assertThat(response.status()).isEqualTo(CouponDisplayStatus.USED);
        assertThat(response.usedAt()).isEqualTo(NOW);
    }

    @Test
    void rejectsDuplicateUseAndPayloadForAnotherCoupon() {
        UserCoupon usedCoupon = userCoupon(3L, UserCouponStatus.USED, NOW.plusSeconds(600), NOW);
        String matchingPayload = tokenProvider.create(3L, 1L, usedCoupon.getExpiresAt()).payload();
        when(userCouponRepository.findByIdAndUserIdForUpdate(3L, 1L))
            .thenReturn(Optional.of(usedCoupon));

        assertThatThrownBy(() -> service.useCoupon(1L, 3L, matchingPayload))
            .isInstanceOf(CouponConflictException.class)
            .hasMessage("이미 사용한 쿠폰입니다.");

        String otherCouponPayload = tokenProvider.create(9L, 1L, NOW.plusSeconds(600))
            .payload();

        assertThatThrownBy(() -> service.useCoupon(1L, 3L, otherCouponPayload))
            .isInstanceOf(CouponConflictException.class)
            .hasMessage("쿠폰 QR payload가 일치하지 않습니다.");
        verify(userCouponRepository).findByIdAndUserIdForUpdate(3L, 1L);
    }

    @Test
    void hidesCouponNotOwnedByUser() {
        String payload = tokenProvider.create(9L, 1L, NOW.plusSeconds(600)).payload();
        when(userCouponRepository.findByIdAndUserIdForUpdate(9L, 1L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.useCoupon(1L, 9L, payload))
            .isInstanceOf(CouponNotFoundException.class);
    }

    @Test
    void rejectsInvalidPayloadBeforeAcquiringCouponLock() {
        assertThatThrownBy(() -> service.useCoupon(1L, 3L, "invalid-payload"))
            .isInstanceOf(CouponConflictException.class)
            .hasMessage("쿠폰 QR payload가 유효하지 않거나 만료되었습니다.");

        verify(userCouponRepository, never()).findByIdAndUserIdForUpdate(3L, 1L);
    }

    private UserCoupon userCoupon(
        Long id,
        UserCouponStatus status,
        Instant expiresAt,
        Instant usedAt
    ) {
        Coupon coupon = new Coupon(
            "감자빵 1개 교환권",
            "제휴 매장에서 사용할 수 있습니다.",
            5000,
            "감자마을 제휴점"
        );
        UserCoupon userCoupon = new UserCoupon(
            mock(User.class),
            coupon,
            status,
            NOW.minusSeconds(600),
            expiresAt,
            usedAt
        );
        ReflectionTestUtils.setField(userCoupon, "id", id);
        return userCoupon;
    }
}
