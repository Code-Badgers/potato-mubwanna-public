package com.gamjamubwatna.potato.api;

import com.gamjamubwatna.potato.domain.ActivitySource;
import java.time.LocalDate;

public record PotatoDailyActivitySyncRequest(
    LocalDate activityDate,
    Integer steps,
    Double distanceMeters,
    ActivitySource source
) {
}
