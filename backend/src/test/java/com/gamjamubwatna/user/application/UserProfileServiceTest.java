package com.gamjamubwatna.user.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.user.api.UserProfileResponse;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

class UserProfileServiceTest {

    @Test
    void returnsProfileForAuthenticatedUserId() {
        Instant createdAt = Instant.parse("2026-06-23T00:00:00Z");
        User user = new User(
            AuthProvider.KAKAO,
            "123",
            "user@example.com",
            "감자여행자",
            "https://example.com/profile.png",
            createdAt
        );
        ReflectionTestUtils.setField(user, "id", 1L);
        UserRepository userRepository = mock(UserRepository.class);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));

        UserProfileResponse profile = new UserProfileService(userRepository).getProfile(1L);

        assertThat(profile.userId()).isEqualTo(1L);
        assertThat(profile.nickname()).isEqualTo("감자여행자");
        assertThat(profile.email()).isEqualTo("user@example.com");
        assertThat(profile.profileImage()).isEqualTo("https://example.com/profile.png");
        assertThat(profile.createdAt()).isEqualTo(createdAt);
    }

    @Test
    void rejectsUnknownUserId() {
        UserRepository userRepository = mock(UserRepository.class);
        when(userRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> new UserProfileService(userRepository).getProfile(99L))
            .isInstanceOf(UserProfileAuthenticationException.class);
    }
}
