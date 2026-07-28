package com.gamjamubwatna.visit.api;

import com.gamjamubwatna.mission.domain.Mission;
import com.gamjamubwatna.mission.domain.MissionRewardType;
import com.gamjamubwatna.mission.domain.MissionType;

public record UnlockedMissionResponse(
    Long missionId,
    String title,
    MissionType type,
    String spotName,
    String cityName,
    MissionRewardType rewardType,
    String rewardLabel
) {

    public static UnlockedMissionResponse from(Mission mission) {
        return new UnlockedMissionResponse(
            mission.getId(),
            mission.getTitle(),
            mission.getType(),
            mission.getSpotName(),
            mission.getCityName(),
            mission.getRewardType(),
            mission.getRewardLabel()
        );
    }
}
