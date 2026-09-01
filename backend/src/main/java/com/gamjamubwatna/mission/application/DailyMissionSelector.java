package com.gamjamubwatna.mission.application;

import com.gamjamubwatna.mission.domain.Mission;
import com.gamjamubwatna.mission.domain.MissionGroup;
import com.gamjamubwatna.mission.domain.MissionStatus;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.time.LocalDate;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Chooses a stable daily set without persisting an assignment row per user/day.
 * The date is part of the score so a new KST day can offer a different set,
 * while repeated requests on the same day remain identical.
 */
public final class DailyMissionSelector {

    public static final int DAILY_MISSION_LIMIT = 3;

    private DailyMissionSelector() {
    }

    public static Set<String> selectCodes(
        List<Mission> missions,
        Long userId,
        LocalDate date
    ) {
        if (missions == null || missions.isEmpty()) {
            return Set.of();
        }

        return missions.stream()
            .filter(DailyMissionSelector::isCandidate)
            .sorted(Comparator.comparing(mission -> score(mission, userId, date)))
            .limit(DAILY_MISSION_LIMIT)
            .map(Mission::getCode)
            .collect(Collectors.toUnmodifiableSet());
    }

    private static boolean isCandidate(Mission mission) {
        return mission.getGroup() == MissionGroup.DAILY
            && mission.isActive()
            && mission.getDefaultStatus() != MissionStatus.LOCKED;
    }

    private static String score(Mission mission, Long userId, LocalDate date) {
        String seed = userId + ":" + date + ":" + mission.getCode();
        try {
            return HexFormat.of().formatHex(
                MessageDigest.getInstance("SHA-256")
                    .digest(seed.getBytes(StandardCharsets.UTF_8))
            );
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is required for daily mission selection", exception);
        }
    }
}
