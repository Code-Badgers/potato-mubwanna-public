package com.gamjamubwatna.user.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.potato.domain.UserDailyActivityRepository;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import com.gamjamubwatna.user.api.UserActivitySummaryResponse;
import org.junit.jupiter.api.Test;

class UserActivitySummaryServiceTest {

    @Test
    void returnsAggregatedActivitySummary() {
        Dependencies dependencies = dependencies();
        when(dependencies.userRepository.existsById(1L)).thenReturn(true);
        when(dependencies.userDailyActivityRepository.sumStepsByUserId(1L)).thenReturn(256_842L);
        when(dependencies.userStampRepository.countByUserId(1L)).thenReturn(12);
        when(dependencies.userPotatoRepository.countByUserId(1L)).thenReturn(7L);

        UserActivitySummaryResponse summary = service(dependencies).getActivitySummary(1L);

        assertThat(summary.totalSteps()).isEqualTo(256_842L);
        assertThat(summary.stampCount()).isEqualTo(12);
        assertThat(summary.ownedPotatoCount()).isEqualTo(7L);
    }

    @Test
    void returnsZeroesWhenTheUserHasNoActivity() {
        Dependencies dependencies = dependencies();
        when(dependencies.userRepository.existsById(1L)).thenReturn(true);

        UserActivitySummaryResponse summary = service(dependencies).getActivitySummary(1L);

        assertThat(summary.totalSteps()).isZero();
        assertThat(summary.stampCount()).isZero();
        assertThat(summary.ownedPotatoCount()).isZero();
    }

    @Test
    void rejectsUnknownUserId() {
        Dependencies dependencies = dependencies();
        when(dependencies.userRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> service(dependencies).getActivitySummary(99L))
            .isInstanceOf(UserProfileAuthenticationException.class);
    }

    private UserActivitySummaryService service(Dependencies dependencies) {
        return new UserActivitySummaryService(
            dependencies.userRepository,
            dependencies.userDailyActivityRepository,
            dependencies.userStampRepository,
            dependencies.userPotatoRepository
        );
    }

    private Dependencies dependencies() {
        return new Dependencies(
            mock(UserRepository.class),
            mock(UserDailyActivityRepository.class),
            mock(UserStampRepository.class),
            mock(UserPotatoRepository.class)
        );
    }

    private record Dependencies(
        UserRepository userRepository,
        UserDailyActivityRepository userDailyActivityRepository,
        UserStampRepository userStampRepository,
        UserPotatoRepository userPotatoRepository
    ) {
    }
}
