package com.gamjamubwatna.mission.application;

import com.gamjamubwatna.mission.domain.Mission;
import com.gamjamubwatna.mission.domain.MissionGroup;
import com.gamjamubwatna.mission.domain.MissionVerificationPolicy;
import com.gamjamubwatna.potato.domain.ActivitySource;
import com.gamjamubwatna.potato.domain.UserDailyActivityRepository;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import com.gamjamubwatna.visit.domain.UserVisitRepository;
import java.time.Clock;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.TemporalAdjusters;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

@Component
public class MissionEvidenceValidator {

    private static final ZoneId SERVICE_ZONE = ZoneId.of("Asia/Seoul");
    private static final List<ActivitySource> TRUSTED_ACTIVITY_SOURCES = List.of(
        ActivitySource.HEALTH_KIT,
        ActivitySource.HEALTH_CONNECT
    );

    private final UserVisitRepository userVisitRepository;
    private final UserStampRepository userStampRepository;
    private final UserDailyActivityRepository userDailyActivityRepository;
    private final Clock clock;

    @Autowired
    public MissionEvidenceValidator(
        UserVisitRepository userVisitRepository,
        UserStampRepository userStampRepository,
        UserDailyActivityRepository userDailyActivityRepository
    ) {
        this(
            userVisitRepository,
            userStampRepository,
            userDailyActivityRepository,
            Clock.systemUTC()
        );
    }

    MissionEvidenceValidator(
        UserVisitRepository userVisitRepository,
        UserStampRepository userStampRepository,
        UserDailyActivityRepository userDailyActivityRepository,
        Clock clock
    ) {
        this.userVisitRepository = userVisitRepository;
        this.userStampRepository = userStampRepository;
        this.userDailyActivityRepository = userDailyActivityRepository;
        this.clock = clock;
    }

    public void validate(
        Long userId,
        Mission mission,
        MissionVerificationPolicy verificationPolicy
    ) {
        switch (mission.getType()) {
            case VISIT -> validateVisit(userId, mission);
            case VISIT_AND_STEP -> validateVisitAndStep(userId, mission, verificationPolicy);
            case STAMP -> validateStamp(userId, mission);
            case COLLECTION -> validateCollection(userId, mission);
            default -> {
                // 입력 자체를 검증하는 미션 타입은 MissionService에서 처리한다.
            }
        }
    }

    private void validateVisit(Long userId, Mission mission) {
        boolean hasVerifiedVisit =
            userVisitRepository.existsByUserIdAndTouristSpotNameAndTouristSpotCityName(
                userId,
                mission.getSpotName(),
                mission.getCityName()
            );
        if (!hasVerifiedVisit) {
            throw new MissionVerificationException("해당 장소의 방문 인증을 먼저 완료해주세요.");
        }
    }

    private void validateVisitAndStep(
        Long userId,
        Mission mission,
        MissionVerificationPolicy policy
    ) {
        if (policy == null || policy.getMinStepCount() == null) {
            throw new MissionVerificationException("미션 걸음 수 정책을 확인할 수 없습니다.");
        }
        if (mission.getGroup() != MissionGroup.DAILY) {
            validateVisit(userId, mission);
        }

        LocalDate today = currentDate();
        long storedSteps = userDailyActivityRepository.sumStepsByUserIdAndActivityDateAndSources(
            userId,
            today,
            TRUSTED_ACTIVITY_SOURCES
        );
        if (storedSteps < policy.getMinStepCount()) {
            throw new MissionVerificationException("동기화된 걸음 수가 미션 목표에 도달하지 않았습니다.");
        }
    }

    private void validateStamp(Long userId, Mission mission) {
        TimeRange range = evidenceRange(mission.getGroup());
        long acquiredStamps =
            userStampRepository.countByUserIdAndAcquiredAtGreaterThanEqualAndAcquiredAtLessThan(
                userId,
                range.startInclusive(),
                range.endExclusive()
            );
        if (acquiredStamps < mission.getTarget()) {
            throw new MissionVerificationException("미션 기간에 획득한 스탬프가 부족합니다.");
        }
    }

    private void validateCollection(Long userId, Mission mission) {
        TimeRange range = evidenceRange(mission.getGroup());
        long visitedCities = userVisitRepository.countDistinctVisitedCities(
            userId,
            range.startInclusive(),
            range.endExclusive()
        );
        if (visitedCities < mission.getTarget()) {
            throw new MissionVerificationException("미션 기간에 방문한 시군 수가 부족합니다.");
        }
    }

    private TimeRange evidenceRange(MissionGroup group) {
        LocalDate today = currentDate();
        LocalDate startDate = group == MissionGroup.WEEKLY
            ? today.with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
            : today;
        Instant startInclusive = startDate.atStartOfDay(SERVICE_ZONE).toInstant();
        Instant endExclusive = today.plusDays(1).atStartOfDay(SERVICE_ZONE).toInstant();
        return new TimeRange(startInclusive, endExclusive);
    }

    private LocalDate currentDate() {
        return LocalDate.now(clock.withZone(SERVICE_ZONE));
    }

    private record TimeRange(Instant startInclusive, Instant endExclusive) {
    }
}
