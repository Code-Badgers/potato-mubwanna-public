package com.gamjamubwatna.visit.api;

import com.gamjamubwatna.potato.api.PotatoAcquisitionResponse;
import java.math.BigDecimal;

public record VisitVerifyResponse(
    Long spotId,
    boolean verified,
    BigDecimal distanceMeters,
    Integer verificationRadiusMeter,
    boolean stampIssued,
    boolean potatoAcquired,
    PotatoAcquisitionResponse acquiredPotato,
    boolean missionAvailable,
    UnlockedMissionResponse unlockedMission
) {
}
