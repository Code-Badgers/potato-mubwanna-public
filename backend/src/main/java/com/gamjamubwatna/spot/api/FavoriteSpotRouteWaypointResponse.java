package com.gamjamubwatna.spot.api;

import com.gamjamubwatna.spot.domain.SpotCategory;
import java.math.BigDecimal;

public record FavoriteSpotRouteWaypointResponse(
    int order,
    Long spotId,
    String name,
    SpotCategory category,
    BigDecimal latitude,
    BigDecimal longitude,
    double distanceFromPreviousKm
) {
}
