package com.gamjamubwatna.spot.api;

import com.gamjamubwatna.spot.domain.CongestionLevel;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
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
    CongestionLevel congestionLevel,
    Boolean stampEnabled,
    List<SpotMenuItemResponse> menuItems
) {

    public static SpotListResponse from(
        TouristSpot spot,
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
            spot.getCongestionLevel(),
            spot.getStampEnabled(),
            List.copyOf(menuItems)
        );
    }
}
