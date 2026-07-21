package com.gamjamubwatna.potato.api;

import com.gamjamubwatna.potato.domain.ActivitySource;
import com.gamjamubwatna.potato.domain.UserDailyActivity;
import java.time.Instant;
import java.time.LocalDate;

public record PotatoDailyActivitySyncResponse(
    LocalDate activityDate,
    int steps,
    double distanceMeters,
    ActivitySource source,
    Instant syncedAt
) {

    public static PotatoDailyActivitySyncResponse from(UserDailyActivity activity) {
        return new PotatoDailyActivitySyncResponse(
            activity.getActivityDate(),
            activity.getSteps(),
            activity.getDistanceMeters(),
            activity.getSource(),
            activity.getSyncedAt()
        );
    }
}
