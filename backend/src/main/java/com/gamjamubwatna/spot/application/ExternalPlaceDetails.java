package com.gamjamubwatna.spot.application;

import java.util.List;

public record ExternalPlaceDetails(
    String googlePlaceId,
    String phone,
    String website,
    Double rating,
    PlaceOpeningHours openingHours,
    List<String> imageUrls
) {

    public static ExternalPlaceDetails empty() {
        return new ExternalPlaceDetails(null, null, null, null, PlaceOpeningHours.empty(), List.of());
    }

    public boolean hasBusinessInfo() {
        return hasText(phone)
            || hasText(website)
            || rating != null
            || openingHours.hasText();
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
