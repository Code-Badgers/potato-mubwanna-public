package com.gamjamubwatna.stamp.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.stamp.api.StampBookResponse;
import com.gamjamubwatna.stamp.api.StampRewardStatusResponse;
import com.gamjamubwatna.stamp.domain.Stamp;
import com.gamjamubwatna.stamp.domain.StampRepository;
import com.gamjamubwatna.stamp.domain.UserStamp;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import java.time.Instant;
import java.util.List;
import java.util.stream.IntStream;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.Arguments;
import org.junit.jupiter.params.provider.MethodSource;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class StampQueryServiceTest {

    @Mock
    private StampRepository stampRepository;

    @Mock
    private UserStampRepository userStampRepository;

    @Mock
    private UserRepository userRepository;

    private StampQueryService stampQueryService;

    @BeforeEach
    void setUp() {
        stampQueryService = new StampQueryService(
            stampRepository,
            userStampRepository,
            userRepository
        );
    }

    @Test
    void returnsAllStampsWithUserAcquisitionState() {
        List<Stamp> stamps = IntStream.rangeClosed(1, 18)
            .mapToObj(index -> stamp((long) index, "시군 " + index, "감자 " + index, index))
            .toList();
        Instant acquiredAt = Instant.parse("2026-06-30T00:00:00Z");
        UserStamp acquired = new UserStamp(null, stamps.getFirst(), null, acquiredAt);
        when(userRepository.existsById(1L)).thenReturn(true);
        when(stampRepository.findAllByOrderByDisplayOrderAsc()).thenReturn(stamps);
        when(userStampRepository.findByUserIdWithStamp(1L)).thenReturn(List.of(acquired));

        StampBookResponse result = stampQueryService.getStampBook(1L);

        assertThat(result.totalCount()).isEqualTo(18);
        assertThat(result.acquiredCount()).isEqualTo(1);
        assertThat(result.stamps()).hasSize(18);
        assertThat(result.stamps().getFirst().acquired()).isTrue();
        assertThat(result.stamps().getFirst().acquiredAt()).isEqualTo(acquiredAt);
        assertThat(result.stamps().get(1).acquired()).isFalse();
        assertThat(result.stamps().get(1).acquiredAt()).isNull();
    }

    @Test
    void returnsEmptyAcquisitionStateWithoutUserStamps() {
        List<Stamp> stamps = List.of(stamp(1L, "강릉시", "하지감자", 1));
        when(userRepository.existsById(2L)).thenReturn(true);
        when(stampRepository.findAllByOrderByDisplayOrderAsc()).thenReturn(stamps);
        when(userStampRepository.findByUserIdWithStamp(2L)).thenReturn(List.of());

        StampBookResponse result = stampQueryService.getStampBook(2L);

        assertThat(result.totalCount()).isEqualTo(1);
        assertThat(result.acquiredCount()).isZero();
        assertThat(result.stamps().getFirst().acquired()).isFalse();
    }

    @ParameterizedTest
    @MethodSource("rewardBoundaries")
    void calculatesNextRewardBoundary(
        int acquiredCount,
        Integer nextTargetCount,
        int remainingCount,
        boolean completed
    ) {
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userStampRepository.countByUserId(1L)).thenReturn(acquiredCount);

        StampRewardStatusResponse result = stampQueryService.getRewardStatus(1L);

        assertThat(result.acquiredCount()).isEqualTo(acquiredCount);
        assertThat(result.nextTargetCount()).isEqualTo(nextTargetCount);
        assertThat(result.remainingCount()).isEqualTo(remainingCount);
        assertThat(result.completed()).isEqualTo(completed);
    }

    @Test
    void rejectsJwtSubjectForDeletedUser() {
        when(userRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> stampQueryService.getStampBook(99L))
            .isInstanceOf(StampAuthenticationException.class);
    }

    private static java.util.stream.Stream<Arguments> rewardBoundaries() {
        return java.util.stream.Stream.of(
            Arguments.of(0, 6, 6, false),
            Arguments.of(5, 6, 1, false),
            Arguments.of(6, 12, 6, false),
            Arguments.of(11, 12, 1, false),
            Arguments.of(12, 18, 6, false),
            Arguments.of(17, 18, 1, false),
            Arguments.of(18, null, 0, true)
        );
    }

    private Stamp stamp(Long id, String cityName, String stampName, int displayOrder) {
        Stamp stamp = new Stamp(
            cityName,
            stampName,
            null,
            displayOrder,
            Instant.parse("2026-06-30T00:00:00Z")
        );
        ReflectionTestUtils.setField(stamp, "id", id);
        return stamp;
    }
}
