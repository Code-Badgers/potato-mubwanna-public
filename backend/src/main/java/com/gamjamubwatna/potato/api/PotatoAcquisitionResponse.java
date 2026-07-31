package com.gamjamubwatna.potato.api;

import com.gamjamubwatna.potato.domain.Potato;
import com.gamjamubwatna.potato.domain.PotatoRarity;

public record PotatoAcquisitionResponse(
    Long potatoId,
    String code,
    String name,
    String region,
    PotatoRarity rarity,
    boolean alreadyOwned
) {

    public static PotatoAcquisitionResponse from(Potato potato, boolean alreadyOwned) {
        return new PotatoAcquisitionResponse(
            potato.getId(),
            potato.getCode(),
            potato.getName(),
            potato.getRegion(),
            potato.getRarity(),
            alreadyOwned
        );
    }
}
