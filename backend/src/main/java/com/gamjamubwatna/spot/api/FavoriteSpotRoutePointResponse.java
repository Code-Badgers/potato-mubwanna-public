package com.gamjamubwatna.spot.api;

import java.math.BigDecimal;

public record FavoriteSpotRoutePointResponse(
    BigDecimal latitude,
    BigDecimal longitude
) {
}
