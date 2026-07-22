package com.gamjamubwatna.visit.api;

import java.math.BigDecimal;

public record VisitVerifyResponse(
    Long spotId,
    boolean verified,
    BigDecimal distanceMeters,
    Integer verificationRadiusMeter,
    boolean stampIssued,
    boolean potatoAcquired,
    boolean missionAvailable
) {
}
