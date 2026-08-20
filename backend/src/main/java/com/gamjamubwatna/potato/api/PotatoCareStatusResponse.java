package com.gamjamubwatna.potato.api;

import com.gamjamubwatna.potato.domain.PotatoCareStatus;
import java.time.Instant;

public record PotatoCareStatusResponse(
    int satiety,
    int moisture,
    int mood,
    Instant calculatedAt
) {

    public static PotatoCareStatusResponse from(PotatoCareStatus status) {
        return new PotatoCareStatusResponse(
            status.satiety(),
            status.moisture(),
            status.mood(),
            status.calculatedAt()
        );
    }
}
