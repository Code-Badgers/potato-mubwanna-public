package com.gamjamubwatna.auth.infrastructure;

import java.util.Arrays;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

final class AdminUserIdPolicy {

    private static final Pattern USER_SUBJECT_PATTERN = Pattern.compile("^user:([1-9]\\d*)$");

    private final Set<String> adminUserIds;

    AdminUserIdPolicy(String configuredUserIds) {
        this.adminUserIds = Arrays.stream(configuredUserIds.split(","))
            .map(String::trim)
            .filter(userId -> userId.matches("[1-9]\\d*"))
            .collect(Collectors.toUnmodifiableSet());
    }

    boolean isAdmin(String subject) {
        if (subject == null) {
            return false;
        }

        Matcher matcher = USER_SUBJECT_PATTERN.matcher(subject);
        return matcher.matches() && adminUserIds.contains(matcher.group(1));
    }
}
