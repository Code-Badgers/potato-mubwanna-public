package com.gamjamubwatna.spot.api;

import com.gamjamubwatna.spot.domain.CongestionLevel;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.application.ExternalPlaceDetails;
import java.math.BigDecimal;
import java.util.List;

public record SpotListResponse(
    Long id,
    String name,
    SpotCategory category,
    BigDecimal latitude,
    BigDecimal longitude,
    String address,
    String cityName,
    String imageUrl,
    List<String> imageUrls,
    CongestionLevel congestionLevel,
    Boolean stampEnabled,
    String phone,
    String website,
    Double rating,
    PlaceOpeningHoursResponse businessOpeningHours,
    List<SpotMenuItemResponse> menuItems
) {

    public static SpotListResponse from(
        TouristSpot spot,
        String imageUrl,
        List<String> imageUrls,
        ExternalPlaceDetails externalDetails,
        List<SpotMenuItemResponse> menuItems
    ) {
        return new SpotListResponse(
            spot.getId(),
            spot.getName(),
            spot.getCategory(),
            spot.getLatitude(),
            spot.getLongitude(),
            spot.getAddress(),
            spot.getCityName(),
            imageUrl,
            List.copyOf(imageUrls),
            spot.getCongestionLevel(),
            spot.getStampEnabled(),
            externalDetails.phone(),
            externalDetails.website(),
            externalDetails.rating(),
            PlaceOpeningHoursResponse.from(externalDetails.openingHours()),
            List.copyOf(menuItems)
        );
    }
}
