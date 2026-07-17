package com.gamjamubwatna.stamp.domain;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.Set;

public enum StampRewardPolicy {
    SIX_STAMPS(6, "CP_STAMP_6_LOCAL_3000"),
    TWELVE_STAMPS(12, "CP_STAMP_12_LOCAL_5000"),
    EIGHTEEN_STAMPS(18, "CP_STAMP_18_COMPLETE_10000");

    private static final List<StampRewardPolicy> ORDERED_POLICIES = List.copyOf(
        Arrays.asList(values())
    );

    private final int targetCount;
    private final String couponCode;

    StampRewardPolicy(int targetCount, String couponCode) {
        this.targetCount = targetCount;
        this.couponCode = couponCode;
    }

    public int targetCount() {
        return targetCount;
    }

    public String couponCode() {
        return couponCode;
    }

    public static Optional<StampRewardPolicy> findByTargetCount(Integer targetCount) {
        if (targetCount == null) {
            return Optional.empty();
        }
        return ORDERED_POLICIES.stream()
            .filter(policy -> policy.targetCount == targetCount)
            .findFirst();
    }

    public static Integer nextTargetCount(int acquiredCount) {
        return ORDERED_POLICIES.stream()
            .map(StampRewardPolicy::targetCount)
            .filter(targetCount -> targetCount > acquiredCount)
            .findFirst()
            .orElse(null);
    }

    public static Integer claimableTargetCount(
        int acquiredCount,
        Set<Long> claimedTargetCounts
    ) {
        return ORDERED_POLICIES.stream()
            .map(StampRewardPolicy::targetCount)
            .filter(targetCount -> targetCount <= acquiredCount)
            .filter(targetCount -> !claimedTargetCounts.contains((long) targetCount))
            .findFirst()
            .orElse(null);
    }
}
