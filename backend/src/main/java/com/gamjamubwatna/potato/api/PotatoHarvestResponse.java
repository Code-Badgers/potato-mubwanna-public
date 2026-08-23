package com.gamjamubwatna.potato.api;

import com.gamjamubwatna.potato.domain.UserPotato;
import java.time.Instant;

public record PotatoHarvestResponse(
    Long potatoId,
    String potatoName,
    boolean harvested,
    Instant harvestedAt
) {

    public static PotatoHarvestResponse from(UserPotato userPotato) {
        return new PotatoHarvestResponse(
            userPotato.getPotato().getId(),
            userPotato.getPotato().getName(),
            userPotato.isHarvested(),
            userPotato.getHarvestedAt()
        );
    }
}
