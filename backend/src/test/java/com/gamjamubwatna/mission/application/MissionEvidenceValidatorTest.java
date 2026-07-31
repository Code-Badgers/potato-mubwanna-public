package com.gamjamubwatna.mission.application;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.mission.domain.Mission;
import com.gamjamubwatna.mission.domain.MissionGroup;
import com.gamjamubwatna.mission.domain.MissionRewardType;
import com.gamjamubwatna.mission.domain.MissionStatus;
import com.gamjamubwatna.mission.domain.MissionType;
import com.gamjamubwatna.mission.domain.MissionVerificationPolicy;
import com.gamjamubwatna.potato.domain.ActivitySource;
import com.gamjamubwatna.potato.domain.UserDailyActivityRepository;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import com.gamjamubwatna.visit.domain.UserVisitRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class MissionEvidenceValidatorTest {

    private static final Instant DAILY_START = Instant.parse("2026-06-30T15:00:00Z");
    private static final Instant WEEKLY_START = Instant.parse("2026-06-28T15:00:00Z");
    private static final Instant END_EXCLUSIVE = Instant.parse("2026-07-01T15:00:00Z");

    @Mock
    private UserVisitRepository userVisitRepository;

    @Mock
    private UserStampRepository userStampRepository;

    @Mock
    private UserDailyActivityRepository userDailyActivityRepository;

    private MissionEvidenceValidator validator;

    @BeforeEach
    void setUp() {
        validator = new MissionEvidenceValidator(
            userVisitRepository,
            userStampRepository,
            userDailyActivityRepository,
            Clock.fixed(Instant.parse("2026-07-01T00:00:00Z"), ZoneOffset.UTC)
        );
    }

    @Test
    void verifiesVisitFromStoredVisitEvidence() {
        Mission mission = mission(MissionGroup.EVENT, MissionType.VISIT, 1);
        when(userVisitRepository.existsByUserIdAndTouristSpotNameAndTouristSpotCityName(
            1L,
            "정선 5일장",
            "정선군"
        )).thenReturn(true);

        assertThatCode(() -> validator.validate(1L, mission, null))
            .doesNotThrowAnyException();
    }

    @Test
    void rejectsVisitWithoutStoredVisitEvidence() {
        Mission mission = mission(MissionGroup.EVENT, MissionType.VISIT, 1);

        assertThatThrownBy(() -> validator.validate(1L, mission, null))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("해당 장소의 방문 인증을 먼저 완료해주세요.");
    }

    @Test
    void verifiesDailyStepsFromStoredHealthActivity() {
        Mission mission = mission(MissionGroup.DAILY, MissionType.VISIT_AND_STEP, 10_000);
        MissionVerificationPolicy policy = stepPolicy(mission, 10_000);
        when(userDailyActivityRepository.sumStepsByUserIdAndActivityDateAndSources(
            1L,
            LocalDate.of(2026, 7, 1),
            List.of(ActivitySource.HEALTH_KIT, ActivitySource.HEALTH_CONNECT)
        )).thenReturn(10_200L);

        assertThatCode(() -> validator.validate(1L, mission, policy))
            .doesNotThrowAnyException();
    }

    @Test
    void requiresVisitForLocationStepMission() {
        Mission mission = mission(MissionGroup.JUMSOONI, MissionType.VISIT_AND_STEP, 1_000);
        MissionVerificationPolicy policy = stepPolicy(mission, 1_000);

        assertThatThrownBy(() -> validator.validate(1L, mission, policy))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("해당 장소의 방문 인증을 먼저 완료해주세요.");
    }

    @Test
    void rejectsInsufficientStoredSteps() {
        Mission mission = mission(MissionGroup.DAILY, MissionType.VISIT_AND_STEP, 10_000);
        MissionVerificationPolicy policy = stepPolicy(mission, 10_000);
        when(userDailyActivityRepository.sumStepsByUserIdAndActivityDateAndSources(
            1L,
            LocalDate.of(2026, 7, 1),
            List.of(ActivitySource.HEALTH_KIT, ActivitySource.HEALTH_CONNECT)
        )).thenReturn(9_999L);

        assertThatThrownBy(() -> validator.validate(1L, mission, policy))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("동기화된 걸음 수가 미션 목표에 도달하지 않았습니다.");
    }

    @Test
    void rejectsStepMissionWithoutMinimumStepPolicy() {
        Mission mission = mission(MissionGroup.DAILY, MissionType.VISIT_AND_STEP, 10_000);

        assertThatThrownBy(() -> validator.validate(1L, mission, stepPolicy(mission, null)))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("미션 걸음 수 정책을 확인할 수 없습니다.");
    }

    @Test
    void verifiesDailyStampFromAcquisitionTime() {
        Mission mission = mission(MissionGroup.DAILY, MissionType.STAMP, 1);
        when(userStampRepository
            .countByUserIdAndAcquiredAtGreaterThanEqualAndAcquiredAtLessThan(
                1L,
                DAILY_START,
                END_EXCLUSIVE
            )).thenReturn(1L);

        assertThatCode(() -> validator.validate(1L, mission, null))
            .doesNotThrowAnyException();
    }

    @Test
    void verifiesWeeklyCollectionFromDistinctVisitedCities() {
        Mission mission = mission(MissionGroup.WEEKLY, MissionType.COLLECTION, 3);
        when(userVisitRepository.countDistinctVisitedCities(
            1L,
            WEEKLY_START,
            END_EXCLUSIVE
        )).thenReturn(3L);

        assertThatCode(() -> validator.validate(1L, mission, null))
            .doesNotThrowAnyException();
        verify(userVisitRepository).countDistinctVisitedCities(
            1L,
            WEEKLY_START,
            END_EXCLUSIVE
        );
    }

    @Test
    void rejectsCollectionWithoutEnoughDistinctCities() {
        Mission mission = mission(MissionGroup.WEEKLY, MissionType.COLLECTION, 3);
        when(userVisitRepository.countDistinctVisitedCities(
            1L,
            WEEKLY_START,
            END_EXCLUSIVE
        )).thenReturn(2L);

        assertThatThrownBy(() -> validator.validate(1L, mission, null))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("미션 기간에 방문한 시군 수가 부족합니다.");
    }

    private Mission mission(MissionGroup group, MissionType type, int target) {
        Mission mission = new Mission(
            "MISSION_EVIDENCE",
            group,
            type,
            MissionStatus.READY,
            "증빙 미션",
            "정선 5일장",
            "정선군",
            "서버 증빙 확인",
            "증빙을 확인한다.",
            "조건",
            MissionRewardType.ITEM,
            "보상",
            0,
            target,
            false,
            true,
            1,
            Instant.parse("2026-07-01T00:00:00Z")
        );
        ReflectionTestUtils.setField(mission, "id", 1L);
        return mission;
    }

    private MissionVerificationPolicy stepPolicy(Mission mission, Integer minimumSteps) {
        return new MissionVerificationPolicy(
            mission,
            MissionType.VISIT_AND_STEP,
            null,
            null,
            false,
            minimumSteps,
            Instant.parse("2026-07-01T00:00:00Z")
        );
    }
}
