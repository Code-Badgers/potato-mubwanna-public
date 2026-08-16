package com.gamjamubwatna.potato.domain;

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
import java.time.Instant;

@Entity
@Table(name = "user_potato_interactions")
public class UserPotatoInteraction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_potato_interaction_id")
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_potato_id", nullable = false)
    private UserPotato userPotato;

    @Enumerated(EnumType.STRING)
    @Column(name = "action", nullable = false, length = 30)
    private PotatoInteractionAction action;

    @Column(name = "growth_distance_added", nullable = false)
    private double growthDistanceAdded;

    @Column(name = "interacted_at", nullable = false, updatable = false)
    private Instant interactedAt;

    protected UserPotatoInteraction() {
    }

    public UserPotatoInteraction(
        UserPotato userPotato,
        PotatoInteractionAction action,
        double growthDistanceAdded,
        Instant interactedAt
    ) {
        this.userPotato = userPotato;
        this.action = action;
        this.growthDistanceAdded = growthDistanceAdded;
        this.interactedAt = interactedAt;
    }

    public Long getId() {
        return id;
    }

    public UserPotato getUserPotato() {
        return userPotato;
    }

    public PotatoInteractionAction getAction() {
        return action;
    }

    public double getGrowthDistanceAdded() {
        return growthDistanceAdded;
    }

    public Instant getInteractedAt() {
        return interactedAt;
    }
}
