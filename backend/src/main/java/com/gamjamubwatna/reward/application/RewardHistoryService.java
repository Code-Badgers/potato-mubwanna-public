package com.gamjamubwatna.reward.application;

import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.reward.api.RewardHistoryListResponse;
import com.gamjamubwatna.reward.api.RewardHistoryResponse;
import com.gamjamubwatna.reward.domain.RewardHistoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RewardHistoryService {

    private final UserRepository userRepository;
    private final RewardHistoryRepository rewardHistoryRepository;

    public RewardHistoryService(
        UserRepository userRepository,
        RewardHistoryRepository rewardHistoryRepository
    ) {
        this.userRepository = userRepository;
        this.rewardHistoryRepository = rewardHistoryRepository;
    }

    @Transactional(readOnly = true)
    public RewardHistoryListResponse getRewardHistory(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new RewardAuthenticationException("사용자를 찾을 수 없습니다.");
        }

        return new RewardHistoryListResponse(
            rewardHistoryRepository.findByUserIdOrderByCreatedAtDesc(userId).stream()
                .map(RewardHistoryResponse::from)
                .toList()
        );
    }
}
