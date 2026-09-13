package com.gamjamubwatna.spot.api;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;

public record SpotRouteEstimateRequest(
    @NotNull @Size(min = 2, max = 7) List<@NotNull Long> spotIds
) {
}
