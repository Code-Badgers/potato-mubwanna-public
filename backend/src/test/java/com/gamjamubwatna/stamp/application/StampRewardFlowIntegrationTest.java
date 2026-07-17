package com.gamjamubwatna.stamp.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.coupon.domain.UserCoupon;
import com.gamjamubwatna.coupon.domain.UserCouponRepository;
import com.gamjamubwatna.reward.domain.RewardHistory;
import com.gamjamubwatna.reward.domain.RewardHistoryRepository;
import com.gamjamubwatna.reward.domain.RewardSourceType;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.stamp.api.StampRewardStatusResponse;
import com.gamjamubwatna.stamp.domain.Stamp;
import com.gamjamubwatna.stamp.domain.StampRepository;
import com.gamjamubwatna.stamp.domain.UserStamp;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:stamp_reward_flow;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough"
})
class StampRewardFlowIntegrationTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private StampRepository stampRepository;

    @Autowired
    private UserStampRepository userStampRepository;

    @Autowired
    private TouristSpotRepository touristSpotRepository;

    @MockitoSpyBean
    private RewardHistoryRepository rewardHistoryRepository;

    @MockitoSpyBean
    private UserCouponRepository userCouponRepository;

    @Autowired
    private StampRewardService stampRewardService;

    @Autowired
    private StampQueryService stampQueryService;

    @Test
    void claimsMultipleAchievedRewardsInOrderAndIssuesCoupons() {
        User user = saveUserWithStamps("multi-stage", 12);

        stampRewardService.claimReward(user.getId(), 6);
        StampRewardStatusResponse afterFirstClaim = stampQueryService.getRewardStatus(user.getId());

        assertThat(afterFirstClaim.claimable()).isTrue();
        assertThat(afterFirstClaim.claimableTargetCount()).isEqualTo(12);

        stampRewardService.claimReward(user.getId(), 12);

        List<RewardHistory> histories = rewardHistoryRepository
            .findByUserIdOrderByCreatedAtDesc(user.getId());
        List<UserCoupon> coupons = userCouponRepository
            .findByUserIdOrderByIssuedAtDesc(user.getId());
        assertThat(histories)
            .hasSize(2)
            .allSatisfy(history -> assertThat(history.getSourceType())
                .isEqualTo(RewardSourceType.STAMP));
        assertThat(histories).extracting(RewardHistory::getSourceId)
            .containsExactlyInAnyOrder(6L, 12L);
        assertThat(coupons).extracting(userCoupon -> userCoupon.getCoupon().getCode())
            .containsExactlyInAnyOrder(
                "CP_STAMP_6_LOCAL_3000",
                "CP_STAMP_12_LOCAL_5000"
            );

        StampRewardStatusResponse afterAllClaims = stampQueryService.getRewardStatus(user.getId());
        assertThat(afterAllClaims.claimable()).isFalse();
        assertThat(afterAllClaims.claimableTargetCount()).isNull();
        assertThatThrownBy(() -> stampRewardService.claimReward(user.getId(), 6))
            .isInstanceOf(StampRewardConflictException.class);
        assertThat(rewardHistoryRepository.findByUserIdOrderByCreatedAtDesc(user.getId()))
            .hasSize(2);
        assertThat(userCouponRepository.findByUserIdOrderByIssuedAtDesc(user.getId()))
            .hasSize(2);
    }

    @Test
    void concurrentDuplicateClaimsIssueOnlyOneCoupon() throws Exception {
        User user = saveUserWithStamps("concurrent", 6);
        CountDownLatch ready = new CountDownLatch(2);
        CountDownLatch start = new CountDownLatch(1);
        Callable<String> claim = () -> {
            ready.countDown();
            start.await();
            try {
                stampRewardService.claimReward(user.getId(), 6);
                return "claimed";
            } catch (StampRewardConflictException exception) {
                return "conflict";
            }
        };

        try (ExecutorService executor = Executors.newFixedThreadPool(2)) {
            Future<String> first = executor.submit(claim);
            Future<String> second = executor.submit(claim);
            assertThat(ready.await(5, TimeUnit.SECONDS)).isTrue();
            start.countDown();

            assertThat(List.of(
                first.get(10, TimeUnit.SECONDS),
                second.get(10, TimeUnit.SECONDS)
            )).containsExactlyInAnyOrder("claimed", "conflict");
        }

        assertThat(rewardHistoryRepository.findByUserIdOrderByCreatedAtDesc(user.getId()))
            .hasSize(1);
        assertThat(userCouponRepository.findByUserIdOrderByIssuedAtDesc(user.getId()))
            .hasSize(1);
    }

    @Test
    void rollsBackFlushedRewardHistoryWhenCouponIssuanceFails() {
        User user = saveUserWithStamps("coupon-failure", 6);
        DataIntegrityViolationException couponFailure = new DataIntegrityViolationException(
            "user coupon insert failed"
        );
        doThrow(couponFailure)
            .when(userCouponRepository)
            .saveAndFlush(any(UserCoupon.class));

        assertThatThrownBy(() -> stampRewardService.claimReward(user.getId(), 6))
            .isSameAs(couponFailure);

        verify(rewardHistoryRepository).saveAndFlush(any(RewardHistory.class));
        assertThat(rewardHistoryRepository.findByUserIdOrderByCreatedAtDesc(user.getId()))
            .isEmpty();
        assertThat(userCouponRepository.findByUserIdOrderByIssuedAtDesc(user.getId()))
            .isEmpty();
    }

    private User saveUserWithStamps(String suffix, int count) {
        Instant now = Instant.parse("2026-07-17T00:00:00Z");
        User user = userRepository.save(new User(
            AuthProvider.KAKAO,
            "stamp-flow-" + suffix,
            null,
            "스탬프 통합 사용자",
            null,
            now
        ));
        TouristSpot touristSpot = touristSpotRepository.save(new TouristSpot(
            "stamp-flow-spot-" + suffix,
            12,
            "스탬프 통합 관광지",
            SpotCategory.POTATO_RESTAURANT,
            new BigDecimal("37.3801000"),
            new BigDecimal("128.6609000"),
            "강원특별자치도 정선군",
            "정선군",
            null,
            "감자",
            now
        ));
        List<Stamp> stamps = stampRepository.findAllByOrderByDisplayOrderAsc()
            .stream()
            .limit(count)
            .toList();
        userStampRepository.saveAll(stamps.stream()
            .map(stamp -> new UserStamp(user, stamp, touristSpot, now))
            .toList());
        return user;
    }
}
