package com.gamjamubwatna.spot.api;

import com.gamjamubwatna.spot.application.SpotTourInfo;
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
    Boolean stampEnabled,
    String description,
    String openingHours,
    String closedDays,
    String admissionFee,
    String parking,
    String contactPhone
) {

    public static SpotDetailResponse from(TouristSpot spot, String imageUrl, SpotTourInfo tourInfo) {
        return new SpotDetailResponse(
            spot.getId(),
            spot.getContentId(),
            spot.getName(),
            spot.getCategory(),
            spot.getLatitude(),
            spot.getLongitude(),
            spot.getAddress(),
            spot.getCityName(),
            imageUrl,
            spot.getPotatoTags(),
            spot.getCongestionLevel(),
            spot.getVerificationRadiusMeter(),
            spot.getStampEnabled(),
            tourInfo.description(),
            tourInfo.openingHours(),
            tourInfo.closedDays(),
            tourInfo.admissionFee(),
            tourInfo.parking(),
            tourInfo.contactPhone()
        );
    }
}
