package com.gamjamubwatna.visit.api;

import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.visit.domain.UserVisit;
import java.time.Instant;

public record VisitHistoryResponse(
    Long visitId,
    Long spotId,
    String spotName,
    String category,
    String cityName,
    String address,
    String imageUrl,
    Instant visitedAt
) {

    public static VisitHistoryResponse from(UserVisit visit) {
        TouristSpot spot = visit.getTouristSpot();
        return new VisitHistoryResponse(
            visit.getId(),
            spot.getId(),
            spot.getName(),
            spot.getCategory().name(),
            spot.getCityName(),
            spot.getAddress(),
            spot.getImageUrl(),
            visit.getVisitedAt()
        );
    }
}
