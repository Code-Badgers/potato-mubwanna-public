package com.gamjamubwatna.potato.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.potato.application.VisitPotatoAcquisitionService.PotatoAcquisitionResult;
import com.gamjamubwatna.potato.domain.Potato;
import com.gamjamubwatna.potato.domain.PotatoRepository;
import com.gamjamubwatna.potato.domain.PotatoRarity;
import com.gamjamubwatna.potato.domain.UserPotato;
import com.gamjamubwatna.potato.domain.UserPotatoRepository;
import com.gamjamubwatna.spot.domain.CongestionLevel;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

class VisitPotatoAcquisitionServiceTest {

    private PotatoRepository potatoRepository;
    private UserPotatoRepository userPotatoRepository;
    private VisitPotatoAcquisitionService service;

    @BeforeEach
    void setUp() {
        potatoRepository = mock(PotatoRepository.class);
        userPotatoRepository = mock(UserPotatoRepository.class);
        service = new VisitPotatoAcquisitionService(
            potatoRepository,
            userPotatoRepository,
            new CongestionRarityPolicy()
        );
    }

    @Test
    void givesEpicPotatoFirstForLowCongestionVisit() {
        User user = user();
        Potato epic = potato(3L, "황금감자", PotatoRarity.EPIC);
        when(potatoRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(epic));
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of());
        when(userPotatoRepository.save(any(UserPotato.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

        PotatoAcquisitionResult result = service.acquireForVisit(
            user,
            spot(CongestionLevel.LOW),
            Instant.parse("2026-07-26T00:00:00Z")
        );

        assertThat(result.newlyAcquired()).isTrue();
        assertThat(result.potato().rarity()).isEqualTo(PotatoRarity.EPIC);
        assertThat(result.potato().alreadyOwned()).isFalse();
        verify(userPotatoRepository).save(any(UserPotato.class));
    }

    @Test
    void fallsBackToCommonPotatoWhenNormalRarityCandidateIsMissing() {
        User user = user();
        Potato common = potato(1L, "하지감자", PotatoRarity.COMMON);
        when(potatoRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(common));
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of());

        PotatoAcquisitionResult result = service.acquireForVisit(
            user,
            spot(CongestionLevel.NORMAL),
            Instant.parse("2026-07-26T00:00:00Z")
        );

        assertThat(result.newlyAcquired()).isTrue();
        assertThat(result.potato().rarity()).isEqualTo(PotatoRarity.COMMON);
    }

    @Test
    void doesNotCreateDuplicateUserPotatoWhenAlreadyOwned() {
        User user = user();
        Potato common = potato(1L, "하지감자", PotatoRarity.COMMON);
        UserPotato owned = mock(UserPotato.class);
        when(owned.getPotato()).thenReturn(common);
        when(potatoRepository.findByActiveTrueOrderByDisplayOrderAsc()).thenReturn(List.of(common));
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(owned));

        PotatoAcquisitionResult result = service.acquireForVisit(
            user,
            spot(CongestionLevel.HIGH),
            Instant.parse("2026-07-26T00:00:00Z")
        );

        assertThat(result.newlyAcquired()).isFalse();
        assertThat(result.potato().alreadyOwned()).isTrue();
        verify(userPotatoRepository, never()).save(any(UserPotato.class));
    }

    @Test
    void givesUnownedRegionalPotatoBeforeAlreadyOwnedGlobalCandidate() {
        User user = user();
        Potato haji = potato(1L, "하지감자", "강릉시", PotatoRarity.COMMON);
        Potato gondre = potato(2L, "곤드레감자", "정선군", PotatoRarity.RARE);
        UserPotato ownedGondre = mock(UserPotato.class);
        when(ownedGondre.getPotato()).thenReturn(gondre);
        when(potatoRepository.findByActiveTrueOrderByDisplayOrderAsc())
            .thenReturn(List.of(haji, gondre));
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(ownedGondre));

        PotatoAcquisitionResult result = service.acquireForVisit(
            user,
            spot("경포대", "강릉시", CongestionLevel.NORMAL),
            Instant.parse("2026-08-04T00:00:00Z")
        );

        assertThat(result.newlyAcquired()).isTrue();
        assertThat(result.potato().name()).isEqualTo("하지감자");
        verify(userPotatoRepository).save(any(UserPotato.class));
    }

    @Test
    void doesNotReplaceOwnedRegionalPotatoWithAnotherRegionsPotato() {
        User user = user();
        Potato haji = potato(1L, "하지감자", "강릉시", PotatoRarity.COMMON);
        Potato hoban = potato(2L, "호반감자", "춘천시", PotatoRarity.COMMON);
        UserPotato ownedHaji = mock(UserPotato.class);
        when(ownedHaji.getPotato()).thenReturn(haji);
        when(potatoRepository.findByActiveTrueOrderByDisplayOrderAsc())
            .thenReturn(List.of(haji, hoban));
        when(userPotatoRepository.findByUserId(1L)).thenReturn(List.of(ownedHaji));

        PotatoAcquisitionResult result = service.acquireForVisit(
            user,
            spot("경포대", "강릉시", CongestionLevel.HIGH),
            Instant.parse("2026-08-04T00:00:00Z")
        );

        assertThat(result.newlyAcquired()).isFalse();
        assertThat(result.potato().name()).isEqualTo("하지감자");
        verify(userPotatoRepository, never()).save(any(UserPotato.class));
    }

    private User user() {
        User user = new User(
            AuthProvider.KAKAO,
            "provider-1",
            "user@example.com",
            "감자러버",
            null,
            Instant.parse("2026-07-01T00:00:00Z")
        );
        ReflectionTestUtils.setField(user, "id", 1L);
        return user;
    }

    private TouristSpot spot(CongestionLevel congestionLevel) {
        return spot("정선 5일장", "정선군", congestionLevel);
    }

    private TouristSpot spot(String name, String cityName, CongestionLevel congestionLevel) {
        TouristSpot spot = new TouristSpot(
            "spot-1",
            12,
            name,
            SpotCategory.POTATO_TOUR,
            new BigDecimal("37.3801000"),
            new BigDecimal("128.6609000"),
            "강원특별자치도 " + cityName,
            cityName,
            null,
            "감자,시장",
            Instant.parse("2026-07-01T00:00:00Z")
        );
        ReflectionTestUtils.setField(spot, "id", 10L);
        spot.updateCongestionLevel(congestionLevel, Instant.parse("2026-07-01T00:00:00Z"));
        return spot;
    }

    private Potato potato(Long id, String name, PotatoRarity rarity) {
        return potato(id, name, "강원특별자치도", rarity);
    }

    private Potato potato(Long id, String name, String region, PotatoRarity rarity) {
        Potato potato = new Potato(
            "CODE_" + id,
            name,
            region,
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
