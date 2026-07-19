package com.gamjamubwatna.potato.api;

import com.gamjamubwatna.potato.domain.UserPotato;

public record PotatoRepresentativeResponse(
    Long potatoId,
    boolean representative
) {

    public static PotatoRepresentativeResponse from(UserPotato userPotato) {
        return new PotatoRepresentativeResponse(
            userPotato.getPotato().getId(),
            userPotato.isRepresentative()
        );
    }
}
