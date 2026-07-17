package com.gamjamubwatna.stamp.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.coupon.domain.Coupon;
import com.gamjamubwatna.coupon.domain.CouponRepository;
import com.gamjamubwatna.coupon.domain.UserCoupon;
import com.gamjamubwatna.coupon.domain.UserCouponRepository;
import com.gamjamubwatna.coupon.domain.UserCouponStatus;
import com.gamjamubwatna.mission.domain.MissionRewardType;
import com.gamjamubwatna.reward.domain.RewardHistory;
import com.gamjamubwatna.reward.domain.RewardHistoryRepository;
import com.gamjamubwatna.reward.domain.RewardSourceType;
import com.gamjamubwatna.stamp.api.StampRewardClaimResponse;
import com.gamjamubwatna.stamp.domain.StampRewardPolicy;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import org.hibernate.exception.ConstraintViolationException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class StampRewardService {

    private static final String REWARD_HISTORY_UNIQUE_CONSTRAINT =
        "uk_reward_histories_user_source";

    private final UserRepository userRepository;
    private final UserStampRepository userStampRepository;
    private final RewardHistoryRepository rewardHistoryRepository;
    private final CouponRepository couponRepository;
    private final UserCouponRepository userCouponRepository;
    private final Clock clock;

    @Autowired
    public StampRewardService(
        UserRepository userRepository,
        UserStampRepository userStampRepository,
        RewardHistoryRepository rewardHistoryRepository,
        CouponRepository couponRepository,
        UserCouponRepository userCouponRepository
    ) {
        this(
            userRepository,
            userStampRepository,
            rewardHistoryRepository,
            couponRepository,
            userCouponRepository,
            Clock.systemUTC()
        );
    }

    StampRewardService(
        UserRepository userRepository,
        UserStampRepository userStampRepository,
        RewardHistoryRepository rewardHistoryRepository,
        CouponRepository couponRepository,
        UserCouponRepository userCouponRepository,
        Clock clock
    ) {
        this.userRepository = userRepository;
        this.userStampRepository = userStampRepository;
        this.rewardHistoryRepository = rewardHistoryRepository;
        this.couponRepository = couponRepository;
        this.userCouponRepository = userCouponRepository;
        this.clock = clock;
    }

    @Transactional
    public StampRewardClaimResponse claimReward(Long userId, Integer targetCount) {
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new StampAuthenticationException("사용자를 찾을 수 없습니다."));
        StampRewardPolicy policy = StampRewardPolicy.findByTargetCount(targetCount)
            .orElseThrow(() -> new StampRewardInvalidTargetException(
                "지원하지 않는 스탬프 보상 기준입니다."
            ));

        if (userStampRepository.countByUserId(userId) < policy.targetCount()) {
            throw new StampRewardConflictException("보상 수령에 필요한 스탬프가 부족합니다.");
        }
        if (rewardHistoryRepository.existsByUserIdAndSourceTypeAndSourceId(
            userId,
            RewardSourceType.STAMP,
            (long) policy.targetCount()
        )) {
            throw new StampRewardConflictException("이미 수령한 스탬프 보상입니다.");
        }

        Coupon coupon = couponRepository.findByCode(policy.couponCode())
            .orElseThrow(() -> new StampRewardConfigurationException(
                "스탬프 보상 쿠폰 정보를 찾을 수 없습니다."
            ));
        Instant issuedAt = Instant.now(clock);
        RewardHistory rewardHistory = saveRewardHistory(user, policy, coupon, issuedAt);
        UserCoupon userCoupon = userCouponRepository.saveAndFlush(new UserCoupon(
            user,
            coupon,
            UserCouponStatus.AVAILABLE,
            issuedAt,
            issuedAt.plus(Duration.ofDays(coupon.getValidDays())),
            null
        ));

        return new StampRewardClaimResponse(
            policy.targetCount(),
            rewardHistory.getId(),
            userCoupon.getId(),
            coupon.getName(),
            userCoupon.getExpiresAt()
        );
    }

    private RewardHistory saveRewardHistory(
        User user,
        StampRewardPolicy policy,
        Coupon coupon,
        Instant issuedAt
    ) {
        try {
            // 유일 제약을 쿠폰 발급 전에 즉시 확인해야 동시 요청의 패자에게 쿠폰이 남지 않는다.
            return rewardHistoryRepository.saveAndFlush(new RewardHistory(
                user,
                MissionRewardType.COUPON,
                coupon.getName(),
                RewardSourceType.STAMP,
                (long) policy.targetCount(),
                issuedAt
            ));
        } catch (DataIntegrityViolationException exception) {
            if (!isRewardHistoryDuplicate(exception)) {
                throw exception;
            }
            throw new StampRewardConflictException("이미 수령한 스탬프 보상입니다.");
        }
    }

    private boolean isRewardHistoryDuplicate(DataIntegrityViolationException exception) {
        Throwable cause = exception;
        while (cause != null) {
            if (cause instanceof ConstraintViolationException constraintViolation) {
                return matchesRewardHistoryUniqueConstraint(
                    constraintViolation.getConstraintName()
                );
            }
            cause = cause.getCause();
        }
        return false;
    }

    private boolean matchesRewardHistoryUniqueConstraint(String constraintName) {
        if (constraintName == null) {
            return false;
        }
        // Hibernate가 PostgreSQL/H2별 메시지 대신 제공하는 구조화된 제약 이름만 비교한다.
        String normalizedName = constraintName
            .replace("\"", "")
            .toLowerCase(Locale.ROOT);
        String simpleName = normalizedName.substring(normalizedName.lastIndexOf('.') + 1);
        return simpleName.equals(REWARD_HISTORY_UNIQUE_CONSTRAINT)
            || simpleName.startsWith(REWARD_HISTORY_UNIQUE_CONSTRAINT + "_index_");
    }
}
