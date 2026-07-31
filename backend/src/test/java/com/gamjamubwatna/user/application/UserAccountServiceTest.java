package com.gamjamubwatna.user.application;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.inOrder;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.RefreshTokenRepository;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.visit.domain.UserVisitRepository;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.mockito.InOrder;

class UserAccountServiceTest {

    @Test
    void deletesSessionsAndVisitsBeforeUserAccount() {
        UserRepository userRepository = mock(UserRepository.class);
        RefreshTokenRepository refreshTokenRepository = mock(RefreshTokenRepository.class);
        UserVisitRepository userVisitRepository = mock(UserVisitRepository.class);
        User user = user();
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        UserAccountService service = new UserAccountService(
            userRepository,
            refreshTokenRepository,
            userVisitRepository
        );

        service.withdraw(1L);

        InOrder deletionOrder = inOrder(
            refreshTokenRepository,
            userVisitRepository,
            userRepository
        );
        deletionOrder.verify(refreshTokenRepository).deleteAllByUserId(1L);
        deletionOrder.verify(userVisitRepository).deleteAllByUserId(1L);
        deletionOrder.verify(userRepository).delete(user);
    }

    @Test
    void rejectsUnknownUserWithoutDeletingRelatedData() {
        UserRepository userRepository = mock(UserRepository.class);
        RefreshTokenRepository refreshTokenRepository = mock(RefreshTokenRepository.class);
        UserVisitRepository userVisitRepository = mock(UserVisitRepository.class);
        when(userRepository.findById(99L)).thenReturn(Optional.empty());
        UserAccountService service = new UserAccountService(
            userRepository,
            refreshTokenRepository,
            userVisitRepository
        );

        assertThatThrownBy(() -> service.withdraw(99L))
            .isInstanceOf(UserProfileAuthenticationException.class);

        verify(refreshTokenRepository, never()).deleteAllByUserId(99L);
        verify(userVisitRepository, never()).deleteAllByUserId(99L);
        verify(userRepository, never()).deleteById(99L);
    }

    private User user() {
        return new User(
            AuthProvider.KAKAO,
            "123",
            "user@example.com",
            "감자여행자",
            null,
            Instant.parse("2026-06-23T00:00:00Z")
        );
    }
}
