package com.gamjamubwatna.potato.domain;

import com.gamjamubwatna.auth.domain.User;
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
    name = "user_potatoes",
    uniqueConstraints = {
        @UniqueConstraint(
            name = "uk_user_potatoes_user_potato",
            columnNames = {"user_id", "potato_id"}
        )
    }
)
public class UserPotato {

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

    @Enumerated(EnumType.STRING)
    @Column(name = "acquisition_type", nullable = false, length = 30)
    private PotatoAcquisitionType acquisitionType;

    @Column(name = "harvested_at")
    private Instant harvestedAt;

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
        this.acquisitionType = PotatoAcquisitionType.GROWTH;
        this.harvestedAt = null;
    }

    public UserPotato(
        User user,
        Potato potato,
        Instant acquiredAt,
        int level,
        double growthDistance,
        boolean representative,
        PotatoAcquisitionType acquisitionType
    ) {
        this.user = user;
        this.potato = potato;
        this.acquiredAt = acquiredAt;
        this.level = level;
        this.growthDistance = growthDistance;
        this.representative = representative;
        this.acquisitionType = acquisitionType == null ? PotatoAcquisitionType.GROWTH : acquisitionType;
        this.harvestedAt = null;
    }

    public UserPotato(
        User user,
        Potato potato,
        Instant acquiredAt,
        int level,
        double growthDistance,
        boolean representative,
        Instant harvestedAt
    ) {
        this.user = user;
        this.potato = potato;
        this.acquiredAt = acquiredAt;
        this.level = level;
        this.growthDistance = growthDistance;
        this.representative = representative;
        this.acquisitionType = PotatoAcquisitionType.GROWTH;
        this.harvestedAt = harvestedAt;
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

    public PotatoAcquisitionType getAcquisitionType() {
        return acquisitionType == null ? PotatoAcquisitionType.GROWTH : acquisitionType;
    }

    public Instant getHarvestedAt() {
        return harvestedAt;
    }

    public boolean isHarvested() {
        return harvestedAt != null;
    }

    public boolean isFullyGrown() {
        return level >= potato.getMaxGrowthLevel();
    }

    public boolean canHarvest() {
        return isFullyGrown() && !isHarvested();
    }

    public void harvest(Instant harvestedAt) {
        if (harvestedAt == null) {
            throw new IllegalArgumentException("수확 시각을 확인할 수 없습니다.");
        }
        if (!isFullyGrown()) {
            throw new IllegalStateException("완전히 성장한 감자만 수확할 수 있습니다.");
        }
        if (isHarvested()) {
            return;
        }
        this.harvestedAt = harvestedAt;
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
            level = potato.getMaxGrowthLevel();
            growthDistance = growthGoalDistance;
            return;
        }

        growthDistance += additionalDistance;
        while (level < potato.getMaxGrowthLevel() && growthDistance >= growthGoalDistance) {
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
