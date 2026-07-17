package com.gamjamubwatna.reward.domain;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RewardHistoryRepository extends JpaRepository<RewardHistory, Long> {

    List<RewardHistory> findByUserIdOrderByCreatedAtDesc(Long userId);

    boolean existsByUserIdAndSourceTypeAndSourceId(
        Long userId,
        RewardSourceType sourceType,
        Long sourceId
    );

    @Query("""
        SELECT rewardHistory.sourceId
        FROM RewardHistory rewardHistory
        WHERE rewardHistory.user.id = :userId
          AND rewardHistory.sourceType = :sourceType
        """)
    List<Long> findSourceIdsByUserIdAndSourceType(
        @Param("userId") Long userId,
        @Param("sourceType") RewardSourceType sourceType
    );
}
