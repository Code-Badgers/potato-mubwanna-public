package com.gamjamubwatna.potato.api;

import com.gamjamubwatna.potato.domain.Potato;
import com.gamjamubwatna.potato.domain.PotatoRarity;

public record PotatoCatalogItemResponse(
    Long potatoId,
    String code,
    String name,
    String region,
    PotatoRarity rarity,
    String description,
    String acquisitionHint,
    String acquisitionType,
    String imageUrl,
    double growthGoalDistance
) {

    public static PotatoCatalogItemResponse from(Potato potato) {
        return new PotatoCatalogItemResponse(
            potato.getId(),
            potato.getCode(),
            potato.getName(),
            potato.getRegion(),
            potato.getRarity(),
            potato.getDescription(),
            potato.getAcquisitionHint(),
            potato.getAcquisitionType().name(),
            potato.getImageUrl(),
            potato.getGrowthGoalDistance()
        );
    }
}
