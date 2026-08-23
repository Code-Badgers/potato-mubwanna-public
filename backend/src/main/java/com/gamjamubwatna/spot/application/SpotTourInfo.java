package com.gamjamubwatna.spot.application;

public record SpotTourInfo(
    String description,
    String openingHours,
    String closedDays,
    String admissionFee,
    String parking,
    String contactPhone
) {
    public static SpotTourInfo empty() {
        return new SpotTourInfo(null, null, null, null, null, null);
    }
}
