package com.gamjamubwatna.reward.api;

import com.gamjamubwatna.mission.domain.MissionRewardType;
import com.gamjamubwatna.reward.domain.RewardHistory;
import com.gamjamubwatna.reward.domain.RewardSourceType;
import java.time.Instant;

public record RewardHistoryResponse(
    Long rewardHistoryId,
    MissionRewardType rewardType,
    String rewardName,
    RewardSourceType sourceType,
    Long sourceId,
    Instant createdAt
) {

    public static RewardHistoryResponse from(RewardHistory rewardHistory) {
        return new RewardHistoryResponse(
            rewardHistory.getId(),
            rewardHistory.getRewardType(),
            rewardHistory.getRewardName(),
            rewardHistory.getSourceType(),
            rewardHistory.getSourceId(),
            rewardHistory.getCreatedAt()
        );
    }
}
