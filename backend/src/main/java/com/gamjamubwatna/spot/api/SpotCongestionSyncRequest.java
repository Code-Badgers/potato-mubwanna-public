package com.gamjamubwatna.spot.api;

import java.time.LocalDate;

public record SpotCongestionSyncRequest(
    LocalDate predictionDate,
    Integer predictedVisitors,
    Integer baselineVisitors,
    String source
) {
}
