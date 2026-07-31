package com.gamjamubwatna.push.application;

import java.util.Set;

public record PushDeliveryResult(
    int successfulCount,
    int failedCount,
    Set<String> invalidTokens
) {

    public PushDeliveryResult {
        invalidTokens = Set.copyOf(invalidTokens);
    }
}
