package com.gamjamubwatna.stamp.api;

import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import java.math.BigDecimal;

public record RallybookSpotResponse(
    Long spotId,
    String spotName,
    String cityName,
    SpotCategory category,
    BigDecimal latitude,
    BigDecimal longitude,
    String address,
    String imageUrl
) {

    public static RallybookSpotResponse from(TouristSpot spot) {
        return new RallybookSpotResponse(
            spot.getId(),
            spot.getName(),
            spot.getCityName(),
            spot.getCategory(),
            spot.getLatitude(),
            spot.getLongitude(),
            spot.getAddress(),
            spot.getImageUrl()
        );
    }
}
