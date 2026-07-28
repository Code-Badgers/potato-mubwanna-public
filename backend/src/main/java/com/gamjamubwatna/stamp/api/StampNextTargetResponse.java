package com.gamjamubwatna.stamp.api;

import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;

public record StampNextTargetResponse(
    Long spotId,
    String spotName,
    String cityName,
    SpotCategory category,
    String address,
    String imageUrl
) {

    public static StampNextTargetResponse from(TouristSpot spot) {
        return new StampNextTargetResponse(
            spot.getId(),
            spot.getName(),
            spot.getCityName(),
            spot.getCategory(),
            spot.getAddress(),
            spot.getImageUrl()
        );
    }
}
