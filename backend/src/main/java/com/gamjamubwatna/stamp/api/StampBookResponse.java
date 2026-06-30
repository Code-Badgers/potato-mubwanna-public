package com.gamjamubwatna.stamp.api;

import java.util.List;

public record StampBookResponse(
    int totalCount,
    int acquiredCount,
    List<StampItemResponse> stamps
) {
}
