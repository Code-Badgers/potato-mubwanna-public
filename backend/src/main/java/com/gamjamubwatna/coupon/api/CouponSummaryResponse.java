package com.gamjamubwatna.coupon.api;

import com.gamjamubwatna.coupon.domain.Coupon;
import com.gamjamubwatna.coupon.domain.CouponDisplayStatus;
import com.gamjamubwatna.coupon.domain.UserCoupon;
import java.time.Instant;

public record CouponSummaryResponse(
    Long userCouponId,
    String name,
    String description,
    int benefitAmount,
    CouponDisplayStatus status,
    Instant expiresAt
) {

    public static CouponSummaryResponse from(UserCoupon userCoupon, Instant now) {
        Coupon coupon = userCoupon.getCoupon();
        return new CouponSummaryResponse(
            userCoupon.getId(),
            coupon.getName(),
            coupon.getDescription(),
            coupon.getBenefitAmount(),
            userCoupon.displayStatus(now),
            userCoupon.getExpiresAt()
        );
    }
}
