package com.gamjamubwatna.spot.api;

public record FavoriteSpotToggleResponse(
    Long spotId,
    boolean favorite
) {
}
