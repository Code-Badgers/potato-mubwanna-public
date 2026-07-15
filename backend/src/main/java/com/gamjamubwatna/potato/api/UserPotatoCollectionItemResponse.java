package com.gamjamubwatna.potato.api;

import com.gamjamubwatna.potato.domain.Potato;
import com.gamjamubwatna.potato.domain.PotatoRarity;
import com.gamjamubwatna.potato.domain.UserPotato;
import java.time.Instant;

public record UserPotatoCollectionItemResponse(
    Long potatoId,
    String code,
    String name,
    String region,
    PotatoRarity rarity,
    String description,
    String acquisitionHint,
    String imageUrl,
    boolean acquired,
    Instant acquiredAt,
    int level,
    double growthDistance,
    double growthGoalDistance,
    boolean representative
) {

    public static UserPotatoCollectionItemResponse from(
        Potato potato,
        UserPotato userPotato
    ) {
        boolean acquired = userPotato != null;
        return new UserPotatoCollectionItemResponse(
            potato.getId(),
            potato.getCode(),
            potato.getName(),
            potato.getRegion(),
            potato.getRarity(),
            potato.getDescription(),
            potato.getAcquisitionHint(),
            potato.getImageUrl(),
            acquired,
            acquired ? userPotato.getAcquiredAt() : null,
            acquired ? userPotato.getLevel() : 0,
            acquired ? userPotato.getGrowthDistance() : 0.0,
            potato.getGrowthGoalDistance(),
            acquired && userPotato.isRepresentative()
        );
    }
}
