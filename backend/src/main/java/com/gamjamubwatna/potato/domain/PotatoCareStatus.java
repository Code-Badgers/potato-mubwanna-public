package com.gamjamubwatna.potato.domain;

import java.time.Instant;

public record PotatoCareStatus(
    int satiety,
    int moisture,
    int mood,
    Instant calculatedAt
) {

    public PotatoCareStatus {
        validateScore(satiety, "satiety");
        validateScore(moisture, "moisture");
        validateScore(mood, "mood");
        if (calculatedAt == null) {
            throw new IllegalArgumentException("Care status calculation time is required");
        }
    }

    private static void validateScore(int score, String label) {
        if (score < 0 || score > 100) {
            throw new IllegalArgumentException(label + " must be between 0 and 100");
        }
    }
}
