package com.gamjamubwatna.stamp.api;

import java.time.Instant;

public record StampRewardClaimResponse(
    int targetCount,
    Long rewardHistoryId,
    Long userCouponId,
    String couponName,
    Instant expiresAt
) {
}
