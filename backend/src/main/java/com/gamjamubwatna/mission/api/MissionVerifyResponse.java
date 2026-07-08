package com.gamjamubwatna.mission.api;

import com.gamjamubwatna.mission.domain.MissionRewardType;
import java.time.Instant;

public record MissionVerifyResponse(
    Long missionId,
    boolean verified,
    boolean completed,
    Instant completedAt,
    MissionRewardType rewardType,
    String rewardLabel
) {

    public static MissionVerifyResponse from(MissionCompleteResponse response) {
        return new MissionVerifyResponse(
            response.missionId(),
            true,
            response.completed(),
            response.completedAt(),
            response.rewardType(),
            response.rewardLabel()
        );
    }
}
