package com.gamjamubwatna.reward.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.mission.domain.MissionRewardType;
import com.gamjamubwatna.reward.api.RewardHistoryListResponse;
import com.gamjamubwatna.reward.domain.RewardHistory;
import com.gamjamubwatna.reward.domain.RewardHistoryRepository;
import com.gamjamubwatna.reward.domain.RewardSourceType;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class RewardHistoryServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private RewardHistoryRepository rewardHistoryRepository;

    private RewardHistoryService rewardHistoryService;

    @BeforeEach
    void setUp() {
        rewardHistoryService = new RewardHistoryService(userRepository, rewardHistoryRepository);
    }

    @Test
    void returnsAuthenticatedUsersRewardHistoryInRepositoryOrder() {
        RewardHistory latest = rewardHistory(
            2L,
            MissionRewardType.COUPON,
            "강원상품권 5,000원",
            1002L,
            Instant.parse("2026-07-11T10:00:00Z")
        );
        RewardHistory older = rewardHistory(
            1L,
            MissionRewardType.POTATO,
            "수미감자 씨앗",
            1001L,
            Instant.parse("2026-07-11T09:00:00Z")
        );
        when(userRepository.existsById(1L)).thenReturn(true);
        when(rewardHistoryRepository.findByUserIdOrderByCreatedAtDesc(1L))
            .thenReturn(List.of(latest, older));

        RewardHistoryListResponse result = rewardHistoryService.getRewardHistory(1L);

        assertThat(result.rewards()).hasSize(2);
        assertThat(result.rewards().getFirst().rewardHistoryId()).isEqualTo(2L);
        assertThat(result.rewards().getFirst().rewardType()).isEqualTo(MissionRewardType.COUPON);
        assertThat(result.rewards().getFirst().rewardName()).isEqualTo("강원상품권 5,000원");
        assertThat(result.rewards().getFirst().sourceType()).isEqualTo(RewardSourceType.MISSION);
        assertThat(result.rewards().getFirst().sourceId()).isEqualTo(1002L);
        assertThat(result.rewards().getFirst().createdAt())
            .isEqualTo(Instant.parse("2026-07-11T10:00:00Z"));
    }

    @Test
    void returnsEmptyHistoryForUserWithoutRewards() {
        when(userRepository.existsById(1L)).thenReturn(true);
        when(rewardHistoryRepository.findByUserIdOrderByCreatedAtDesc(1L))
            .thenReturn(List.of());

        RewardHistoryListResponse result = rewardHistoryService.getRewardHistory(1L);

        assertThat(result.rewards()).isEmpty();
    }

    @Test
    void rejectsJwtSubjectForDeletedUser() {
        when(userRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> rewardHistoryService.getRewardHistory(99L))
            .isInstanceOf(RewardAuthenticationException.class);
    }

    private RewardHistory rewardHistory(
        Long id,
        MissionRewardType rewardType,
        String rewardName,
        Long sourceId,
        Instant createdAt
    ) {
        RewardHistory rewardHistory = new RewardHistory(
            org.mockito.Mockito.mock(User.class),
            rewardType,
            rewardName,
            RewardSourceType.MISSION,
            sourceId,
            createdAt
        );
        ReflectionTestUtils.setField(rewardHistory, "id", id);
        return rewardHistory;
    }
}
