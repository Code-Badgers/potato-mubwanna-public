package com.gamjamubwatna.visit.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.legal.application.LocationUsageLogService;
import com.gamjamubwatna.mission.domain.Mission;
import com.gamjamubwatna.mission.domain.MissionGroup;
import com.gamjamubwatna.mission.domain.MissionRepository;
import com.gamjamubwatna.mission.domain.MissionRewardType;
import com.gamjamubwatna.mission.domain.MissionStatus;
import com.gamjamubwatna.mission.domain.MissionType;
import com.gamjamubwatna.mission.domain.UserMissionRepository;
import com.gamjamubwatna.potato.api.PotatoAcquisitionResponse;
import com.gamjamubwatna.potato.application.VisitPotatoAcquisitionService;
import com.gamjamubwatna.potato.application.VisitPotatoAcquisitionService.PotatoAcquisitionResult;
import com.gamjamubwatna.potato.domain.PotatoAcquisitionType;
import com.gamjamubwatna.potato.domain.PotatoRarity;
import com.gamjamubwatna.push.application.PushEventPublisher;
import com.gamjamubwatna.push.application.PushNotificationMessage;
import com.gamjamubwatna.push.domain.PushDestination;
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
import org.mockito.ArgumentCaptor;
import org.springframework.test.util.ReflectionTestUtils;

class VisitVerificationServiceTest {

    private UserRepository userRepository;
    private TouristSpotRepository touristSpotRepository;
    private UserVisitRepository userVisitRepository;
    private VisitStampIssuanceService visitStampIssuanceService;
    private VisitPotatoAcquisitionService visitPotatoAcquisitionService;
    private MissionRepository missionRepository;
    private UserMissionRepository userMissionRepository;
    private LocationUsageLogService locationUsageLogService;
    private PushEventPublisher pushEventPublisher;
    private VisitVerificationService visitVerificationService;

