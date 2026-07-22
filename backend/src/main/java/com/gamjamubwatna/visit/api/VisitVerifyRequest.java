package com.gamjamubwatna.visit.api;

import java.math.BigDecimal;

public record VisitVerifyRequest(
    Long spotId,
    BigDecimal latitude,
    BigDecimal longitude
) {
}
