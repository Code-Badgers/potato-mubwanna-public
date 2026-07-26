package com.gamjamubwatna.spot.application;

public record TourismCongestionSyncResult(
    int targetSpotCount,
    int syncedSpotCount,
    int savedPredictionCount,
    int failedSpotCount
) {
}
