package com.gamjamubwatna.auth.infrastructure;

import java.util.Arrays;
import java.util.Set;
import java.util.stream.Collectors;

final class AdminUserIdPolicy {

    private final Set<String> adminUserIds;

    AdminUserIdPolicy(String configuredUserIds) {
        this.adminUserIds = Arrays.stream(configuredUserIds.split(","))
            .map(String::trim)
            .filter(userId -> !userId.isEmpty())
            .collect(Collectors.toUnmodifiableSet());
    }

    boolean isAdmin(String userId) {
        return userId != null && adminUserIds.contains(userId);
    }
}
