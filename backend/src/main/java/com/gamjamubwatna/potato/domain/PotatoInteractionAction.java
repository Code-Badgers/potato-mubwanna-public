package com.gamjamubwatna.potato.domain;

import java.time.Duration;

public enum PotatoInteractionAction {
    PAT(50.0, Duration.ofMinutes(30)),
    WATER(120.0, Duration.ofHours(2)),
    SNACK(200.0, Duration.ofHours(4)),
    WALK(500.0, Duration.ofHours(12));

    private final double growthDistance;
    private final Duration cooldown;

    PotatoInteractionAction(double growthDistance, Duration cooldown) {
        this.growthDistance = growthDistance;
        this.cooldown = cooldown;
    }

    public double growthDistance() {
        return growthDistance;
    }

    public Duration cooldown() {
        return cooldown;
    }
}
