package com.gamjamubwatna.mission.application;

import static org.assertj.core.api.Assertions.assertThat;

import com.gamjamubwatna.mission.domain.Mission;
import com.gamjamubwatna.mission.domain.MissionGroup;
import com.gamjamubwatna.mission.domain.MissionRewardType;
import com.gamjamubwatna.mission.domain.MissionStatus;
import com.gamjamubwatna.mission.domain.MissionType;
import java.time.LocalDate;
import java.time.Month;
import java.util.List;
import java.util.Set;
import org.junit.jupiter.api.Test;

class DailyMissionSelectorTest {

    private static final LocalDate FIRST_DAY = LocalDate.of(2026, Month.SEPTEMBER, 1);

    @Test
    void selectsAtMostThreeActiveDailyMissions() {
        Set<String> selected = DailyMissionSelector.selectCodes(
            missions(),
            7L,
            FIRST_DAY
        );

        assertThat(selected).hasSize(3);
        assertThat(selected).allMatch(code -> code.startsWith("DAILY_"));
    }

    @Test
    void sameUserAndDateAlwaysGetsTheSameSet() {
        Set<String> first = DailyMissionSelector.selectCodes(missions(), 7L, FIRST_DAY);
        Set<String> second = DailyMissionSelector.selectCodes(missions(), 7L, FIRST_DAY);

        assertThat(second).isEqualTo(first);
    }

    @Test
    void dateIsPartOfSelectionSoAFollowingDayCanRotateTheSet() {
        Set<String> first = DailyMissionSelector.selectCodes(missions(), 7L, FIRST_DAY);
        Set<String> next = DailyMissionSelector.selectCodes(
            missions(),
            7L,
            FIRST_DAY.plusDays(1)
        );

        assertThat(next).isNotEqualTo(first);
    }

    @Test
    void excludesLockedInactiveAndNonDailyMissions() {
        Set<String> selected = DailyMissionSelector.selectCodes(
            List.of(
                mission("DAILY_READY", MissionGroup.DAILY, MissionStatus.READY, true),
                mission("DAILY_LOCKED", MissionGroup.DAILY, MissionStatus.LOCKED, true),
                mission("DAILY_INACTIVE", MissionGroup.DAILY, MissionStatus.READY, false),
                mission("JUMSOONI_READY", MissionGroup.JUMSOONI, MissionStatus.READY, true)
            ),
            7L,
            FIRST_DAY
        );

        assertThat(selected).containsExactly("DAILY_READY");
    }

    private List<Mission> missions() {
        return List.of(
            mission("DAILY_STEPS_3000", MissionGroup.DAILY, MissionStatus.READY, true),
            mission("DAILY_STEPS_5000", MissionGroup.DAILY, MissionStatus.READY, true),
            mission("DAILY_STEPS_7000", MissionGroup.DAILY, MissionStatus.READY, true),
            mission("DAILY_STAMP", MissionGroup.DAILY, MissionStatus.READY, true),
            mission("DAILY_CITIES", MissionGroup.DAILY, MissionStatus.READY, true)
        );
    }

    private Mission mission(
        String code,
        MissionGroup group,
        MissionStatus status,
        boolean active
    ) {
        return new Mission(
            code,
            group,
            MissionType.VISIT,
            status,
            "미션",
            "강원 여행길",
            "강원도",
            "설명",
            "대사",
            "조건",
            MissionRewardType.COIN,
            "코인",
            0,
            1,
            false,
            active,
            1,
            null,
            null,
            FIRST_DAY.atStartOfDay(java.time.ZoneOffset.UTC).toInstant()
        );
    }
}
