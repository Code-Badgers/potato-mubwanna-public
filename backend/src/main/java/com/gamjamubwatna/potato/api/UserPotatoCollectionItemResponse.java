package com.gamjamubwatna.potato.api;

import com.gamjamubwatna.potato.domain.Potato;
import com.gamjamubwatna.potato.domain.PotatoCareStatus;
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
    PotatoCareStatusResponse careStatus,
    boolean representative,
    String acquisitionType,
    boolean harvestable,
    boolean harvested
) {

    public static UserPotatoCollectionItemResponse from(
        Potato potato,
        UserPotato userPotato,
        PotatoCareStatus careStatus
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
            careStatus == null ? null : PotatoCareStatusResponse.from(careStatus),
            acquired && userPotato.isRepresentative(),
            "GROWTH",
            acquired && userPotato.canHarvest(),
            acquired && userPotato.isHarvested()
        );
    }
}
