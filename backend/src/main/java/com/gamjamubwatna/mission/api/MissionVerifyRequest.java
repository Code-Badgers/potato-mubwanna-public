package com.gamjamubwatna.mission.api;

import com.gamjamubwatna.mission.domain.MissionType;

public record MissionVerifyRequest(
    MissionType type,
    String answer,
    Integer stepCount,
    String uploadKey,
    String qrCode
) {
}
