package com.gamjamubwatna.stamp.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.reward.domain.RewardHistoryRepository;
import com.gamjamubwatna.reward.domain.RewardSourceType;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.stamp.api.StampBookResponse;
import com.gamjamubwatna.stamp.api.StampNextTargetResponse;
import com.gamjamubwatna.stamp.api.StampRewardStatusResponse;
import com.gamjamubwatna.stamp.domain.Stamp;
import com.gamjamubwatna.stamp.domain.StampRepository;
import com.gamjamubwatna.stamp.domain.UserStamp;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import java.math.BigDecimal;
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

    @Mock
    private RewardHistoryRepository rewardHistoryRepository;

    @Mock
    private TouristSpotRepository touristSpotRepository;

    private StampQueryService stampQueryService;

    @BeforeEach
    void setUp() {
        stampQueryService = new StampQueryService(
            stampRepository,
            userStampRepository,
            userRepository,
            rewardHistoryRepository,
            touristSpotRepository
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

    @Test
    void returnsThreeOrderedTargetsFromUnacquiredCities() {
        List<Stamp> stamps = IntStream.rangeClosed(1, 5)
            .mapToObj(index -> stamp((long) index, "시군 " + index, "감자 " + index, index))
            .toList();
        UserStamp acquired = new UserStamp(null, stamps.getFirst(), null, Instant.now());
        TouristSpot cityTwoLater = touristSpot(22L, "시군 2", "나 관광지");
        TouristSpot cityTwoFirst = touristSpot(21L, "시군 2", "가 관광지");
        TouristSpot cityFour = touristSpot(41L, "시군 4", "라 관광지");
        TouristSpot cityFive = touristSpot(51L, "시군 5", "마 관광지");

        when(userRepository.existsById(1L)).thenReturn(true);
        when(userStampRepository.findByUserIdWithStamp(1L)).thenReturn(List.of(acquired));
        when(stampRepository.findAllByOrderByDisplayOrderAsc()).thenReturn(stamps);
        when(touristSpotRepository.findActiveStampSpots()).thenReturn(List.of(
            cityTwoFirst,
            cityTwoLater,
            cityFour,
            cityFive
        ));

        List<StampNextTargetResponse> result = stampQueryService.getNextTargets(1L);

        assertThat(result).hasSize(3);
        assertThat(result)
            .extracting(StampNextTargetResponse::cityName)
            .containsExactly("시군 2", "시군 4", "시군 5");
        assertThat(result.getFirst().spotName()).isEqualTo("가 관광지");
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
        when(rewardHistoryRepository.findSourceIdsByUserIdAndSourceType(
            1L,
            RewardSourceType.STAMP
        )).thenReturn(List.of());

        StampRewardStatusResponse result = stampQueryService.getRewardStatus(1L);

        assertThat(result.acquiredCount()).isEqualTo(acquiredCount);
        assertThat(result.nextTargetCount()).isEqualTo(nextTargetCount);
        assertThat(result.remainingCount()).isEqualTo(remainingCount);
        assertThat(result.completed()).isEqualTo(completed);
        assertThat(result.claimable()).isEqualTo(acquiredCount >= 6);
        assertThat(result.claimableTargetCount()).isEqualTo(acquiredCount >= 6 ? 6 : null);
    }

    @Test
    void returnsLowestAchievedUnclaimedRewardTarget() {
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userStampRepository.countByUserId(1L)).thenReturn(18);
        when(rewardHistoryRepository.findSourceIdsByUserIdAndSourceType(
            1L,
            RewardSourceType.STAMP
        )).thenReturn(List.of(6L, 12L));

        StampRewardStatusResponse result = stampQueryService.getRewardStatus(1L);

        assertThat(result.completed()).isTrue();
        assertThat(result.claimable()).isTrue();
        assertThat(result.claimableTargetCount()).isEqualTo(18);
    }

    @Test
    void keepsLowerTargetClaimableWhenHigherTargetWasClaimedFirst() {
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userStampRepository.countByUserId(1L)).thenReturn(12);
        when(rewardHistoryRepository.findSourceIdsByUserIdAndSourceType(
            1L,
            RewardSourceType.STAMP
        )).thenReturn(List.of(12L));

        StampRewardStatusResponse result = stampQueryService.getRewardStatus(1L);

        assertThat(result.claimable()).isTrue();
        assertThat(result.claimableTargetCount()).isEqualTo(6);
    }

    @Test
    void returnsNoClaimableTargetAfterAllRewardsWereClaimed() {
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userStampRepository.countByUserId(1L)).thenReturn(18);
        when(rewardHistoryRepository.findSourceIdsByUserIdAndSourceType(
            1L,
            RewardSourceType.STAMP
        )).thenReturn(List.of(6L, 12L, 18L));

        StampRewardStatusResponse result = stampQueryService.getRewardStatus(1L);

        assertThat(result.completed()).isTrue();
        assertThat(result.claimable()).isFalse();
        assertThat(result.claimableTargetCount()).isNull();
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

    private TouristSpot touristSpot(Long id, String cityName, String name) {
        TouristSpot spot = new TouristSpot(
            "content-" + id,
            12,
            name,
            SpotCategory.POTATO_TOUR,
            BigDecimal.valueOf(37.0),
            BigDecimal.valueOf(128.0),
            cityName + " 주소",
            cityName,
            "https://example.com/" + id + ".jpg",
            null,
            Instant.parse("2026-06-30T00:00:00Z")
        );
        ReflectionTestUtils.setField(spot, "id", id);
        return spot;
    }
}