    @BeforeEach
    void setUp() {
        userRepository = mock(UserRepository.class);
        touristSpotRepository = mock(TouristSpotRepository.class);
        userVisitRepository = mock(UserVisitRepository.class);
        visitStampIssuanceService = mock(VisitStampIssuanceService.class);
        visitPotatoAcquisitionService = mock(VisitPotatoAcquisitionService.class);
        missionRepository = mock(MissionRepository.class);
        userMissionRepository = mock(UserMissionRepository.class);
        locationUsageLogService = mock(LocationUsageLogService.class);
        pushEventPublisher = mock(PushEventPublisher.class);
        visitVerificationService = new VisitVerificationService(
            userRepository,
            touristSpotRepository,
            userVisitRepository,
            new VisitDistancePolicy(),
            visitStampIssuanceService,
            visitPotatoAcquisitionService,
            missionRepository,
            userMissionRepository,
            locationUsageLogService,
            pushEventPublisher,
            Clock.fixed(Instant.parse("2026-07-22T00:00:00Z"), ZoneOffset.UTC)
        );
        when(userVisitRepository.save(any(UserVisit.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(missionRepository.findFirstBySpotNameAndCityNameAndActiveTrueOrderByDisplayOrderAsc(any(), any()))
            .thenReturn(Optional.empty());
        when(missionRepository.findFirstBySpotNameAndActiveTrueOrderByDisplayOrderAsc(any()))
            .thenReturn(Optional.empty());
    }

    @Test
    void verifiesVisitWhenUserIsInsideSpotRadius() {
        User user = user();
        TouristSpot spot = spot();
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(touristSpotRepository.findByIdAndActiveTrue(10L)).thenReturn(Optional.of(spot));
        when(userVisitRepository.findByUserIdAndSpotIdForUpdate(1L, 10L)).thenReturn(Optional.empty());
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
                    PotatoAcquisitionType.VISIT.name(),
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
        assertThat(result.acquiredPotato().acquisitionType()).isEqualTo("VISIT");
        assertThat(result.acquiredPotato().alreadyOwned()).isFalse();
        assertThat(result.missionAvailable()).isFalse();
        assertThat(result.unlockedMission()).isNull();
        verify(userVisitRepository).save(any(UserVisit.class));
        verify(visitStampIssuanceService).issueStamp(any(), any(), any());
        verify(visitPotatoAcquisitionService).acquireForVisit(any(), any(), any());
        verify(locationUsageLogService).recordVisitVerification(
            1L,
            Instant.parse("2026-07-22T00:00:00Z"),
            true
        );
        ArgumentCaptor<PushNotificationMessage> pushCaptor =
            ArgumentCaptor.forClass(PushNotificationMessage.class);
        verify(pushEventPublisher).publish(eq(1L), pushCaptor.capture());
        assertThat(pushCaptor.getValue().destination()).isEqualTo(PushDestination.SPOT);
        assertThat(pushCaptor.getValue().destinationId()).isEqualTo(10L);
        assertThat(pushCaptor.getValue().body()).contains("스탬프·감자 획득");
    }

    @Test
    void returnsUnlockedMissionWhenSpotHasActiveIncompleteMission() {
        User user = user();
        TouristSpot spot = spot();
        Mission mission = mission();
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(touristSpotRepository.findByIdAndActiveTrue(10L)).thenReturn(Optional.of(spot));
        when(userVisitRepository.findByUserIdAndSpotIdForUpdate(1L, 10L)).thenReturn(Optional.empty());
        when(visitStampIssuanceService.issueStamp(any(), any(), any())).thenReturn(true);
        when(visitPotatoAcquisitionService.acquireForVisit(any(), any(), any()))
            .thenReturn(new PotatoAcquisitionResult(false, null));
        when(missionRepository.findFirstBySpotNameAndCityNameAndActiveTrueOrderByDisplayOrderAsc(
            "정선 5일장",
            "정선군"
        )).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1004L)).thenReturn(false);

        VisitVerifyResponse result = visitVerificationService.verifyVisit(
            1L,
            new VisitVerifyRequest(
                10L,
                new BigDecimal("37.3801000"),
                new BigDecimal("128.6609000")
            )
        );

        assertThat(result.missionAvailable()).isTrue();
        assertThat(result.unlockedMission()).isNotNull();
        assertThat(result.unlockedMission().missionId()).isEqualTo(1004L);
        assertThat(result.unlockedMission().title()).isEqualTo("정선 5일장 곤드레 퀴즈");
        assertThat(result.unlockedMission().rewardLabel()).isEqualTo("황금감자 성장 아이템");
    }

    @Test
    void doesNotReturnUnlockedMissionWhenMissionAlreadyCompleted() {
        User user = user();
        TouristSpot spot = spot();
        Mission mission = mission();
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(touristSpotRepository.findByIdAndActiveTrue(10L)).thenReturn(Optional.of(spot));
        when(userVisitRepository.findByUserIdAndSpotIdForUpdate(1L, 10L)).thenReturn(Optional.empty());
        when(visitStampIssuanceService.issueStamp(any(), any(), any())).thenReturn(true);
        when(visitPotatoAcquisitionService.acquireForVisit(any(), any(), any()))
            .thenReturn(new PotatoAcquisitionResult(false, null));
        when(missionRepository.findFirstBySpotNameAndCityNameAndActiveTrueOrderByDisplayOrderAsc(
            "정선 5일장",
            "정선군"
        )).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1004L)).thenReturn(true);

        VisitVerifyResponse result = visitVerificationService.verifyVisit(
            1L,
            new VisitVerifyRequest(
                10L,
                new BigDecimal("37.3801000"),
                new BigDecimal("128.6609000")
            )
        );

