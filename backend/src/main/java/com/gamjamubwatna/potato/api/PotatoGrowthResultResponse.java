package com.gamjamubwatna.potato.api;

import com.gamjamubwatna.potato.domain.UserPotato;

public record PotatoGrowthResultResponse(
    Long potatoId,
    String potatoName,
    int previousLevel,
    int currentLevel,
    boolean leveledUp,
    boolean fullyGrown
) {

    public static PotatoGrowthResultResponse from(UserPotato userPotato, int previousLevel) {
        int currentLevel = userPotato.getLevel();
        return new PotatoGrowthResultResponse(
            userPotato.getPotato().getId(),
            userPotato.getPotato().getName(),
            previousLevel,
            currentLevel,
            currentLevel > previousLevel,
            userPotato.isFullyGrown()
        );
    }
}
