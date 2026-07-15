package com.gamjamubwatna.coupon.api;

import java.time.Instant;

public record CouponQrResponse(
    Long userCouponId,
    String payload,
    Instant expiresAt
) {
}
