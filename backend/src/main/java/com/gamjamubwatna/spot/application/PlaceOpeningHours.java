package com.gamjamubwatna.spot.application;

import java.util.List;

public record PlaceOpeningHours(
    Boolean openNow,
    String todayText,
    List<String> weekdayDescriptions
) {

    public static PlaceOpeningHours empty() {
        return new PlaceOpeningHours(null, null, List.of());
    }

    public boolean hasText() {
        return openNow != null
            || (todayText != null && !todayText.isBlank())
            || (weekdayDescriptions != null && !weekdayDescriptions.isEmpty());
    }
}
