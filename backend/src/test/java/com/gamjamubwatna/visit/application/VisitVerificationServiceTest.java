package com.gamjamubwatna.visit.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.potato.api.PotatoAcquisitionResponse;
import com.gamjamubwatna.potato.application.VisitPotatoAcquisitionService;
import com.gamjamubwatna.potato.application.VisitPotatoAcquisitionService.PotatoAcquisitionResult;
import com.gamjamubwatna.potato.domain.PotatoRarity;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.stamp.application.VisitStampIssuanceService;
import com.gamjamubwatna.visit.api.VisitVerifyRequest;
import com.gamjamubwatna.visit.api.VisitVerifyResponse;
import com.gamjamubwatna.visit.domain.UserVisit;
import com.gamjamubwatna.visit.domain.UserVisitRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

class VisitVerificationServiceTest {

    private UserRepository userRepository;
    private TouristSpotRepository touristSpotRepository;
    private UserVisitRepository userVisitRepository;
    private VisitStampIssuanceService visitStampIssuanceService;
    private VisitPotatoAcquisitionService visitPotatoAcquisitionService;
    private VisitVerificationService visitVerificationService;

    @BeforeEach
    void setUp() {
        userRepository = mock(UserRepository.class);
        touristSpotRepository = mock(TouristSpotRepository.class);
        userVisitRepository = mock(UserVisitRepository.class);
        visitStampIssuanceService = mock(VisitStampIssuanceService.class);
        visitPotatoAcquisitionService = mock(VisitPotatoAcquisitionService.class);
        visitVerificationService = new VisitVerificationService(
            userRepository,
            touristSpotRepository,
            userVisitRepository,
            new VisitDistancePolicy(),
            visitStampIssuanceService,
            visitPotatoAcquisitionService,
            Clock.fixed(Instant.parse("2026-07-22T00:00:00Z"), ZoneOffset.UTC)
        );
    }

    @Test
    void verifiesVisitWhenUserIsInsideSpotRadius() {
        User user = user();
        TouristSpot spot = spot();
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(touristSpotRepository.findByIdAndActiveTrue(10L)).thenReturn(Optional.of(spot));
        when(userVisitRepository.existsByUserIdAndTouristSpotId(1L, 10L)).thenReturn(false);
        when(visitStampIssuanceService.issueStamp(any(), any(), any())).thenReturn(true);
        when(visitPotatoAcquisitionService.acquireForVisit(any(), any(), any()))
            .thenReturn(new PotatoAcquisitionResult(
                true,
                new PotatoAcquisitionResponse(
                    3L,
                    "POTATO_GOLDEN_GANGWON",
                    "황금감자",
                    "강원특별자치도",
                    PotatoRarity.EPIC,
                    false
                )
            ));

        VisitVerifyResponse result = visitVerificationService.verifyVisit(
            1L,
            new VisitVerifyRequest(
                10L,
                new BigDecimal("37.3801000"),
                new BigDecimal("128.6609000")
            )
        );

        assertThat(result.verified()).isTrue();
        assertThat(result.spotId()).isEqualTo(10L);
        assertThat(result.distanceMeters()).isEqualByComparingTo("0.00");
        assertThat(result.verificationRadiusMeter()).isEqualTo(100);
        assertThat(result.stampIssued()).isTrue();
        assertThat(result.potatoAcquired()).isTrue();
        assertThat(result.acquiredPotato().name()).isEqualTo("황금감자");
        assertThat(result.acquiredPotato().alreadyOwned()).isFalse();
        assertThat(result.missionAvailable()).isFalse();
        verify(userVisitRepository).save(any(UserVisit.class));
        verify(visitStampIssuanceService).issueStamp(any(), any(), any());
        verify(visitPotatoAcquisitionService).acquireForVisit(any(), any(), any());
    }

    @Test
    void rejectsVisitWhenUserIsOutsideSpotRadius() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user()));
        when(touristSpotRepository.findByIdAndActiveTrue(10L)).thenReturn(Optional.of(spot()));
        when(userVisitRepository.existsByUserIdAndTouristSpotId(1L, 10L)).thenReturn(false);

        assertThatThrownBy(() -> visitVerificationService.verifyVisit(
            1L,
            new VisitVerifyRequest(
                10L,
                new BigDecimal("37.3901000"),
                new BigDecimal("128.6609000")
            )
        ))
            .isInstanceOf(VisitVerificationException.class)
            .hasMessage("방문 인증 가능 범위를 벗어났습니다.");
    }

    @Test
    void rejectsDuplicateVisit() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user()));
        when(touristSpotRepository.findByIdAndActiveTrue(10L)).thenReturn(Optional.of(spot()));
        when(userVisitRepository.existsByUserIdAndTouristSpotId(1L, 10L)).thenReturn(true);

        assertThatThrownBy(() -> visitVerificationService.verifyVisit(
            1L,
            new VisitVerifyRequest(
                10L,
                new BigDecimal("37.3801000"),
                new BigDecimal("128.6609000")
            )
        ))
            .isInstanceOf(VisitDuplicateException.class)
            .hasMessage("이미 방문 인증한 감자 스팟입니다.");
    }

    @Test
    void rejectsInvalidCoordinates() {
        assertThatThrownBy(() -> visitVerificationService.verifyVisit(
            1L,
            new VisitVerifyRequest(10L, new BigDecimal("91"), new BigDecimal("128.6609000"))
        ))
            .isInstanceOf(VisitVerificationException.class)
            .hasMessage("방문 인증 위치를 확인할 수 없습니다.");
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

    private TouristSpot spot() {
        TouristSpot spot = new TouristSpot(
            "spot-10",
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
        ReflectionTestUtils.setField(spot, "id", 10L);
        return spot;
    }
}