        assertThat(result.missionAvailable()).isFalse();
        assertThat(result.unlockedMission()).isNull();
    }

    @Test
    void rejectsVisitWhenUserIsOutsideSpotRadius() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user()));
        when(touristSpotRepository.findByIdAndActiveTrue(10L)).thenReturn(Optional.of(spot()));
        when(userVisitRepository.findByUserIdAndSpotIdForUpdate(1L, 10L)).thenReturn(Optional.empty());

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
        verify(locationUsageLogService).recordVisitVerification(
            1L,
            Instant.parse("2026-07-22T00:00:00Z"),
            false
        );
    }

    @Test
    void rejectsDuplicateVisit() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user()));
        when(touristSpotRepository.findByIdAndActiveTrue(10L)).thenReturn(Optional.of(spot()));
        when(userVisitRepository.findByUserIdAndSpotIdForUpdate(1L, 10L))
            .thenReturn(Optional.of(new UserVisit(user(), spot(), BigDecimal.ZERO, Instant.EPOCH)));

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

    @Test
    void processesPhotoVisitRewardsOnceWithoutDuplicatingTravelRecord() {
        User user = user();
        TouristSpot spot = spot();
        UserVisit photoVisit = UserVisit.fromPhotoEvidence(user, spot, BigDecimal.ZERO, Instant.EPOCH);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(touristSpotRepository.findByIdAndActiveTrue(10L)).thenReturn(Optional.of(spot));
        when(userVisitRepository.findByUserIdAndSpotIdForUpdate(1L, 10L)).thenReturn(Optional.of(photoVisit));
        when(visitStampIssuanceService.issueStamp(any(), any(), any())).thenReturn(true);
        when(visitPotatoAcquisitionService.acquireForVisit(any(), any(), any()))
            .thenReturn(new PotatoAcquisitionResult(true, null));
        VisitVerifyRequest request = new VisitVerifyRequest(10L, spot.getLatitude(), spot.getLongitude());

        VisitVerifyResponse response = visitVerificationService.verifyVisit(1L, request);

        assertThat(response.stampIssued()).isTrue();
        assertThat(response.potatoAcquired()).isTrue();
        assertThat(photoVisit.isVisitRewardsProcessed()).isTrue();
        assertThat(photoVisit.getVisitedAt()).isEqualTo(Instant.EPOCH);
        org.mockito.Mockito.verify(userVisitRepository, org.mockito.Mockito.never()).save(any());
        assertThatThrownBy(() -> visitVerificationService.verifyVisit(1L, request))
            .isInstanceOf(VisitDuplicateException.class);
        verify(visitPotatoAcquisitionService).acquireForVisit(any(), any(), any());
    }

    @Test
    void photoEvidenceDoesNotBypassCurrentLocationVerification() {
        UserVisit photoVisit = UserVisit.fromPhotoEvidence(user(), spot(), BigDecimal.ZERO, Instant.EPOCH);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user()));
        when(touristSpotRepository.findByIdAndActiveTrue(10L)).thenReturn(Optional.of(spot()));
        when(userVisitRepository.findByUserIdAndSpotIdForUpdate(1L, 10L)).thenReturn(Optional.of(photoVisit));

        assertThatThrownBy(() -> visitVerificationService.verifyVisit(1L,
            new VisitVerifyRequest(10L, new BigDecimal("38"), new BigDecimal("128"))))
            .isInstanceOf(VisitVerificationException.class);
        assertThat(photoVisit.isVisitRewardsProcessed()).isFalse();
        org.mockito.Mockito.verifyNoInteractions(visitStampIssuanceService, visitPotatoAcquisitionService);
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

    private Mission mission() {
        Mission mission = new Mission(
            "MISSION_JEONGSEON_MARKET_QUIZ",
            MissionGroup.JUMSOONI,
            MissionType.QUIZ,
            MissionStatus.READY,
            "정선 5일장 곤드레 퀴즈",
            "정선 5일장",
            "정선군",
            "정선 장터에서 점순이가 내는 향토 음식 퀴즈를 풀어보세요.",
            "여까지 왔네? 장터 냄새만 맡아도 배고프지 않나?",
            "퀴즈 1개 정답",
            MissionRewardType.ITEM,
            "황금감자 성장 아이템",
            0,
            1,
            true,
            true,
            1,
            Instant.parse("2026-07-01T00:00:00Z")
        );
        ReflectionTestUtils.setField(mission, "id", 1004L);
        return mission;
    }
}
