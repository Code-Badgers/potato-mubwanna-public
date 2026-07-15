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
    private Integer level;

    @Column(name = "growth_distance", nullable = false)
    private Double growthDistance;

    @Column(name = "representative", nullable = false)
    private Boolean representative;

    protected UserPotato() {
    }

    public UserPotato(
        User user,
        Potato potato,
        Instant acquiredAt,
        Integer level,
        Double growthDistance,
        Boolean representative
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

    public Integer getLevel() {
        return level;
    }

    public Double getGrowthDistance() {
        return growthDistance;
    }

    public Boolean isRepresentative() {
        return representative;
    }
}
