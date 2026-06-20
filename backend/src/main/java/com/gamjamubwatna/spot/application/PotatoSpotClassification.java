package com.gamjamubwatna.spot.application;

import com.gamjamubwatna.spot.domain.SpotCategory;

public record PotatoSpotClassification(
    SpotCategory category,
    String tags
) {
}
