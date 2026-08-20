package com.gamjamubwatna.potato.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.assertj.core.api.Assertions.within;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.potato.api.PotatoCatalogResponse;
import com.gamjamubwatna.potato.api.PotatoGrowthSummaryResponse;
import com.gamjamubwatna.potato.api.UserPotatoCollectionResponse;
import com.gamjamubwatna.potato.domain.ActivitySource;
import com.gamjamubwatna.potato.domain.Potato;
import com.gamjamubwatna.potato.domain.PotatoRarity;
import com.gamjamubwatna.potato.domain.PotatoRepository;
import com.gamjamubwatna.potato.domain.UserDailyActivity;
import com.gamjamubwatna.potato.domain.UserDailyActivityRepository;
import com.gamjamubwatna.potato.domain.UserPotato;
import com.gamjamubwatna.potato.domain.UserPotatoInteractionRepository;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class PotatoQueryServiceTest {

    @Mock
    private PotatoRepository potatoRepository;

    @Mock
    private UserPotatoRepository userPotatoRepository;

    @Mock
    private UserDailyActivityRepository userDailyActivityRepository;

    @Mock
    private UserPotatoInteractionRepository userPotatoInteractionRepository;

    @Mock
    private UserRepository userRepository;

    private PotatoQueryService potatoQueryService;

    @BeforeEach
    void setUp() {
        potatoQueryService = new PotatoQueryService(
            potatoRepository,
            userPotatoRepository,
            userDailyActivityRepository,
            userPotatoInteractionRepository,
            userRepository,
            new PotatoCareStatusPolicy()
        );
    }

    @Test
    void returnsActivePotatoCatalogInRepositoryOrder() {
        when(potatoRepository.findByActiveTrueOrderByDisplayOrderAsc())
            .thenReturn(List.of(potato(1L, "하지감자", PotatoRarity.COMMON)));

        PotatoCatalogResponse result = potatoQueryService.getPotatoes();

        assertThat(result.totalCount()).isEqualTo(1);
        assertThat(result.items().getFirst().potatoId()).isEqualTo(1L);
        assertThat(result.items().getFirst().name()).isEqualTo("하지감자");
        assertThat(result.items().getFirst().rarity()).isEqualTo(PotatoRarity.COMMON);
    }

    @Test
    void mergesAcquiredPotatoesIntoFullCatalog() {
        Potato acquired = potato(1L, "곤드레감자", PotatoRarity.RARE);
        Potato locked = potato(2L, "전설감자", PotatoRarity.LEGENDARY);
        UserPotato userPotato = new UserPotato(
            mock(User.class),
            acquired,
            Instant.parse("2026-07-01T00:00:00Z"),
            3,
            4200.0,
            true
        );
        when(userRepository.existsById(1L)).thenReturn(true);
        when(potatoRepository.findByActiveTrueOrderByDisplayOrderAsc())
            .thenReturn(List.of(acquired, locked));
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(userPotato));

        UserPotatoCollectionResponse result = potatoQueryService.getMyPotatoes(1L);

        assertThat(result.totalCount()).isEqualTo(2);
        assertThat(result.acquiredCount()).isEqualTo(1);
        assertThat(result.items().getFirst().acquired()).isTrue();
        assertThat(result.items().getFirst().level()).isEqualTo(3);
        assertThat(result.items().getFirst().representative()).isTrue();
        assertThat(result.items().getFirst().careStatus()).isNotNull();
        assertThat(result.items().getFirst().careStatus().satiety()).isBetween(20, 100);
        assertThat(result.items().get(1).acquired()).isFalse();
        assertThat(result.items().get(1).level()).isZero();
        assertThat(result.items().get(1).careStatus()).isNull();
    }

    @Test
    void rejectsDeletedUser() {
        when(userRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> potatoQueryService.getMyPotatoes(99L))
            .isInstanceOf(PotatoAuthenticationException.class);
    }

    @Test
    void returnsGrowthSummaryWithRepresentativeRemainingDistance() {
        LocalDate today = LocalDate.parse("2026-07-21");
        Potato potato = potato(1L, "하지감자", PotatoRarity.COMMON);
        UserPotato representativePotato = new UserPotato(
            mock(User.class),
            potato,
            Instant.parse("2026-07-01T00:00:00Z"),
            2,
            1500.0,
            true
        );
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userDailyActivityRepository.findByUserIdAndActivityDateBetween(
            1L,
            today.withDayOfMonth(1),
            today
        )).thenReturn(List.of());
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(representativePotato));

        PotatoGrowthSummaryResponse result = potatoQueryService.getGrowthSummary(1L, today);

        assertThat(result.todaySteps()).isZero();
        assertThat(result.dailyStepGoal()).isEqualTo(10000);
        assertThat(result.weeklyDistanceKm()).isZero();
        assertThat(result.monthlyDistanceKm()).isZero();
        assertThat(result.remainingDistanceKmForRepresentative()).isEqualTo(1.5);
    }

    @Test
    void returnsZeroRemainingDistanceWhenRepresentativePotatoIsMissing() {
        LocalDate today = LocalDate.parse("2026-07-21");
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userDailyActivityRepository.findByUserIdAndActivityDateBetween(
            1L,
            today.withDayOfMonth(1),
            today
        )).thenReturn(List.of());
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of());

        PotatoGrowthSummaryResponse result = potatoQueryService.getGrowthSummary(1L, today);

        assertThat(result.remainingDistanceKmForRepresentative()).isZero();
    }

    @Test
    void returnsZeroRemainingDistanceForCompletedRepresentativePotato() {
        LocalDate today = LocalDate.parse("2026-07-21");
        UserPotato representativePotato = new UserPotato(
            mock(User.class),
            potato(1L, "하지감자", PotatoRarity.COMMON),
            Instant.parse("2026-07-01T00:00:00Z"),
            5,
            500.0,
            true
        );
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userDailyActivityRepository.findByUserIdAndActivityDateBetween(
            1L,
            today.withDayOfMonth(1),
            today
        )).thenReturn(List.of());
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(representativePotato));

        PotatoGrowthSummaryResponse result = potatoQueryService.getGrowthSummary(1L, today);

        assertThat(result.remainingDistanceKmForRepresentative()).isZero();
    }

    @Test
    void returnsGrowthSummaryFromStoredActivities() {
        LocalDate today = LocalDate.parse("2026-07-21");
        Potato potato = potato(1L, "하지감자", PotatoRarity.COMMON);
        UserPotato representativePotato = new UserPotato(
            mock(User.class),
            potato,
            Instant.parse("2026-07-01T00:00:00Z"),
            2,
            1500.0,
            true
        );
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userDailyActivityRepository.findByUserIdAndActivityDateBetween(
            1L,
            today.withDayOfMonth(1),
            today
        )).thenReturn(List.of(
            activity(today, 8420, 5894.0),
            activity(today.minusDays(1), 3000, 2100.0),
            activity(today.withDayOfMonth(1), 1000, 700.0)
        ));
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(representativePotato));

        PotatoGrowthSummaryResponse result = potatoQueryService.getGrowthSummary(1L, today);

        assertThat(result.todaySteps()).isEqualTo(8420);
        assertThat(result.dailyStepGoal()).isEqualTo(10000);
        assertThat(result.weeklyDistanceKm()).isEqualTo(7.994);
        assertThat(result.monthlyDistanceKm()).isEqualTo(8.694);
        assertThat(result.remainingDistanceKmForRepresentative()).isEqualTo(1.5);
    }

    @Test
    void usesKoreaDateForGrowthSummaryWhenServerInstantIsPreviousUtcDate() {
        LocalDate koreaToday = LocalDate.parse("2026-08-21");
        Clock koreaClock = Clock.fixed(
            Instant.parse("2026-08-20T15:30:00Z"),
            ZoneId.of("Asia/Seoul")
        );
        potatoQueryService = new PotatoQueryService(
            potatoRepository,
            userPotatoRepository,
            userDailyActivityRepository,
            userPotatoInteractionRepository,
            userRepository,
            new PotatoCareStatusPolicy(),
            koreaClock
        );
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userDailyActivityRepository.findByUserIdAndActivityDateBetween(
            1L,
            koreaToday.withDayOfMonth(1),
            koreaToday
        )).thenReturn(List.of(activity(koreaToday, 4321, 3024.7)));
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of());

        PotatoGrowthSummaryResponse result = potatoQueryService.getGrowthSummary(1L);

        assertThat(result.todaySteps()).isEqualTo(4321);
        assertThat(result.weeklyDistanceKm()).isCloseTo(3.0247, within(0.0000001));
        assertThat(result.monthlyDistanceKm()).isCloseTo(3.0247, within(0.0000001));
    }

    @Test
    void includesPreviousMonthActivitiesInWeeklyDistanceAtStartOfMonth() {
        LocalDate today = LocalDate.parse("2026-08-03");
        Potato potato = potato(1L, "하지감자", PotatoRarity.COMMON);
        UserPotato representativePotato = new UserPotato(
            mock(User.class),
            potato,
            Instant.parse("2026-07-01T00:00:00Z"),
            2,
            1500.0,
            true
        );
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userDailyActivityRepository.findByUserIdAndActivityDateBetween(
            1L,
            LocalDate.parse("2026-07-28"),
            today
        )).thenReturn(List.of(
            activity(LocalDate.parse("2026-07-29"), 2000, 1400.0),
            activity(LocalDate.parse("2026-08-01"), 3000, 2100.0),
            activity(today, 4000, 2800.0)
        ));
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(representativePotato));

        PotatoGrowthSummaryResponse result = potatoQueryService.getGrowthSummary(1L, today);

        assertThat(result.todaySteps()).isEqualTo(4000);
        assertThat(result.dailyStepGoal()).isEqualTo(10000);
        assertThat(result.weeklyDistanceKm()).isEqualTo(6.3);
        assertThat(result.monthlyDistanceKm()).isEqualTo(4.9);
        assertThat(result.remainingDistanceKmForRepresentative()).isEqualTo(1.5);
    }

    @Test
    void rejectsDeletedUserForGrowthSummary() {
        when(userRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> potatoQueryService.getGrowthSummary(99L))
            .isInstanceOf(PotatoAuthenticationException.class);
    }

    private Potato potato(Long id, String name, PotatoRarity rarity) {
        Potato potato = new Potato(
            "CODE_" + id,
            name,
            "강릉시",
            rarity,
            name + " 설명",
            name + " 획득 방법",
            null,
            3000.0,
            id.intValue(),
            true,
            Instant.parse("2026-07-01T00:00:00Z")
        );
        ReflectionTestUtils.setField(potato, "id", id);
        return potato;
    }

    private UserDailyActivity activity(LocalDate date, int steps, double distanceMeters) {
        return new UserDailyActivity(
            mock(User.class),
            date,
            steps,
            distanceMeters,
            ActivitySource.HEALTH_CONNECT,
            Instant.parse("2026-07-21T00:00:00Z")
        );
    }
}
