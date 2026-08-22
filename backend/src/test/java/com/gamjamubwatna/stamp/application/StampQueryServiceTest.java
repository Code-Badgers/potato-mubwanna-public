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
import com.gamjamubwatna.stamp.api.RallybookSpotResponse;
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
        List<Stamp> stamps = IntStream.rangeClosed(1, 29)
            .mapToObj(index -> stamp((long) index, "시군 " + index, "감자 " + index, index))
            .toList();
        Instant acquiredAt = Instant.parse("2026-06-30T00:00:00Z");
        UserStamp acquired = new UserStamp(
            null,
            stamps.getFirst(),
            stamps.getFirst().getTouristSpot(),
            acquiredAt
        );
        when(userRepository.existsById(1L)).thenReturn(true);
        when(stampRepository.findAllByOrderByDisplayOrderAsc()).thenReturn(stamps);
        when(userStampRepository.findByUserIdWithStamp(1L)).thenReturn(List.of(acquired));

        StampBookResponse result = stampQueryService.getStampBook(1L);

        assertThat(result.totalCount()).isEqualTo(29);
        assertThat(result.acquiredCount()).isEqualTo(1);
        assertThat(result.stamps()).hasSize(29);
        assertThat(result.stamps().getFirst().spotId())
            .isEqualTo(stamps.getFirst().getTouristSpot().getId());
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
    void returnsThreeOrderedUnacquiredPassportSpotsIncludingSameCity() {
        List<Stamp> stamps = List.of(
            stamp(1L, "시군 1", "가 관광지", 1),
            stamp(2L, "시군 2", "나 관광지", 2),
            stamp(3L, "시군 2", "다 관광지", 3),
            stamp(4L, "시군 4", "라 관광지", 4),
            stamp(5L, "시군 5", "마 관광지", 5)
        );
        UserStamp acquired = new UserStamp(
            null,
            stamps.getFirst(),
            stamps.getFirst().getTouristSpot(),
            Instant.now()
        );

        when(userRepository.existsById(1L)).thenReturn(true);
        when(userStampRepository.findByUserIdWithStamp(1L)).thenReturn(List.of(acquired));
        when(stampRepository.findAllByOrderByDisplayOrderAsc()).thenReturn(stamps);

        List<StampNextTargetResponse> result = stampQueryService.getNextTargets(1L);

        assertThat(result).hasSize(3);
        assertThat(result)
            .extracting(StampNextTargetResponse::spotName)
            .containsExactly("나 관광지", "다 관광지", "라 관광지");
        assertThat(result)
            .extracting(StampNextTargetResponse::cityName)
            .containsExactly("시군 2", "시군 2", "시군 4");
    }

    @Test
    void returnsEveryRallybookSpotInStampCityOrder() {
        TouristSpot gangneung = touristSpot(31L, "강릉시", "경포대");
        TouristSpot chuncheonLater = touristSpot(12L, "춘천시", "소양강 스카이워크");
        TouristSpot chuncheonFirst = touristSpot(11L, "춘천시", "남이섬");
        List<Stamp> stamps = List.of(
            stamp(1L, chuncheonFirst, 1),
            stamp(2L, chuncheonLater, 2),
            stamp(3L, gangneung, 3)
        );

        when(userRepository.existsById(1L)).thenReturn(true);
        when(stampRepository.findAllByOrderByDisplayOrderAsc()).thenReturn(stamps);
        when(touristSpotRepository.findActiveRallybookSpots()).thenReturn(List.of(
            gangneung,
            chuncheonLater,
            chuncheonFirst
        ));

        List<RallybookSpotResponse> result = stampQueryService.getRallybookSpots(1L);

        assertThat(result)
            .extracting(RallybookSpotResponse::spotName)
            .containsExactly("남이섬", "소양강 스카이워크", "경포대");
        assertThat(result)
            .allSatisfy(spot -> {
                assertThat(spot.latitude()).isEqualByComparingTo("37.0");
                assertThat(spot.longitude()).isEqualByComparingTo("128.0");
            });
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
        when(stampRepository.count()).thenReturn(29L);
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
        when(stampRepository.count()).thenReturn(29L);
        when(rewardHistoryRepository.findSourceIdsByUserIdAndSourceType(
            1L,
            RewardSourceType.STAMP
        )).thenReturn(List.of(6L, 12L));

        StampRewardStatusResponse result = stampQueryService.getRewardStatus(1L);

        assertThat(result.completed()).isFalse();
        assertThat(result.claimable()).isTrue();
        assertThat(result.claimableTargetCount()).isEqualTo(18);
    }

    @Test
    void keepsLowerTargetClaimableWhenHigherTargetWasClaimedFirst() {
        when(userRepository.existsById(1L)).thenReturn(true);
        when(userStampRepository.countByUserId(1L)).thenReturn(12);
        when(stampRepository.count()).thenReturn(29L);
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
        when(stampRepository.count()).thenReturn(29L);
        when(rewardHistoryRepository.findSourceIdsByUserIdAndSourceType(
            1L,
            RewardSourceType.STAMP
        )).thenReturn(List.of(6L, 12L, 18L));

        StampRewardStatusResponse result = stampQueryService.getRewardStatus(1L);

        assertThat(result.completed()).isFalse();
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
            Arguments.of(18, null, 11, false),
            Arguments.of(28, null, 1, false),
            Arguments.of(29, null, 0, true)
        );
    }

    private Stamp stamp(Long id, String cityName, String stampName, int displayOrder) {
        TouristSpot spot = touristSpot(1000L + id, cityName, stampName);
        return stamp(id, spot, displayOrder);
    }

    private Stamp stamp(Long id, TouristSpot spot, int displayOrder) {
        Stamp stamp = new Stamp(
            "PASSPORT_SPOT_" + spot.getContentId(),
            spot,
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
