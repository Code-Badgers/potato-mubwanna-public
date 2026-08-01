package com.gamjamubwatna.potato.domain;

import com.gamjamubwatna.auth.domain.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
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
    name = "user_potatoes",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_user_potatoes_user_potato",
            columnNames = {"user_id", "potato_id"}
        )
    }
)
public class UserPotato {

    private static final int MAX_GROWTH_LEVEL = 5;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_potato_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "potato_id", nullable = false)
    private Potato potato;

    @Column(name = "acquired_at", nullable = false, updatable = false)
    private Instant acquiredAt;

    @Column(name = "level", nullable = false)
    private int level;

    @Column(name = "growth_distance", nullable = false)
    private double growthDistance;

    @Column(name = "representative", nullable = false)
    private boolean representative;

    protected UserPotato() {
    }

    public UserPotato(
        User user,
        Potato potato,
        Instant acquiredAt,
        int level,
        double growthDistance,
        boolean representative
    ) {
        this.user = user;
        this.potato = potato;
        this.acquiredAt = acquiredAt;
        this.level = level;
        this.growthDistance = growthDistance;
        this.representative = representative;
    }

    public Long getId() {
        return id;
    }

    public User getUser() {
        return user;
    }

    public Potato getPotato() {
        return potato;
    }

    public Instant getAcquiredAt() {
        return acquiredAt;
    }

    public int getLevel() {
        return level;
    }

    public double getGrowthDistance() {
        return growthDistance;
    }

    public boolean isRepresentative() {
        return representative;
    }

    public boolean isFullyGrown() {
        return level >= MAX_GROWTH_LEVEL;
    }

    public void addGrowthDistance(double additionalDistance) {
        if (!Double.isFinite(additionalDistance) || additionalDistance < 0) {
            throw new IllegalArgumentException("성장 거리는 0 이상의 유한한 값이어야 합니다.");
        }

        double growthGoalDistance = potato.getGrowthGoalDistance();
        if (!Double.isFinite(growthGoalDistance) || growthGoalDistance <= 0) {
            throw new IllegalStateException("감자 성장 목표 거리를 확인할 수 없습니다.");
        }
        if (isFullyGrown()) {
            level = MAX_GROWTH_LEVEL;
            growthDistance = growthGoalDistance;
            return;
        }

        growthDistance += additionalDistance;
        while (level < MAX_GROWTH_LEVEL && growthDistance >= growthGoalDistance) {
            level++;
            growthDistance -= growthGoalDistance;
        }

        // 완성 단계는 다음 목표가 없으므로 진행률을 100%로 고정한다.
        if (isFullyGrown()) {
            growthDistance = growthGoalDistance;
        }
    }

    public void markRepresentative() {
        representative = true;
    }

    public void unmarkRepresentative() {
        representative = false;
    }
}
