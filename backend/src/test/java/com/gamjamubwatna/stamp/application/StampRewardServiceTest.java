package com.gamjamubwatna.stamp.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.coupon.domain.Coupon;
import com.gamjamubwatna.coupon.domain.CouponRepository;
import com.gamjamubwatna.coupon.domain.UserCoupon;
import com.gamjamubwatna.coupon.domain.UserCouponRepository;
import com.gamjamubwatna.mission.domain.MissionRewardType;
import com.gamjamubwatna.reward.domain.RewardHistory;
import com.gamjamubwatna.reward.domain.RewardHistoryRepository;
import com.gamjamubwatna.reward.domain.RewardSourceType;
import com.gamjamubwatna.stamp.api.StampRewardClaimResponse;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.hibernate.exception.ConstraintViolationException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class StampRewardServiceTest {

    private static final Instant NOW = Instant.parse("2026-07-17T00:00:00Z");

    @Mock
    private UserRepository userRepository;

    @Mock
    private UserStampRepository userStampRepository;

    @Mock
    private RewardHistoryRepository rewardHistoryRepository;

    @Mock
    private CouponRepository couponRepository;

    @Mock
    private UserCouponRepository userCouponRepository;

    private StampRewardService stampRewardService;

    @BeforeEach
    void setUp() {
        stampRewardService = new StampRewardService(
            userRepository,
            userStampRepository,
            rewardHistoryRepository,
            couponRepository,
            userCouponRepository,
            Clock.fixed(NOW, ZoneOffset.UTC)
        );
    }

    @Test
    void claimsRewardAndIssuesCouponInOneFlow() {
        User user = user(1L);
        Coupon coupon = coupon();
        givenClaimableReward(user, coupon);
        when(rewardHistoryRepository.saveAndFlush(any(RewardHistory.class)))
            .thenAnswer(invocation -> withId(invocation.getArgument(0), "id", 10L));
        when(userCouponRepository.saveAndFlush(any(UserCoupon.class)))
            .thenAnswer(invocation -> withId(invocation.getArgument(0), "id", 21L));

        StampRewardClaimResponse result = stampRewardService.claimReward(1L, 6);

        assertThat(result.targetCount()).isEqualTo(6);
        assertThat(result.rewardHistoryId()).isEqualTo(10L);
        assertThat(result.userCouponId()).isEqualTo(21L);
        assertThat(result.couponName()).isEqualTo("강원 감자 제휴점 3,000원 할인권");
        assertThat(result.expiresAt()).isEqualTo(Instant.parse("2026-08-16T00:00:00Z"));

        ArgumentCaptor<RewardHistory> historyCaptor = ArgumentCaptor.forClass(RewardHistory.class);
        verify(rewardHistoryRepository).saveAndFlush(historyCaptor.capture());
        assertThat(historyCaptor.getValue().getRewardType()).isEqualTo(MissionRewardType.COUPON);
        assertThat(historyCaptor.getValue().getSourceType()).isEqualTo(RewardSourceType.STAMP);
        assertThat(historyCaptor.getValue().getSourceId()).isEqualTo(6L);

        ArgumentCaptor<UserCoupon> couponCaptor = ArgumentCaptor.forClass(UserCoupon.class);
        verify(userCouponRepository).saveAndFlush(couponCaptor.capture());
        assertThat(couponCaptor.getValue().getCoupon()).isSameAs(coupon);
        assertThat(couponCaptor.getValue().getIssuedAt()).isEqualTo(NOW);
        assertThat(couponCaptor.getValue().getExpiresAt())
            .isEqualTo(Instant.parse("2026-08-16T00:00:00Z"));
    }

    @Test
    void allowsClaimingHigherAchievedTargetBeforeLowerTarget() {
        User user = user(1L);
        Coupon coupon = new Coupon(
            "CP_STAMP_12_LOCAL_5000",
            "강원 감자 제휴점 5,000원 할인권",
            "강원 감자 제휴점에서 5,000원 할인받을 수 있습니다.",
            5000,
            "강원 감자 제휴점",
            30
        );
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(userStampRepository.countByUserId(1L)).thenReturn(12);
        when(couponRepository.findByCode("CP_STAMP_12_LOCAL_5000"))
            .thenReturn(Optional.of(coupon));
        when(rewardHistoryRepository.saveAndFlush(any(RewardHistory.class)))
            .thenAnswer(invocation -> withId(invocation.getArgument(0), "id", 12L));
        when(userCouponRepository.saveAndFlush(any(UserCoupon.class)))
            .thenAnswer(invocation -> withId(invocation.getArgument(0), "id", 22L));

        StampRewardClaimResponse result = stampRewardService.claimReward(1L, 12);

        assertThat(result.targetCount()).isEqualTo(12);
        ArgumentCaptor<RewardHistory> historyCaptor = ArgumentCaptor.forClass(RewardHistory.class);
        verify(rewardHistoryRepository).saveAndFlush(historyCaptor.capture());
        assertThat(historyCaptor.getValue().getSourceId()).isEqualTo(12L);
    }

    @Test
    void rejectsUnsupportedTarget() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));

        assertThatThrownBy(() -> stampRewardService.claimReward(1L, 7))
            .isInstanceOf(StampRewardInvalidTargetException.class);

        verifyNoInteractions(userStampRepository, rewardHistoryRepository, couponRepository);
    }

    @Test
    void rejectsInsufficientStamps() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(userStampRepository.countByUserId(1L)).thenReturn(5);

        assertThatThrownBy(() -> stampRewardService.claimReward(1L, 6))
            .isInstanceOf(StampRewardConflictException.class)
            .hasMessage("보상 수령에 필요한 스탬프가 부족합니다.");

        verifyNoInteractions(couponRepository, userCouponRepository);
    }

    @Test
    void rejectsAlreadyClaimedReward() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(userStampRepository.countByUserId(1L)).thenReturn(6);
        when(rewardHistoryRepository.existsByUserIdAndSourceTypeAndSourceId(
            1L,
            RewardSourceType.STAMP,
            6L
        )).thenReturn(true);

        assertThatThrownBy(() -> stampRewardService.claimReward(1L, 6))
            .isInstanceOf(StampRewardConflictException.class)
            .hasMessage("이미 수령한 스탬프 보상입니다.");

        verifyNoInteractions(couponRepository, userCouponRepository);
    }

    @ParameterizedTest
    @ValueSource(strings = {
        "uk_reward_histories_user_source",
        "\"PUBLIC\".\"UK_REWARD_HISTORIES_USER_SOURCE_INDEX_E\""
    })
    void mapsUniqueConstraintRaceBeforeIssuingCoupon(String constraintName) {
        givenClaimableReward(user(1L), coupon());
        DataIntegrityViolationException duplicate = dataIntegrityViolation(constraintName);
        when(rewardHistoryRepository.saveAndFlush(any(RewardHistory.class)))
            .thenThrow(duplicate);

        assertThatThrownBy(() -> stampRewardService.claimReward(1L, 6))
            .isInstanceOf(StampRewardConflictException.class)
            .hasMessage("이미 수령한 스탬프 보상입니다.");

        verify(userCouponRepository, never()).saveAndFlush(any(UserCoupon.class));
    }

    @Test
    void rethrowsIntegrityViolationFromDifferentConstraint() {
        givenClaimableReward(user(1L), coupon());
        DataIntegrityViolationException failure = dataIntegrityViolation(
            "uk_reward_histories_different_constraint"
        );
        when(rewardHistoryRepository.saveAndFlush(any(RewardHistory.class)))
            .thenThrow(failure);

        assertThatThrownBy(() -> stampRewardService.claimReward(1L, 6))
            .isSameAs(failure);

        verify(userCouponRepository, never()).saveAndFlush(any(UserCoupon.class));
    }

    @Test
    void claimsEighteenStampCompletionReward() {
        User user = user(1L);
        Coupon coupon = new Coupon(
            "CP_STAMP_18_COMPLETE_10000",
            "강원 감자 랠리 완주 10,000원 할인권",
            "강원 감자 랠리 완주 기념으로 제휴점에서 10,000원 할인받을 수 있습니다.",
            10000,
            "강원 감자 제휴점",
            30
        );
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(userStampRepository.countByUserId(1L)).thenReturn(18);
        when(couponRepository.findByCode("CP_STAMP_18_COMPLETE_10000"))
            .thenReturn(Optional.of(coupon));
        when(rewardHistoryRepository.saveAndFlush(any(RewardHistory.class)))
            .thenAnswer(invocation -> withId(invocation.getArgument(0), "id", 18L));
        when(userCouponRepository.saveAndFlush(any(UserCoupon.class)))
            .thenAnswer(invocation -> withId(invocation.getArgument(0), "id", 28L));

        StampRewardClaimResponse result = stampRewardService.claimReward(1L, 18);

        assertThat(result.targetCount()).isEqualTo(18);
        assertThat(result.couponName()).isEqualTo("강원 감자 랠리 완주 10,000원 할인권");
        ArgumentCaptor<RewardHistory> historyCaptor = ArgumentCaptor.forClass(RewardHistory.class);
        verify(rewardHistoryRepository).saveAndFlush(historyCaptor.capture());
        assertThat(historyCaptor.getValue().getSourceId()).isEqualTo(18L);
    }

    @Test
    void failsWhenPolicyCouponIsMissing() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(userStampRepository.countByUserId(1L)).thenReturn(6);
        when(couponRepository.findByCode("CP_STAMP_6_LOCAL_3000"))
            .thenReturn(Optional.empty());

        assertThatThrownBy(() -> stampRewardService.claimReward(1L, 6))
            .isInstanceOf(StampRewardConfigurationException.class)
            .hasMessage("스탬프 보상 쿠폰 정보를 찾을 수 없습니다.");

        verify(rewardHistoryRepository, never()).saveAndFlush(any(RewardHistory.class));
        verifyNoInteractions(userCouponRepository);
    }

    private void givenClaimableReward(User user, Coupon coupon) {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(userStampRepository.countByUserId(1L)).thenReturn(6);
        when(couponRepository.findByCode("CP_STAMP_6_LOCAL_3000"))
            .thenReturn(Optional.of(coupon));
    }

    private User user(Long id) {
        User user = new User(
            AuthProvider.KAKAO,
            "stamp-reward-" + id,
            null,
            "스탬프 사용자",
            null,
            NOW
        );
        ReflectionTestUtils.setField(user, "id", id);
        return user;
    }

    private Coupon coupon() {
        return new Coupon(
            "CP_STAMP_6_LOCAL_3000",
            "강원 감자 제휴점 3,000원 할인권",
            "강원 감자 제휴점에서 3,000원 할인받을 수 있습니다.",
            3000,
            "강원 감자 제휴점",
            30
        );
    }

    private <T> T withId(T entity, String fieldName, Long id) {
        ReflectionTestUtils.setField(entity, fieldName, id);
        return entity;
    }

    private DataIntegrityViolationException dataIntegrityViolation(String constraintName) {
        ConstraintViolationException constraintViolation = mock(
            ConstraintViolationException.class
        );
        when(constraintViolation.getConstraintName()).thenReturn(constraintName);
        return new DataIntegrityViolationException("insert failed", constraintViolation);
    }
}
