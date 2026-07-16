package com.gamjamubwatna.spot.api;

import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import java.math.BigDecimal;

public record SpotRecommendationResponse(
    Long spotId,
    String name,
    SpotCategory category,
    BigDecimal latitude,
    BigDecimal longitude,
    String address,
    String cityName,
    String imageUrl,
    int externalRank
) {

    public static SpotRecommendationResponse from(TouristSpot spot, int externalRank) {
        return new SpotRecommendationResponse(
            spot.getId(),
            spot.getName(),
            spot.getCategory(),
            spot.getLatitude(),
            spot.getLongitude(),
            spot.getAddress(),
            spot.getCityName(),
            spot.getImageUrl(),
            externalRank
        );
    }
}
