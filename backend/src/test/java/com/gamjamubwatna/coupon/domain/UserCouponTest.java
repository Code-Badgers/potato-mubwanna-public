package com.gamjamubwatna.coupon.domain;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;

import com.gamjamubwatna.auth.domain.User;
import java.time.Instant;
import org.junit.jupiter.api.Test;

class UserCouponTest {

    private static final Instant ISSUED_AT = Instant.parse("2026-07-15T00:00:00Z");
    private static final Instant EXPIRES_AT = Instant.parse("2026-08-15T00:00:00Z");

    @Test
    void rejectsExpirationThatIsNotAfterIssueTime() {
        assertThatThrownBy(() -> new UserCoupon(
            mock(User.class),
            mock(Coupon.class),
            UserCouponStatus.AVAILABLE,
            ISSUED_AT,
            ISSUED_AT,
            null
        ))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("만료 시간은 발급 시간보다 이후여야 합니다.");
    }

    @Test
    void rejectsUsedAtForAvailableCoupon() {
        assertThatThrownBy(() -> new UserCoupon(
            mock(User.class),
            mock(Coupon.class),
            UserCouponStatus.AVAILABLE,
            ISSUED_AT,
            EXPIRES_AT,
            Instant.parse("2026-07-16T00:00:00Z")
        ))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("사용 가능한 쿠폰은 사용 일시를 가질 수 없습니다.");
    }

    @Test
    void requiresUsedAtForUsedCoupon() {
        assertThatThrownBy(() -> new UserCoupon(
            mock(User.class),
            mock(Coupon.class),
            UserCouponStatus.USED,
            ISSUED_AT,
            EXPIRES_AT,
            null
        ))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("사용된 쿠폰은 사용 일시를 가져야 합니다.");
    }

    @Test
    void rejectsMissingRequiredReferences() {
        assertThatThrownBy(() -> new UserCoupon(
            null,
            mock(Coupon.class),
            UserCouponStatus.AVAILABLE,
            ISSUED_AT,
            EXPIRES_AT,
            null
        ))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("쿠폰 소유 사용자는 필수입니다.");
        assertThatThrownBy(() -> new UserCoupon(
            mock(User.class),
            null,
            UserCouponStatus.AVAILABLE,
            ISSUED_AT,
            EXPIRES_AT,
            null
        ))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("쿠폰 정보는 필수입니다.");
        assertThatThrownBy(() -> new UserCoupon(
            mock(User.class),
            mock(Coupon.class),
            null,
            ISSUED_AT,
            EXPIRES_AT,
            null
        ))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessage("쿠폰 상태는 필수입니다.");
    }

    @Test
    void marksAvailableCouponAsUsed() {
        UserCoupon coupon = new UserCoupon(
            mock(User.class),
            mock(Coupon.class),
            UserCouponStatus.AVAILABLE,
            ISSUED_AT,
            EXPIRES_AT,
            null
        );
        Instant usedAt = Instant.parse("2026-07-20T00:00:00Z");

        coupon.use(usedAt);

        assertThat(coupon.displayStatus(usedAt)).isEqualTo(CouponDisplayStatus.USED);
        assertThat(coupon.getUsedAt()).isEqualTo(usedAt);
    }

    @Test
    void rejectsUsingCouponMoreThanOnceOrAfterExpiration() {
        UserCoupon usedCoupon = new UserCoupon(
            mock(User.class),
            mock(Coupon.class),
            UserCouponStatus.USED,
            ISSUED_AT,
            EXPIRES_AT,
            Instant.parse("2026-07-20T00:00:00Z")
        );
        UserCoupon expiredCoupon = new UserCoupon(
            mock(User.class),
            mock(Coupon.class),
            UserCouponStatus.AVAILABLE,
            ISSUED_AT,
            EXPIRES_AT,
            null
        );

        assertThatThrownBy(() -> usedCoupon.use(Instant.parse("2026-07-21T00:00:00Z")))
            .isInstanceOf(IllegalStateException.class)
            .hasMessage("이미 사용한 쿠폰입니다.");
        assertThatThrownBy(() -> expiredCoupon.use(EXPIRES_AT))
            .isInstanceOf(IllegalStateException.class)
            .hasMessage("사용 기간이 만료된 쿠폰입니다.");
    }
}
