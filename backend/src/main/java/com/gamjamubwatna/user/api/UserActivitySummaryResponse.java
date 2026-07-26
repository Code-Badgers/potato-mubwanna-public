package com.gamjamubwatna.user.api;

public record UserActivitySummaryResponse(
    long totalSteps,
    int stampCount,
    long ownedPotatoCount
) {
}
