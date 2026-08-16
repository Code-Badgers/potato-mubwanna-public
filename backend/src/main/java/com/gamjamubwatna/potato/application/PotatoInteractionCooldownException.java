package com.gamjamubwatna.potato.application;

import java.time.Instant;

public class PotatoInteractionCooldownException extends RuntimeException {

    private final Instant nextAvailableAt;

    public PotatoInteractionCooldownException(String message, Instant nextAvailableAt) {
        super(message);
        this.nextAvailableAt = nextAvailableAt;
    }

    public Instant getNextAvailableAt() {
        return nextAvailableAt;
    }
}
