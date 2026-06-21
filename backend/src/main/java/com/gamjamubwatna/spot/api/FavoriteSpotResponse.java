package com.gamjamubwatna.spot.api;

import com.gamjamubwatna.spot.domain.FavoriteSpot;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import java.math.BigDecimal;
import java.time.Instant;

public record FavoriteSpotResponse(
    Long spotId,
    String name,
    SpotCategory category,
    BigDecimal latitude,
    BigDecimal longitude,
    Instant createdAt
) {

    public static FavoriteSpotResponse from(FavoriteSpot favoriteSpot) {
        TouristSpot spot = favoriteSpot.getTouristSpot();
        return new FavoriteSpotResponse(
            spot.getId(),
            spot.getName(),
            spot.getCategory(),
            spot.getLatitude(),
            spot.getLongitude(),
            favoriteSpot.getCreatedAt()
        );
    }
}
