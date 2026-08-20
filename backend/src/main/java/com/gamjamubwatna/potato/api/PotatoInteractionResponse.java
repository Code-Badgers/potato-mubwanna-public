package com.gamjamubwatna.potato.api;

import com.gamjamubwatna.potato.domain.PotatoInteractionAction;
import com.gamjamubwatna.potato.domain.PotatoCareStatus;
import com.gamjamubwatna.potato.domain.UserPotato;
import java.time.Instant;

public record PotatoInteractionResponse(
    Long potatoId,
    String potatoName,
    PotatoInteractionAction action,
    double growthDistanceAdded,
    long cooldownSeconds,
    Instant nextAvailableAt,
    PotatoCareStatusResponse careStatus,
    PotatoGrowthResultResponse growthResult
) {

    public static PotatoInteractionResponse from(
        UserPotato userPotato,
        PotatoInteractionAction action,
        Instant nextAvailableAt,
        int previousLevel,
        PotatoCareStatus careStatus
    ) {
        return new PotatoInteractionResponse(
            userPotato.getPotato().getId(),
            userPotato.getPotato().getName(),
            action,
            action.growthDistance(),
            action.cooldown().toSeconds(),
            nextAvailableAt,
            PotatoCareStatusResponse.from(careStatus),
            PotatoGrowthResultResponse.from(userPotato, previousLevel)
        );
    }
}
