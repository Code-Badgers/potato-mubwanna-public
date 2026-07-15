package com.gamjamubwatna.potato.api;

import java.util.List;

public record PotatoCatalogResponse(
    int totalCount,
    List<PotatoCatalogItemResponse> items
) {
}
