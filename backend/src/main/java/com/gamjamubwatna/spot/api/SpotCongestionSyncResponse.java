package com.gamjamubwatna.spot.api;

import com.gamjamubwatna.spot.domain.CongestionLevel;
import com.gamjamubwatna.spot.domain.SpotCongestionPrediction;
import java.time.LocalDate;

public record SpotCongestionSyncResponse(
    Long touristSpotId,
    LocalDate predictionDate,
    Integer predictedVisitors,
    Integer baselineVisitors,
    CongestionLevel congestionLevel,
    String source
) {

    public static SpotCongestionSyncResponse from(SpotCongestionPrediction prediction) {
        return new SpotCongestionSyncResponse(
            prediction.getTouristSpot().getId(),
            prediction.getPredictionDate(),
            prediction.getPredictedVisitors(),
            prediction.getBaselineVisitors(),
            prediction.getCongestionLevel(),
            prediction.getSource()
        );
    }
}
