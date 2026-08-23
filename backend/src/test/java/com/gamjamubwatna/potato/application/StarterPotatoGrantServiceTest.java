package com.gamjamubwatna.potato.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.potato.domain.Potato;
import com.gamjamubwatna.potato.domain.PotatoRarity;
import com.gamjamubwatna.potato.domain.PotatoRepository;
import com.gamjamubwatna.potato.domain.UserPotato;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.test.util.ReflectionTestUtils;

class StarterPotatoGrantServiceTest {

    private static final Instant NOW = Instant.parse("2026-08-23T00:00:00Z");

    @Test
    void grantsStarterAsRepresentativeWhenUserHasNoPotato() {
        PotatoRepository potatoRepository = mock(PotatoRepository.class);
        UserPotatoRepository userPotatoRepository = mock(UserPotatoRepository.class);
        User user = user();
        Potato starter = starterPotato();
        when(userPotatoRepository.countByUserId(1L)).thenReturn(0L);
        when(potatoRepository.findByCode(StarterPotatoGrantService.STARTER_POTATO_CODE))
            .thenReturn(Optional.of(starter));

        new StarterPotatoGrantService(potatoRepository, userPotatoRepository)
            .grantIfNeeded(user, NOW);

        ArgumentCaptor<UserPotato> captor = ArgumentCaptor.forClass(UserPotato.class);
        verify(userPotatoRepository).save(captor.capture());
        UserPotato granted = captor.getValue();
        assertThat(granted.getUser()).isSameAs(user);
        assertThat(granted.getPotato()).isSameAs(starter);
        assertThat(granted.getAcquiredAt()).isEqualTo(NOW);
        assertThat(granted.getLevel()).isEqualTo(1);
        assertThat(granted.getGrowthDistance()).isZero();
        assertThat(granted.isRepresentative()).isTrue();
    }

    @Test
    void keepsExistingCollectionUnchanged() {
        PotatoRepository potatoRepository = mock(PotatoRepository.class);
        UserPotatoRepository userPotatoRepository = mock(UserPotatoRepository.class);
        User user = user();
        when(userPotatoRepository.countByUserId(1L)).thenReturn(1L);

        new StarterPotatoGrantService(potatoRepository, userPotatoRepository)
            .grantIfNeeded(user, NOW);

        verify(potatoRepository, never()).findByCode(any());
        verify(userPotatoRepository, never()).save(any());
    }

    @Test
    void failsLoginTransactionWhenStarterCatalogIsMissing() {
        PotatoRepository potatoRepository = mock(PotatoRepository.class);
        UserPotatoRepository userPotatoRepository = mock(UserPotatoRepository.class);
        when(userPotatoRepository.countByUserId(1L)).thenReturn(0L);
        when(potatoRepository.findByCode(StarterPotatoGrantService.STARTER_POTATO_CODE))
            .thenReturn(Optional.empty());

        StarterPotatoGrantService service =
            new StarterPotatoGrantService(potatoRepository, userPotatoRepository);

        assertThatThrownBy(() -> service.grantIfNeeded(user(), NOW))
            .isInstanceOf(IllegalStateException.class)
            .hasMessage("기본 감자 카탈로그를 찾을 수 없습니다.");
    }

    private User user() {
        User user = new User(
            AuthProvider.KAKAO,
            "starter-user",
            null,
            "새싹 사용자",
            null,
            NOW
        );
        ReflectionTestUtils.setField(user, "id", 1L);
        return user;
    }

    private Potato starterPotato() {
        return new Potato(
            StarterPotatoGrantService.STARTER_POTATO_CODE,
            "새싹 감자",
            "강원 여행길",
            PotatoRarity.COMMON,
            "기본 지급 감자",
            "회원가입 시 기본 지급",
            null,
            3000,
            0,
            true,
            NOW
        );
    }
}
