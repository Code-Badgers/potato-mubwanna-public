package com.gamjamubwatna.potato.api;

import java.util.List;

public record UserPotatoCollectionResponse(
    int totalCount,
    int acquiredCount,
    List<UserPotatoCollectionItemResponse> items
) {
}
