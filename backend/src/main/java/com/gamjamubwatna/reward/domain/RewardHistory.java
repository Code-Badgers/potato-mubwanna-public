package com.gamjamubwatna.reward.domain;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.mission.domain.MissionRewardType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;

@Entity
@Table(
    name = "reward_histories",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_reward_histories_user_source",
            columnNames = {"user_id", "source_type", "source_id"}
        )
    }
)
public class RewardHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "reward_history_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(name = "reward_type", nullable = false, length = 30)
    private MissionRewardType rewardType;

    @Column(name = "reward_name", nullable = false, length = 255)
    private String rewardName;

    @Enumerated(EnumType.STRING)
    @Column(name = "source_type", nullable = false, length = 30)
    private RewardSourceType sourceType;

    @Column(name = "source_id", nullable = false)
    private Long sourceId;

    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    protected RewardHistory() {
    }

    public RewardHistory(
        User user,
        MissionRewardType rewardType,
        String rewardName,
        RewardSourceType sourceType,
        Long sourceId,
        Instant now
    ) {
        this.user = user;
        this.rewardType = rewardType;
        this.rewardName = rewardName;
        this.sourceType = sourceType;
        this.sourceId = sourceId;
        this.createdAt = now;
    }

    public User getUser() {
        return user;
    }

    public Long getId() {
        return id;
    }

    public MissionRewardType getRewardType() {
        return rewardType;
    }

    public String getRewardName() {
        return rewardName;
    }

    public RewardSourceType getSourceType() {
        return sourceType;
    }

    public Long getSourceId() {
        return sourceId;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }
}
