package com.gamjamubwatna.potato.domain;

import java.time.Duration;

public enum PotatoInteractionAction {
    PAT(50.0, Duration.ofMinutes(30), 4),
    WATER(120.0, Duration.ofHours(1), 3),
    SNACK(200.0, Duration.ofMinutes(90), 2),
    WALK(500.0, Duration.ofHours(12));

    private final double growthDistance;
    private final Duration cooldown;
    private final int consecutiveUseLimit;

    PotatoInteractionAction(double growthDistance, Duration cooldown) {
        this(growthDistance, cooldown, 1);
    }

    PotatoInteractionAction(double growthDistance, Duration cooldown, int consecutiveUseLimit) {
        this.growthDistance = growthDistance;
        this.cooldown = cooldown;
        this.consecutiveUseLimit = consecutiveUseLimit;
    }

    public double growthDistance() {
        return growthDistance;
    }

    public Duration cooldown() {
        return cooldown;
    }

    public int consecutiveUseLimit() {
        return consecutiveUseLimit;
    }
}
