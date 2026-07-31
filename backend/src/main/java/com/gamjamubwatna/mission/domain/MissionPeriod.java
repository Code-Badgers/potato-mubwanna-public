package com.gamjamubwatna.mission.domain;

import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.TemporalAdjusters;
import java.util.Objects;

public record MissionPeriod(
    String key,
    Instant startInclusive,
    Instant endExclusive,
    boolean available
) {

    public static final String ONE_TIME_KEY = "ONCE";
    private static final String UNSCHEDULED_EVENT_KEY = "EVENT:UNSCHEDULED";
    private static final ZoneId SERVICE_ZONE = ZoneId.of("Asia/Seoul");

    public MissionPeriod {
        Objects.requireNonNull(key);
        if ((startInclusive == null) != (endExclusive == null)) {
            throw new IllegalArgumentException("Mission period boundaries must both be present or absent");
        }
        if (startInclusive != null && !startInclusive.isBefore(endExclusive)) {
            throw new IllegalArgumentException("Mission period start must be before its end");
        }
    }

    public static MissionPeriod current(Mission mission, Instant now) {
        Objects.requireNonNull(mission);
        Objects.requireNonNull(now);

        return switch (mission.getGroup()) {
            case JUMSOONI -> new MissionPeriod(ONE_TIME_KEY, null, null, true);
            case DAILY -> daily(now);
            case WEEKLY -> weekly(now);
            case EVENT -> event(mission, now);
        };
    }

    public boolean isOneTime() {
        return ONE_TIME_KEY.equals(key);
    }

    public boolean hasRange() {
        return startInclusive != null;
    }

    private static MissionPeriod daily(Instant now) {
        LocalDate date = LocalDate.ofInstant(now, SERVICE_ZONE);
        Instant start = date.atStartOfDay(SERVICE_ZONE).toInstant();
        Instant end = date.plusDays(1).atStartOfDay(SERVICE_ZONE).toInstant();
        return new MissionPeriod("DAY:" + date, start, end, true);
    }

    private static MissionPeriod weekly(Instant now) {
        LocalDate date = LocalDate.ofInstant(now, SERVICE_ZONE);
        LocalDate monday = date.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        Instant start = monday.atStartOfDay(SERVICE_ZONE).toInstant();
        Instant end = monday.plusWeeks(1).atStartOfDay(SERVICE_ZONE).toInstant();
        return new MissionPeriod("WEEK:" + monday, start, end, true);
    }

    private static MissionPeriod event(Mission mission, Instant now) {
        Instant start = mission.getStartsAt();
        Instant end = mission.getEndsAt();
        if (start == null || end == null || !start.isBefore(end)) {
            return new MissionPeriod(UNSCHEDULED_EVENT_KEY, null, null, false);
        }

        boolean available = !now.isBefore(start) && now.isBefore(end);
        return new MissionPeriod("EVENT:" + start.toEpochMilli(), start, end, available);
    }
}
