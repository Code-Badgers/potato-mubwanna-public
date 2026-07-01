package com.gamjamubwatna.mission.api;

import com.gamjamubwatna.mission.domain.MissionRewardType;
import java.time.Instant;

public record MissionCompleteResponse(
    Long missionId,
    boolean completed,
    Instant completedAt,
    MissionRewardType rewardType,
    String rewardLabel
) {
}
