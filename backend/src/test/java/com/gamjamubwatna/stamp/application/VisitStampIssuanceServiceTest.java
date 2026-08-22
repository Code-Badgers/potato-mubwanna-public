package com.gamjamubwatna.stamp.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.stamp.domain.Stamp;
import com.gamjamubwatna.stamp.domain.StampRepository;
import com.gamjamubwatna.stamp.domain.UserStamp;
import com.gamjamubwatna.stamp.domain.UserStampRepository;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

class VisitStampIssuanceServiceTest {

    private StampRepository stampRepository;
    private UserStampRepository userStampRepository;
    private VisitStampIssuanceService service;

    @BeforeEach
    void setUp() {
        stampRepository = mock(StampRepository.class);
        userStampRepository = mock(UserStampRepository.class);
        service = new VisitStampIssuanceService(stampRepository, userStampRepository);
    }

    @Test
    void issuesPassportStampForFirstSpotVisit() {
        User user = user();
        TouristSpot spot = spot();
        Stamp stamp = stamp();
        when(stampRepository.findByTouristSpotIdForUpdate(101L))
            .thenReturn(Optional.of(stamp));
        when(userStampRepository.existsByUserIdAndStampId(1L, 2L)).thenReturn(false);

        boolean issued = service.issueStamp(
            user,
            spot,
            Instant.parse("2026-07-23T00:00:00Z")
        );

        assertThat(issued).isTrue();
        verify(userStampRepository).save(any(UserStamp.class));
    }

    @Test
    void skipsStampAlreadyOwnedByUser() {
        when(stampRepository.findByTouristSpotIdForUpdate(101L))
            .thenReturn(Optional.of(stamp()));
        when(userStampRepository.existsByUserIdAndStampId(1L, 2L)).thenReturn(true);

        boolean issued = service.issueStamp(
            user(),
            spot(),
            Instant.parse("2026-07-23T00:00:00Z")
        );

        assertThat(issued).isFalse();
        verify(userStampRepository, never()).save(any(UserStamp.class));
    }

    @Test
    void skipsSpotWithStampIssuanceDisabled() {
        TouristSpot spot = spot();
        ReflectionTestUtils.setField(spot, "stampEnabled", false);

        boolean issued = service.issueStamp(
            user(),
            spot,
            Instant.parse("2026-07-23T00:00:00Z")
        );

        assertThat(issued).isFalse();
        verifyNoInteractions(stampRepository, userStampRepository);
    }

    @Test
    void skipsSpotWithoutConfiguredPassportStamp() {
        when(stampRepository.findByTouristSpotIdForUpdate(101L))
            .thenReturn(Optional.empty());

        boolean issued = service.issueStamp(
            user(),
            spot(),
            Instant.parse("2026-07-23T00:00:00Z")
        );

        assertThat(issued).isFalse();
        verifyNoInteractions(userStampRepository);
    }

    private User user() {
        User user = new User(
            AuthProvider.KAKAO,
            "visit-stamp-user",
            null,
            "스탬프 사용자",
            null,
            Instant.parse("2026-07-01T00:00:00Z")
        );
        ReflectionTestUtils.setField(user, "id", 1L);
        return user;
    }

    private TouristSpot spot() {
        TouristSpot spot = new TouristSpot(
            "visit-stamp-spot",
            12,
            "정선 5일장",
            SpotCategory.POTATO_TOUR,
            new BigDecimal("37.3801000"),
            new BigDecimal("128.6609000"),
            "강원특별자치도 정선군",
            "정선군",
            null,
            "감자,시장",
            Instant.parse("2026-07-01T00:00:00Z")
        );
        ReflectionTestUtils.setField(spot, "id", 101L);
        return spot;
    }

    private Stamp stamp() {
        Stamp stamp = new Stamp(
            "PASSPORT_SPOT_visit-stamp-spot",
            spot(),
            null,
            2,
            Instant.parse("2026-07-01T00:00:00Z")
        );
        ReflectionTestUtils.setField(stamp, "id", 2L);
        return stamp;
    }
}
