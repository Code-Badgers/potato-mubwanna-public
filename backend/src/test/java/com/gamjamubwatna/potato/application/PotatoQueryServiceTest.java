package com.gamjamubwatna.potato.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.potato.api.PotatoCatalogResponse;
import com.gamjamubwatna.potato.api.UserPotatoCollectionResponse;
import com.gamjamubwatna.potato.domain.Potato;
import com.gamjamubwatna.potato.domain.PotatoRarity;
import com.gamjamubwatna.potato.domain.PotatoRepository;
import com.gamjamubwatna.potato.domain.UserPotato;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class PotatoQueryServiceTest {

    @Mock
    private PotatoRepository potatoRepository;

    @Mock
    private UserPotatoRepository userPotatoRepository;

    @Mock
    private UserRepository userRepository;

    private PotatoQueryService potatoQueryService;

    @BeforeEach
    void setUp() {
        potatoQueryService = new PotatoQueryService(
            potatoRepository,
            userPotatoRepository,
            userRepository
        );
    }

    @Test
    void returnsActivePotatoCatalogInRepositoryOrder() {
        when(potatoRepository.findByActiveTrueOrderByDisplayOrderAsc())
            .thenReturn(List.of(potato(1L, "하지감자", PotatoRarity.COMMON)));

        PotatoCatalogResponse result = potatoQueryService.getPotatoes();

        assertThat(result.totalCount()).isEqualTo(1);
        assertThat(result.items().getFirst().potatoId()).isEqualTo(1L);
        assertThat(result.items().getFirst().name()).isEqualTo("하지감자");
        assertThat(result.items().getFirst().rarity()).isEqualTo(PotatoRarity.COMMON);
    }

    @Test
    void mergesAcquiredPotatoesIntoFullCatalog() {
        Potato acquired = potato(1L, "곤드레감자", PotatoRarity.RARE);
        Potato locked = potato(2L, "전설감자", PotatoRarity.LEGENDARY);
        UserPotato userPotato = new UserPotato(
            mock(User.class),
            acquired,
            Instant.parse("2026-07-01T00:00:00Z"),
            3,
            4200.0,
            true
        );
        when(userRepository.existsById(1L)).thenReturn(true);
        when(potatoRepository.findByActiveTrueOrderByDisplayOrderAsc())
            .thenReturn(List.of(acquired, locked));
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(userPotato));

        UserPotatoCollectionResponse result = potatoQueryService.getMyPotatoes(1L);

        assertThat(result.totalCount()).isEqualTo(2);
        assertThat(result.acquiredCount()).isEqualTo(1);
        assertThat(result.items().getFirst().acquired()).isTrue();
        assertThat(result.items().getFirst().level()).isEqualTo(3);
        assertThat(result.items().getFirst().representative()).isTrue();
        assertThat(result.items().get(1).acquired()).isFalse();
        assertThat(result.items().get(1).level()).isZero();
    }

    @Test
    void rejectsDeletedUser() {
        when(userRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> potatoQueryService.getMyPotatoes(99L))
            .isInstanceOf(PotatoAuthenticationException.class);
    }

    private Potato potato(Long id, String name, PotatoRarity rarity) {
        Potato potato = new Potato(
            "CODE_" + id,
            name,
            "강릉시",
            rarity,
            name + " 설명",
            name + " 획득 방법",
            null,
            3000.0,
            id.intValue(),
            true,
            Instant.parse("2026-07-01T00:00:00Z")
        );
        ReflectionTestUtils.setField(potato, "id", id);
        return potato;
    }
}
