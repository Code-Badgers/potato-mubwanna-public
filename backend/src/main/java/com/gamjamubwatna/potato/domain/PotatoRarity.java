package com.gamjamubwatna.potato.domain;

public enum PotatoRarity {
    COMMON(3),
    RARE(5),
    EPIC(8),
    LEGENDARY(10);

    private final int maxLevel;

    PotatoRarity(int maxLevel) {
        this.maxLevel = maxLevel;
    }

    public int maxLevel() {
        return maxLevel;
    }
}
