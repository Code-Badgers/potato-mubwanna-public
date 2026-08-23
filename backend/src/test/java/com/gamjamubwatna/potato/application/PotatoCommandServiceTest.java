package com.gamjamubwatna.potato.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.potato.api.PotatoDailyActivitySyncRequest;
import com.gamjamubwatna.potato.api.PotatoDailyActivitySyncResponse;
import com.gamjamubwatna.potato.api.PotatoInteractionRequest;
import com.gamjamubwatna.potato.api.PotatoInteractionResponse;
import com.gamjamubwatna.potato.api.PotatoRepresentativeResponse;
import com.gamjamubwatna.potato.domain.ActivitySource;
import com.gamjamubwatna.potato.domain.Potato;
import com.gamjamubwatna.potato.domain.PotatoInteractionAction;
import com.gamjamubwatna.potato.domain.PotatoRarity;
import com.gamjamubwatna.potato.domain.UserDailyActivity;
import com.gamjamubwatna.potato.domain.UserDailyActivityRepository;
import com.gamjamubwatna.potato.domain.UserPotato;
import com.gamjamubwatna.potato.domain.UserPotatoInteraction;
import com.gamjamubwatna.potato.domain.UserPotatoInteractionRepository;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import com.gamjamubwatna.push.application.PushEventPublisher;
import com.gamjamubwatna.push.application.PushNotificationMessage;
import com.gamjamubwatna.push.domain.PushDestination;
import java.time.Clock;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.ArgumentCaptor;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class PotatoCommandServiceTest {

    @Mock
    private UserPotatoRepository userPotatoRepository;

    @Mock
    private UserPotatoInteractionRepository userPotatoInteractionRepository;

    @Mock
    private UserDailyActivityRepository userDailyActivityRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private PushEventPublisher pushEventPublisher;

    private PotatoCommandService potatoCommandService;

    @BeforeEach
    void setUp() {
        potatoCommandService = new PotatoCommandService(
            userPotatoRepository,
            userPotatoInteractionRepository,
            userDailyActivityRepository,
            userRepository,
            new PotatoCareStatusPolicy(),
            pushEventPublisher,
            Clock.fixed(Instant.parse("2026-07-21T10:00:00Z"), ZoneOffset.UTC)
        );
    }

    @Test
    void updatesRepresentativePotatoAndUnmarksPreviousOne() {
        UserPotato previous = userPotato(1L, potato(1L, "하지감자"), true);
        UserPotato selected = userPotato(2L, potato(2L, "곤드레감자"), false);
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(previous, selected));

        PotatoRepresentativeResponse result =
            potatoCommandService.updateRepresentativePotato(1L, 2L);

        assertThat(result.potatoId()).isEqualTo(2L);
        assertThat(result.representative()).isTrue();
        assertThat(previous.isRepresentative()).isFalse();
        assertThat(selected.isRepresentative()).isTrue();
    }

    @Test
    void succeedsWhenSamePotatoIsAlreadyRepresentative() {
        UserPotato selected = userPotato(1L, potato(1L, "하지감자"), true);
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(selected));

        PotatoRepresentativeResponse result =
            potatoCommandService.updateRepresentativePotato(1L, 1L);

        assertThat(result.potatoId()).isEqualTo(1L);
        assertThat(selected.isRepresentative()).isTrue();
    }

    @Test
    void rejectsUnacquiredPotato() {
        UserPotato acquired = userPotato(1L, potato(1L, "하지감자"), true);
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(acquired));

        assertThatThrownBy(() -> potatoCommandService.updateRepresentativePotato(1L, 99L))
            .isInstanceOf(PotatoRepresentativeException.class)
            .hasMessage("획득한 감자만 대표 감자로 설정할 수 있습니다.");
    }

    @Test
    void rejectsDeletedUser() {
        when(userRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> potatoCommandService.updateRepresentativePotato(99L, 1L))
            .isInstanceOf(PotatoAuthenticationException.class);
    }

    @Test
    void createsDailyActivityWhenActivityDoesNotExist() {
        User user = mock(User.class);
        UserPotato representative = userPotato(1L, potato(1L, "자주감자", PotatoRarity.RARE), true);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(representative));
        when(userDailyActivityRepository.findByUserIdAndActivityDateAndSource(
            1L,
            LocalDate.parse("2026-07-21"),
            ActivitySource.HEALTH_CONNECT
        )).thenReturn(Optional.empty());
        when(userDailyActivityRepository.save(any(UserDailyActivity.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

        PotatoDailyActivitySyncResponse result = potatoCommandService.syncDailyActivity(
            1L,
            new PotatoDailyActivitySyncRequest(
                LocalDate.parse("2026-07-21"),
                8420,
                5894.0,
                ActivitySource.HEALTH_CONNECT
            )
        );

        assertThat(result.activityDate()).isEqualTo(LocalDate.parse("2026-07-21"));
        assertThat(result.steps()).isEqualTo(8420);
        assertThat(result.distanceMeters()).isEqualTo(5894.0);
        assertThat(result.source()).isEqualTo(ActivitySource.HEALTH_CONNECT);
        assertThat(result.syncedAt()).isNotNull();
        assertThat(result.growthResult()).isNotNull();
        assertThat(result.growthResult().potatoId()).isEqualTo(1L);
        assertThat(result.growthResult().potatoName()).isEqualTo("자주감자");
        assertThat(result.growthResult().previousLevel()).isEqualTo(2);
        assertThat(result.growthResult().currentLevel()).isEqualTo(4);
        assertThat(result.growthResult().leveledUp()).isTrue();
        assertThat(result.growthResult().fullyGrown()).isFalse();
        assertThat(representative.getLevel()).isEqualTo(4);
        assertThat(representative.getGrowthDistance()).isEqualTo(1394.0);
        ArgumentCaptor<PushNotificationMessage> pushCaptor =
            ArgumentCaptor.forClass(PushNotificationMessage.class);
        verify(pushEventPublisher).publish(eq(1L), pushCaptor.capture());
        assertThat(pushCaptor.getValue().destination()).isEqualTo(PushDestination.POTATOES);
        assertThat(pushCaptor.getValue().body()).contains("Lv.4");
    }

    @Test
    void updatesDailyActivityWhenActivityAlreadyExists() {
        UserDailyActivity activity = new UserDailyActivity(
            mock(User.class),
            LocalDate.parse("2026-07-21"),
            3000,
            2100.0,
            ActivitySource.HEALTH_KIT,
            Instant.parse("2026-07-21T00:00:00Z")
        );
        UserPotato representative = userPotato(1L, potato(1L, "하지감자"), true);
        when(userRepository.findById(1L)).thenReturn(Optional.of(mock(User.class)));
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(representative));
        when(userDailyActivityRepository.findByUserIdAndActivityDateAndSource(
            1L,
            LocalDate.parse("2026-07-21"),
            ActivitySource.HEALTH_KIT
        )).thenReturn(Optional.of(activity));
        when(userDailyActivityRepository.save(any(UserDailyActivity.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

        PotatoDailyActivitySyncResponse result = potatoCommandService.syncDailyActivity(
            1L,
            new PotatoDailyActivitySyncRequest(
                LocalDate.parse("2026-07-21"),
                9000,
                6300.0,
                ActivitySource.HEALTH_KIT
            )
        );

        assertThat(result.steps()).isEqualTo(9000);
        assertThat(result.distanceMeters()).isEqualTo(6300.0);
        assertThat(result.growthResult()).isNotNull();
        assertThat(result.growthResult().previousLevel()).isEqualTo(2);
        assertThat(result.growthResult().currentLevel()).isEqualTo(3);
        assertThat(result.growthResult().leveledUp()).isTrue();
        assertThat(representative.getLevel()).isEqualTo(3);
        assertThat(representative.getGrowthDistance()).isEqualTo(3000.0);
    }

    @Test
    void doesNotDuplicateGrowthWhenSnapshotIsUnchangedOrDecreased() {
        UserDailyActivity activity = new UserDailyActivity(
            mock(User.class),
            LocalDate.parse("2026-07-21"),
            5000,
            3500.0,
            ActivitySource.HEALTH_CONNECT,
            Instant.parse("2026-07-21T00:00:00Z")
        );
        when(userRepository.findById(1L)).thenReturn(Optional.of(mock(User.class)));
        when(userDailyActivityRepository.findByUserIdAndActivityDateAndSource(
            1L,
            LocalDate.parse("2026-07-21"),
            ActivitySource.HEALTH_CONNECT
        )).thenReturn(Optional.of(activity));
        when(userDailyActivityRepository.save(any(UserDailyActivity.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

        PotatoDailyActivitySyncResponse result = potatoCommandService.syncDailyActivity(
            1L,
            new PotatoDailyActivitySyncRequest(
                LocalDate.parse("2026-07-21"),
                4500,
                3000.0,
                ActivitySource.HEALTH_CONNECT
            )
        );

        assertThat(result.steps()).isEqualTo(5000);
        assertThat(result.distanceMeters()).isEqualTo(3500.0);
        assertThat(result.growthResult()).isNull();
        verify(userPotatoRepository, never()).findByUserId(1L);
    }

    @Test
    void reportsWhenRepresentativePotatoBecomesFullyGrown() {
        User user = mock(User.class);
        UserPotato representative = userPotato(
            1L,
            potato(1L, "자주감자", PotatoRarity.RARE),
            4,
            2900.0,
            true
        );
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(representative));
        when(userDailyActivityRepository.findByUserIdAndActivityDateAndSource(
            1L,
            LocalDate.parse("2026-07-21"),
            ActivitySource.HEALTH_CONNECT
        )).thenReturn(Optional.empty());
        when(userDailyActivityRepository.save(any(UserDailyActivity.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

        PotatoDailyActivitySyncResponse result = potatoCommandService.syncDailyActivity(
            1L,
            new PotatoDailyActivitySyncRequest(
                LocalDate.parse("2026-07-21"),
                1000,
                200.0,
                ActivitySource.HEALTH_CONNECT
            )
        );

        assertThat(result.growthResult()).isNotNull();
        assertThat(result.growthResult().previousLevel()).isEqualTo(4);
        assertThat(result.growthResult().currentLevel()).isEqualTo(5);
        assertThat(result.growthResult().leveledUp()).isTrue();
        assertThat(result.growthResult().fullyGrown()).isTrue();
    }

    @Test
    void omitsGrowthResultWhenRepresentativePotatoIsAlreadyFullyGrown() {
        User user = mock(User.class);
        UserPotato representative = userPotato(
            1L,
            potato(1L, "자주감자", PotatoRarity.RARE),
            5,
            3000.0,
            true
        );
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(representative));
        when(userDailyActivityRepository.findByUserIdAndActivityDateAndSource(
            1L,
            LocalDate.parse("2026-07-21"),
            ActivitySource.HEALTH_CONNECT
        )).thenReturn(Optional.empty());
        when(userDailyActivityRepository.save(any(UserDailyActivity.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

        PotatoDailyActivitySyncResponse result = potatoCommandService.syncDailyActivity(
            1L,
            new PotatoDailyActivitySyncRequest(
                LocalDate.parse("2026-07-21"),
                1000,
                200.0,
                ActivitySource.HEALTH_CONNECT
            )
        );

        assertThat(result.growthResult()).isNull();
        assertThat(representative.getLevel()).isEqualTo(5);
        assertThat(representative.getGrowthDistance()).isEqualTo(3000.0);
    }

    @Test
    void omitsGrowthResultWhenUserHasNoRepresentativePotato() {
        User user = mock(User.class);
        UserPotato nonRepresentative = userPotato(
            1L,
            potato(1L, "하지감자"),
            false
        );
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(nonRepresentative));
        when(userDailyActivityRepository.findByUserIdAndActivityDateAndSource(
            1L,
            LocalDate.parse("2026-07-21"),
            ActivitySource.HEALTH_CONNECT
        )).thenReturn(Optional.empty());
        when(userDailyActivityRepository.save(any(UserDailyActivity.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

        PotatoDailyActivitySyncResponse result = potatoCommandService.syncDailyActivity(
            1L,
            new PotatoDailyActivitySyncRequest(
                LocalDate.parse("2026-07-21"),
                1000,
                200.0,
                ActivitySource.HEALTH_CONNECT
            )
        );

        assertThat(result.growthResult()).isNull();
        assertThat(nonRepresentative.getGrowthDistance()).isEqualTo(1500.0);
    }

    @Test
    void rejectsNegativeSteps() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(mock(User.class)));

        assertThatThrownBy(() -> potatoCommandService.syncDailyActivity(
            1L,
            new PotatoDailyActivitySyncRequest(
                LocalDate.parse("2026-07-21"),
                -1,
                100.0,
                ActivitySource.HEALTH_CONNECT
            )
        ))
            .isInstanceOf(PotatoActivityException.class)
            .hasMessage("걸음 수가 허용 범위를 벗어났습니다.");
    }

    @Test
    void rejectsNonFiniteDistance() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(mock(User.class)));

        assertThatThrownBy(() -> potatoCommandService.syncDailyActivity(
            1L,
            new PotatoDailyActivitySyncRequest(
                LocalDate.parse("2026-07-21"),
                100,
                Double.NaN,
                ActivitySource.HEALTH_CONNECT
            )
        ))
            .isInstanceOf(PotatoActivityException.class)
            .hasMessage("이동 거리가 허용 범위를 벗어났습니다.");
    }

    @Test
    void interactsWithRepresentativePotatoAndAppliesGrowth() {
        UserPotato representative = userPotato(1L, potato(1L, "새싹감자"), 2, 2950.0, true);
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(representative));
        when(userPotatoInteractionRepository.findTopByUserPotatoIdAndActionOrderByInteractedAtDesc(
            1L,
            PotatoInteractionAction.PAT
        )).thenReturn(Optional.empty());
        when(userPotatoInteractionRepository.save(any(UserPotatoInteraction.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

        PotatoInteractionResponse result = potatoCommandService.interactWithRepresentativePotato(
            1L,
            new PotatoInteractionRequest(PotatoInteractionAction.PAT)
        );

        assertThat(result.potatoId()).isEqualTo(1L);
        assertThat(result.action()).isEqualTo(PotatoInteractionAction.PAT);
        assertThat(result.growthDistanceAdded()).isEqualTo(50.0);
        assertThat(result.cooldownSeconds()).isEqualTo(1800);
        assertThat(result.nextAvailableAt()).isEqualTo(Instant.parse("2026-07-21T10:30:00Z"));
        assertThat(result.growthResult().previousLevel()).isEqualTo(2);
        assertThat(result.growthResult().currentLevel()).isEqualTo(3);
        assertThat(result.growthResult().fullyGrown()).isTrue();
        assertThat(result.careStatus().mood()).isEqualTo(100);
        ArgumentCaptor<PushNotificationMessage> pushCaptor =
            ArgumentCaptor.forClass(PushNotificationMessage.class);
        verify(pushEventPublisher).publish(eq(1L), pushCaptor.capture());
        assertThat(pushCaptor.getValue().destination()).isEqualTo(PushDestination.POTATOES);
        assertThat(pushCaptor.getValue().body()).contains("Lv.3");
    }

    @Test
    void rejectsInteractionDuringCooldown() {
        UserPotato representative = userPotato(1L, potato(1L, "새싹감자"), 1, 0.0, true);
        UserPotatoInteraction lastInteraction = new UserPotatoInteraction(
            representative,
            PotatoInteractionAction.WATER,
            120.0,
            Instant.parse("2026-07-21T09:30:00Z")
        );
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(representative));
        when(userPotatoInteractionRepository.findTopByUserPotatoIdAndActionOrderByInteractedAtDesc(
            1L,
            PotatoInteractionAction.WATER
        )).thenReturn(Optional.of(lastInteraction));

        assertThatThrownBy(() -> potatoCommandService.interactWithRepresentativePotato(
            1L,
            new PotatoInteractionRequest(PotatoInteractionAction.WATER)
        ))
            .isInstanceOf(PotatoInteractionCooldownException.class)
            .hasMessage("아직 다시 돌볼 수 없습니다. 잠시 후 다시 시도해주세요.");

        verify(userPotatoInteractionRepository, never()).save(any(UserPotatoInteraction.class));
    }

    @Test
    void rejectsInteractionWhenRepresentativePotatoDoesNotExist() {
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of());

        assertThatThrownBy(() -> potatoCommandService.interactWithRepresentativePotato(
            1L,
            new PotatoInteractionRequest(PotatoInteractionAction.SNACK)
        ))
            .isInstanceOf(PotatoInteractionException.class)
            .hasMessage("대표 감자를 먼저 설정해주세요.");
    }

    @Test
    void harvestsFullyGrownRepresentativePotato() {
        UserPotato representative =
            userPotato(1L, potato(1L, "새싹감자"), 3, 3000.0, true, null);
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(representative));

        var result = potatoCommandService.harvestRepresentativePotato(1L);

        assertThat(result.potatoId()).isEqualTo(1L);
        assertThat(result.potatoName()).isEqualTo("새싹감자");
        assertThat(result.harvested()).isTrue();
        assertThat(result.harvestedAt()).isEqualTo(Instant.parse("2026-07-21T10:00:00Z"));
        assertThat(representative.isHarvested()).isTrue();
    }

    @Test
    void rejectsHarvestBeforeRepresentativePotatoIsFullyGrown() {
        UserPotato representative =
            userPotato(1L, potato(1L, "새싹감자"), 2, 1500.0, true, null);
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(representative));

        assertThatThrownBy(() -> potatoCommandService.harvestRepresentativePotato(1L))
            .isInstanceOf(PotatoInteractionException.class)
            .hasMessage("아직 수확할 수 없습니다. 조금만 더 키워주세요.");
    }

    private UserPotato userPotato(Long id, Potato potato, boolean representative) {
        return userPotato(id, potato, 2, 1500.0, representative);
    }

    private UserPotato userPotato(
        Long id,
        Potato potato,
        int level,
        double growthDistance,
        boolean representative
    ) {
        return userPotato(id, potato, level, growthDistance, representative, Instant.parse("2026-07-01T00:00:00Z"));
    }

    private UserPotato userPotato(
        Long id,
        Potato potato,
        int level,
        double growthDistance,
        boolean representative,
        Instant harvestedAt
    ) {
        UserPotato userPotato = new UserPotato(
            mock(User.class),
            potato,
            Instant.parse("2026-07-01T00:00:00Z"),
            level,
            growthDistance,
            representative,
            harvestedAt
        );
        ReflectionTestUtils.setField(userPotato, "id", id);
        return userPotato;
    }

    private Potato potato(Long id, String name) {
        return potato(id, name, PotatoRarity.COMMON);
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
}
