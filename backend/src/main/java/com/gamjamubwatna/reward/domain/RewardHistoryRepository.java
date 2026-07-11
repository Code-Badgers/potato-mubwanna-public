package com.gamjamubwatna.reward.domain;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RewardHistoryRepository extends JpaRepository<RewardHistory, Long> {

    List<RewardHistory> findByUserIdOrderByCreatedAtDesc(Long userId);
}
