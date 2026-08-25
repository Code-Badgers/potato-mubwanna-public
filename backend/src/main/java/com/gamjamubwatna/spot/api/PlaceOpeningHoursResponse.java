package com.gamjamubwatna.spot.api;

import com.gamjamubwatna.spot.application.PlaceOpeningHours;
import java.util.List;

public record PlaceOpeningHoursResponse(
    Boolean openNow,
    String todayText,
    List<String> weekdayDescriptions
) {

    public static PlaceOpeningHoursResponse from(PlaceOpeningHours openingHours) {
        if (openingHours == null) {
            return new PlaceOpeningHoursResponse(null, null, List.of());
        }
        return new PlaceOpeningHoursResponse(
            openingHours.openNow(),
            openingHours.todayText(),
            openingHours.weekdayDescriptions() == null ? List.of() : List.copyOf(openingHours.weekdayDescriptions())
        );
    }
}
