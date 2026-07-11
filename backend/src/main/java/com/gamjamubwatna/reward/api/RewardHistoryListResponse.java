package com.gamjamubwatna.reward.api;

import java.util.List;

public record RewardHistoryListResponse(
    List<RewardHistoryResponse> rewards
) {
}
