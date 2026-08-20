package com.gamjamubwatna.mission.api;

import com.gamjamubwatna.mission.domain.MissionType;
import java.math.BigDecimal;

public record MissionVerifyRequest(
    MissionType type,
    String answer,
    Integer stepCount,
    String uploadKey,
    String qrCode,
    BigDecimal latitude,
    BigDecimal longitude
) {

    public MissionVerifyRequest(
        MissionType type,
        String answer,
        Integer stepCount,
        String uploadKey,
        String qrCode
    ) {
        this(type, answer, stepCount, uploadKey, qrCode, null, null);
    }
}
