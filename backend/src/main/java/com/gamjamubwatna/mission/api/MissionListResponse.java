package com.gamjamubwatna.mission.api;

import java.util.List;

public record MissionListResponse(
    int totalCount,
    int completedCount,
    List<MissionItemResponse> missions
) {
}
