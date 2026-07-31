package com.gamjamubwatna.mission.domain;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.Instant;
import org.junit.jupiter.api.Test;

class MissionPeriodTest {

    @Test
    void dailyPeriodChangesAtSeoulMidnight() {
        Mission mission = mission(MissionGroup.DAILY, null, null);

        MissionPeriod beforeMidnight = MissionPeriod.current(
            mission,
            Instant.parse("2026-06-30T14:59:59Z")
        );
        MissionPeriod atMidnight = MissionPeriod.current(
            mission,
            Instant.parse("2026-06-30T15:00:00Z")
        );

        assertThat(beforeMidnight.key()).isEqualTo("DAY:2026-06-30");
        assertThat(atMidnight.key()).isEqualTo("DAY:2026-07-01");
        assertThat(atMidnight.startInclusive())
            .isEqualTo(Instant.parse("2026-06-30T15:00:00Z"));
        assertThat(atMidnight.endExclusive())
            .isEqualTo(Instant.parse("2026-07-01T15:00:00Z"));
    }

    @Test
    void weeklyPeriodChangesAtMondaySeoulMidnight() {
        Mission mission = mission(MissionGroup.WEEKLY, null, null);

        MissionPeriod beforeMonday = MissionPeriod.current(
            mission,
            Instant.parse("2026-07-05T14:59:59Z")
        );
        MissionPeriod atMonday = MissionPeriod.current(
            mission,
            Instant.parse("2026-07-05T15:00:00Z")
        );

        assertThat(beforeMonday.key()).isEqualTo("WEEK:2026-06-29");
        assertThat(beforeMonday.startInclusive())
            .isEqualTo(Instant.parse("2026-06-28T15:00:00Z"));
        assertThat(beforeMonday.endExclusive())
            .isEqualTo(Instant.parse("2026-07-05T15:00:00Z"));
        assertThat(atMonday.key()).isEqualTo("WEEK:2026-07-06");
    }

    @Test
    void eventPeriodUsesHalfOpenBoundaries() {
        Instant startsAt = Instant.parse("2026-07-01T00:00:00Z");
        Instant endsAt = Instant.parse("2026-07-03T00:00:00Z");
        Mission mission = mission(MissionGroup.EVENT, startsAt, endsAt);

        MissionPeriod atStart = MissionPeriod.current(mission, startsAt);
        MissionPeriod atEnd = MissionPeriod.current(mission, endsAt);

        assertThat(atStart.available()).isTrue();
        assertThat(atStart.key()).isEqualTo("EVENT:1782864000000");
        assertThat(atStart.startInclusive()).isEqualTo(startsAt);
        assertThat(atStart.endExclusive()).isEqualTo(endsAt);
        assertThat(atEnd.available()).isFalse();
    }

    @Test
    void unscheduledEventIsUnavailable() {
        MissionPeriod period = MissionPeriod.current(
            mission(MissionGroup.EVENT, null, null),
            Instant.parse("2026-07-01T00:00:00Z")
        );

        assertThat(period.available()).isFalse();
        assertThat(period.startInclusive()).isNull();
        assertThat(period.endExclusive()).isNull();
    }

    private Mission mission(
        MissionGroup group,
        Instant startsAt,
        Instant endsAt
    ) {
        return new Mission(
            "MISSION_PERIOD_TEST",
            group,
            MissionType.VISIT,
            MissionStatus.READY,
            "기간 테스트",
            "테스트 장소",
            "테스트 시군",
            "기간 계산을 검증한다.",
            "기간을 확인한다.",
            "조건",
            MissionRewardType.ITEM,
            "보상",
            0,
            1,
            false,
            true,
            1,
            startsAt,
            endsAt,
            Instant.parse("2026-06-01T00:00:00Z")
        );
    }
}
