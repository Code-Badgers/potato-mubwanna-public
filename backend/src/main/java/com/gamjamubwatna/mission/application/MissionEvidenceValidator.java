package com.gamjamubwatna.mission.application;

import com.gamjamubwatna.mission.domain.Mission;
import com.gamjamubwatna.mission.domain.MissionGroup;
import com.gamjamubwatna.mission.domain.MissionPeriod;
import com.gamjamubwatna.mission.domain.MissionVerificationPolicy;
import com.gamjamubwatna.potato.domain.ActivitySource;
import com.gamjamubwatna.potato.domain.UserDailyActivityRepository;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import com.gamjamubwatna.visit.domain.UserVisitRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
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
        validate(
            userId,
            mission,
            verificationPolicy,
            MissionPeriod.current(mission, Instant.now(clock))
        );
    }

    public void validate(
        Long userId,
        Mission mission,
        MissionVerificationPolicy verificationPolicy,
        MissionPeriod period
    ) {
        switch (mission.getType()) {
            case VISIT -> validateVisit(userId, mission, period);
            case VISIT_AND_STEP ->
                validateVisitAndStep(userId, mission, verificationPolicy, period);
            case STAMP -> validateStamp(userId, mission, period);
            case COLLECTION -> validateCollection(userId, mission, period);
            default -> {
                // 입력 자체를 검증하는 미션 타입은 MissionService에서 처리한다.
            }
        }
    }

    public int progress(Long userId, Mission mission, MissionPeriod period) {
        if (!period.available()) {
            return 0;
        }

        long progress = switch (mission.getType()) {
            case VISIT -> hasVerifiedVisit(userId, mission, period) ? 1L : 0L;
            case VISIT_AND_STEP -> storedSteps(userId, period);
            case STAMP -> acquiredStampCount(userId, period);
            case COLLECTION -> visitedCityCount(userId, period);
            default -> mission.getProgress();
        };
        long normalized = Math.max(0L, Math.min(progress, mission.getTarget().longValue()));
        return (int) normalized;
    }

    private void validateVisit(Long userId, Mission mission, MissionPeriod period) {
        if (!hasVerifiedVisit(userId, mission, period)) {
            throw new MissionVerificationException("해당 장소의 방문 인증을 먼저 완료해주세요.");
        }
    }

    private boolean hasVerifiedVisit(Long userId, Mission mission, MissionPeriod period) {
        if (period.hasRange()) {
            return userVisitRepository
                .existsByUserIdAndTouristSpotNameAndTouristSpotCityNameAndVisitedAtGreaterThanEqualAndVisitedAtLessThan(
                    userId,
                    mission.getSpotName(),
                    mission.getCityName(),
                    period.startInclusive(),
                    period.endExclusive()
                );
        }
        return userVisitRepository.existsByUserIdAndTouristSpotNameAndTouristSpotCityName(
            userId,
            mission.getSpotName(),
            mission.getCityName()
        );
    }

    private void validateVisitAndStep(
        Long userId,
        Mission mission,
        MissionVerificationPolicy policy,
        MissionPeriod period
    ) {
        if (policy == null || policy.getMinStepCount() == null) {
            throw new MissionVerificationException("미션 걸음 수 정책을 확인할 수 없습니다.");
        }
        if (mission.getGroup() != MissionGroup.DAILY) {
            validateVisit(userId, mission, period);
        }

        if (storedSteps(userId, period) < policy.getMinStepCount()) {
            throw new MissionVerificationException("동기화된 걸음 수가 미션 목표에 도달하지 않았습니다.");
        }
    }

    private void validateStamp(Long userId, Mission mission, MissionPeriod period) {
        if (acquiredStampCount(userId, period) < mission.getTarget()) {
            throw new MissionVerificationException("미션 기간에 획득한 스탬프가 부족합니다.");
        }
    }

    private long acquiredStampCount(Long userId, MissionPeriod period) {
        validateBoundedPeriod(period);
        return userStampRepository.countByUserIdAndAcquiredAtGreaterThanEqualAndAcquiredAtLessThan(
            userId,
            period.startInclusive(),
            period.endExclusive()
        );
    }

    private void validateCollection(Long userId, Mission mission, MissionPeriod period) {
        if (visitedCityCount(userId, period) < mission.getTarget()) {
            throw new MissionVerificationException("미션 기간에 방문한 시군 수가 부족합니다.");
        }
    }

    private long visitedCityCount(Long userId, MissionPeriod period) {
        validateBoundedPeriod(period);
        return userVisitRepository.countDistinctVisitedCities(
            userId,
            period.startInclusive(),
            period.endExclusive()
        );
    }

    private long storedSteps(Long userId, MissionPeriod period) {
        if (period.hasRange()) {
            LocalDate startDate = LocalDate.ofInstant(period.startInclusive(), SERVICE_ZONE);
            LocalDate endDate = LocalDate.ofInstant(period.endExclusive(), SERVICE_ZONE);
            return userDailyActivityRepository.sumStepsByUserIdAndActivityDateRangeAndSources(
                userId,
                startDate,
                endDate,
                TRUSTED_ACTIVITY_SOURCES
            );
        }

        LocalDate activityDate = currentDate();
        return userDailyActivityRepository.sumStepsByUserIdAndActivityDateAndSources(
            userId,
            activityDate,
            TRUSTED_ACTIVITY_SOURCES
        );
    }

    private void validateBoundedPeriod(MissionPeriod period) {
        if (!period.hasRange()) {
            throw new MissionVerificationException("미션 기간을 확인할 수 없습니다.");
        }
    }

    private LocalDate currentDate() {
        return LocalDate.now(clock.withZone(SERVICE_ZONE));
    }
}
