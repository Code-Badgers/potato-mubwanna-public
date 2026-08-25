package com.gamjamubwatna.spot.api;

import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import java.math.BigDecimal;
import java.util.List;

public record SpotRecommendationResponse(
    Long spotId,
    String name,
    SpotCategory category,
    BigDecimal latitude,
    BigDecimal longitude,
    String address,
    String cityName,
    String imageUrl,
    List<String> imageUrls,
    int externalRank
) {

    public static SpotRecommendationResponse from(
        TouristSpot spot,
        String imageUrl,
        List<String> imageUrls,
        int externalRank
    ) {
        return new SpotRecommendationResponse(
            spot.getId(),
            spot.getName(),
            spot.getCategory(),
            spot.getLatitude(),
            spot.getLongitude(),
            spot.getAddress(),
            spot.getCityName(),
            imageUrl,
            List.copyOf(imageUrls),
            externalRank
        );
    }
}
