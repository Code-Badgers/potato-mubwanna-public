package com.gamjamubwatna.reward.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.coupon.api.CouponDetailResponse;
import com.gamjamubwatna.coupon.api.CouponQrResponse;
import com.gamjamubwatna.coupon.application.CouponCommandService;
import com.gamjamubwatna.coupon.domain.CouponDisplayStatus;
import com.gamjamubwatna.coupon.domain.UserCoupon;
import com.gamjamubwatna.coupon.domain.UserCouponRepository;
import com.gamjamubwatna.mission.application.MissionAlreadyCompletedException;
import com.gamjamubwatna.mission.application.MissionService;
import com.gamjamubwatna.mission.domain.Mission;
import com.gamjamubwatna.mission.domain.MissionRepository;
import com.gamjamubwatna.reward.domain.RewardHistory;
import com.gamjamubwatna.reward.domain.RewardHistoryRepository;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest(properties = {
    "spring.datasource.url=jdbc:h2:mem:reward_coupon_flow;MODE=PostgreSQL;DATABASE_TO_LOWER=TRUE;DEFAULT_NULL_ORDERING=HIGH",
    "spring.datasource.driver-class-name=org.h2.Driver",
    "spring.datasource.username=sa",
    "spring.datasource.password=",
    "spring.jpa.hibernate.ddl-auto=validate",
    "auth.jwt.secret=test-jwt-secret-must-be-long-enough",
    "coupon.qr.secret=test-coupon-qr-secret-must-be-long-enough"
})
class RewardCouponFlowIntegrationTest {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private MissionRepository missionRepository;

    @Autowired
    private RewardHistoryRepository rewardHistoryRepository;

    @Autowired
    private UserCouponRepository userCouponRepository;

    @Autowired
    private MissionService missionService;

    @Autowired
    private CouponCommandService couponCommandService;

    @Test
    void completesMissionAndUsesIssuedCouponOnlyOnce() {
        User user = userRepository.save(new User(
            AuthProvider.KAKAO,
            "reward-flow-user",
            null,
            "보상 검증 사용자",
            null,
            Instant.parse("2026-07-01T00:00:00Z")
        ));
        Mission mission = missionRepository.findAllByOrderByDisplayOrderAsc().stream()
            .filter(candidate -> candidate.getCode().equals("MISSION_EVENT_HWACHEON"))
            .findFirst()
            .orElseThrow();

        missionService.completeMission(user.getId(), mission.getId());

        List<RewardHistory> rewardHistories = rewardHistoryRepository
            .findByUserIdOrderByCreatedAtDesc(user.getId());
        List<UserCoupon> issuedCoupons = userCouponRepository
            .findByUserIdOrderByIssuedAtDesc(user.getId());
        assertThat(rewardHistories).hasSize(1);
        assertThat(issuedCoupons).hasSize(1);
        UserCoupon issuedCoupon = issuedCoupons.getFirst();
        assertThat(issuedCoupon.getCoupon().getCode()).isEqualTo("CP_HWACHEON_LOCAL");
        assertThat(issuedCoupon.getExpiresAt()).isAfter(issuedCoupon.getIssuedAt());

        CouponQrResponse qr = couponCommandService.getQr(user.getId(), issuedCoupon.getId());
        CouponDetailResponse used = couponCommandService.useCoupon(
            user.getId(),
            issuedCoupon.getId(),
            qr.payload()
        );

        assertThat(used.status()).isEqualTo(CouponDisplayStatus.USED);
        assertThat(used.usedAt()).isNotNull();
        assertThatThrownBy(() -> missionService.completeMission(user.getId(), mission.getId()))
            .isInstanceOf(MissionAlreadyCompletedException.class);
        assertThat(rewardHistoryRepository.findByUserIdOrderByCreatedAtDesc(user.getId()))
            .hasSize(1);
        assertThat(userCouponRepository.findByUserIdOrderByIssuedAtDesc(user.getId()))
            .hasSize(1);
    }
}
