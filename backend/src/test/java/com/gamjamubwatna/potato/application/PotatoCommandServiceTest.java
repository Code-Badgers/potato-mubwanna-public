package com.gamjamubwatna.potato.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.potato.api.PotatoDailyActivitySyncRequest;
import com.gamjamubwatna.potato.api.PotatoDailyActivitySyncResponse;
import com.gamjamubwatna.potato.api.PotatoRepresentativeResponse;
import com.gamjamubwatna.potato.domain.ActivitySource;
import com.gamjamubwatna.potato.domain.Potato;
import com.gamjamubwatna.potato.domain.PotatoRarity;
import com.gamjamubwatna.potato.domain.UserDailyActivity;
import com.gamjamubwatna.potato.domain.UserDailyActivityRepository;
import com.gamjamubwatna.potato.domain.UserPotato;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class PotatoCommandServiceTest {

    @Mock
    private UserPotatoRepository userPotatoRepository;

    @Mock
    private UserDailyActivityRepository userDailyActivityRepository;

    @Mock
    private UserRepository userRepository;

    private PotatoCommandService potatoCommandService;

    @BeforeEach
    void setUp() {
        potatoCommandService = new PotatoCommandService(
            userPotatoRepository,
            userDailyActivityRepository,
            userRepository
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
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
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
        when(userRepository.findById(1L)).thenReturn(Optional.of(mock(User.class)));
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

    private UserPotato userPotato(Long id, Potato potato, boolean representative) {
        UserPotato userPotato = new UserPotato(
            mock(User.class),
            potato,
            Instant.parse("2026-07-01T00:00:00Z"),
            2,
            1500.0,
            representative
        );
        ReflectionTestUtils.setField(userPotato, "id", id);
        return userPotato;
    }

    private Potato potato(Long id, String name) {
        Potato potato = new Potato(
            "CODE_" + id,
            name,
            "강릉시",
            PotatoRarity.COMMON,
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
