package com.gamjamubwatna.spot.api;

import com.gamjamubwatna.spot.domain.SpotMenuItem;
import java.time.LocalDate;

public record SpotMenuItemResponse(
    String name,
    Integer priceWon,
    String priceNote,
    LocalDate verifiedOn
) {

    public static SpotMenuItemResponse from(SpotMenuItem item) {
        return new SpotMenuItemResponse(
            item.getName(),
            item.getPriceWon(),
            item.getPriceNote(),
            item.getVerifiedOn()
        );
    }
}
