package com.gamjamubwatna.spot.api;

public record SpotRouteEstimateResponse(
    int distanceMeters,
    int durationSeconds,
    String source
) {
}
