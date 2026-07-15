package com.gamjamubwatna.coupon.api;

import com.gamjamubwatna.coupon.domain.Coupon;
import com.gamjamubwatna.coupon.domain.CouponDisplayStatus;
import com.gamjamubwatna.coupon.domain.UserCoupon;
import java.time.Instant;

public record CouponDetailResponse(
    Long userCouponId,
    String name,
    String description,
    int benefitAmount,
    CouponDisplayStatus status,
    Instant expiresAt,
    String usagePlace,
    Instant issuedAt,
    Instant usedAt
) {

    public static CouponDetailResponse from(UserCoupon userCoupon, Instant now) {
        Coupon coupon = userCoupon.getCoupon();
        return new CouponDetailResponse(
            userCoupon.getId(),
            coupon.getName(),
            coupon.getDescription(),
            coupon.getBenefitAmount(),
            userCoupon.displayStatus(now),
            userCoupon.getExpiresAt(),
            coupon.getUsagePlace(),
            userCoupon.getIssuedAt(),
            userCoupon.getUsedAt()
        );
    }
}
