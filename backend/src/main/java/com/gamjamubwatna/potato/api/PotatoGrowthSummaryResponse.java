package com.gamjamubwatna.potato.api;

public record PotatoGrowthSummaryResponse(
    int todaySteps,
    int dailyStepGoal,
    double weeklyDistanceKm,
    double monthlyDistanceKm,
    double remainingDistanceKmForRepresentative
) {
}
