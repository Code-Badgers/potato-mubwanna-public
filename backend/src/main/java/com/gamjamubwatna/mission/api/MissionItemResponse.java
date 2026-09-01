package com.gamjamubwatna.mission.api;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.gamjamubwatna.mission.domain.Mission;
import com.gamjamubwatna.mission.domain.MissionGroup;
import com.gamjamubwatna.mission.domain.MissionPeriod;
import com.gamjamubwatna.mission.domain.MissionRewardType;
import com.gamjamubwatna.mission.domain.MissionStatus;
import com.gamjamubwatna.mission.domain.MissionType;
import com.gamjamubwatna.mission.domain.UserMission;
import java.time.Instant;

public record MissionItemResponse(
    Long missionId,
    String code,
    MissionGroup group,
    MissionType type,
    MissionStatus status,
    String title,
    String spotName,
    String cityName,
    String description,
    String dialogue,
    String conditionLabel,
    MissionRewardType rewardType,
    String rewardLabel,
    int progress,
    int target,
    boolean active,
    @JsonProperty("new")
    boolean isNew,
    boolean completed,
    Instant completedAt,
    Instant periodStartsAt,
    Instant periodEndsAt,
    boolean todaySelected
) {

    public static MissionItemResponse from(
        Mission mission,
        UserMission userMission,
        MissionPeriod period,
        int progress,
        boolean available,
        boolean todaySelected
    ) {
        boolean completed = userMission != null;
        return new MissionItemResponse(
            mission.getId(),
            mission.getCode(),
            mission.getGroup(),
            mission.getType(),
            completed
                ? MissionStatus.COMPLETED
                : available ? mission.getDefaultStatus() : MissionStatus.LOCKED,
            mission.getTitle(),
            mission.getSpotName(),
            mission.getCityName(),
            mission.getDescription(),
            mission.getDialogue(),
            mission.getConditionLabel(),
            mission.getRewardType(),
            mission.getRewardLabel(),
            completed ? mission.getTarget() : progress,
            mission.getTarget(),
            available,
            mission.isNewMission(),
            completed,
            completed ? userMission.getCompletedAt() : null,
            period.startInclusive(),
            period.endExclusive(),
            todaySelected
        );
    }
}
