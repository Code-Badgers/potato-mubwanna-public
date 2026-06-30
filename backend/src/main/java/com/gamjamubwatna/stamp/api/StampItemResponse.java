package com.gamjamubwatna.stamp.api;

import com.gamjamubwatna.stamp.domain.Stamp;
import com.gamjamubwatna.stamp.domain.UserStamp;
import java.time.Instant;

public record StampItemResponse(
    Long stampId,
    String cityName,
    String stampName,
    String stampImage,
    boolean acquired,
    Instant acquiredAt
) {

    public static StampItemResponse from(Stamp stamp, UserStamp userStamp) {
        return new StampItemResponse(
            stamp.getId(),
            stamp.getCityName(),
            stamp.getStampName(),
            stamp.getStampImage(),
            userStamp != null,
            userStamp == null ? null : userStamp.getAcquiredAt()
        );
    }
}
