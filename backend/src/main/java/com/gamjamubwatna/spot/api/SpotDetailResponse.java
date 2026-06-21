package com.gamjamubwatna.spot.api;

import com.gamjamubwatna.spot.domain.CongestionLevel;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import java.math.BigDecimal;

public record SpotDetailResponse(
    Long id,
    String contentId,
    String name,
    SpotCategory category,
    BigDecimal latitude,
    BigDecimal longitude,
    String address,
    String cityName,
    String imageUrl,
    String potatoTags,
    CongestionLevel congestionLevel,
    Integer verificationRadiusMeter,
    Boolean stampEnabled
) {

    public static SpotDetailResponse from(TouristSpot spot) {
        return new SpotDetailResponse(
            spot.getId(),
            spot.getContentId(),
            spot.getName(),
            spot.getCategory(),
            spot.getLatitude(),
            spot.getLongitude(),
            spot.getAddress(),
            spot.getCityName(),
            spot.getImageUrl(),
            spot.getPotatoTags(),
            spot.getCongestionLevel(),
            spot.getVerificationRadiusMeter(),
            spot.getStampEnabled()
        );
    }
}
