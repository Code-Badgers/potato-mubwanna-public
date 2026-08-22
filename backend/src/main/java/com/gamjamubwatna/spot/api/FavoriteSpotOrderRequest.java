package com.gamjamubwatna.spot.api;

import java.util.List;

public record FavoriteSpotOrderRequest(
    List<Long> spotIds
) {
}
