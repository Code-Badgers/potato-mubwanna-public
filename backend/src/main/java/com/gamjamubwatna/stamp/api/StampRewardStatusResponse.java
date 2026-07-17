package com.gamjamubwatna.stamp.api;

public record StampRewardStatusResponse(
    int acquiredCount,
    Integer nextTargetCount,
    int remainingCount,
    boolean completed,
    boolean claimable,
    Integer claimableTargetCount
) {
}
