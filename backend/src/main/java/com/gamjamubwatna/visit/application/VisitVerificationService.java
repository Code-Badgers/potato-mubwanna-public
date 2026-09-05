package com.gamjamubwatna.visit.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.legal.application.LocationUsageLogService;
import com.gamjamubwatna.mission.domain.Mission;
import com.gamjamubwatna.mission.domain.MissionRepository;
import com.gamjamubwatna.mission.domain.UserMissionRepository;
import com.gamjamubwatna.potato.application.VisitPotatoAcquisitionService;
import com.gamjamubwatna.potato.application.VisitPotatoAcquisitionService.PotatoAcquisitionResult;
import com.gamjamubwatna.push.application.PushEventPublisher;
import com.gamjamubwatna.push.application.PushNotificationMessage;
import com.gamjamubwatna.push.domain.PushDestination;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import com.gamjamubwatna.stamp.application.VisitStampIssuanceService;
import com.gamjamubwatna.visit.api.UnlockedMissionResponse;
import com.gamjamubwatna.visit.api.VisitVerifyRequest;
import com.gamjamubwatna.visit.api.VisitVerifyResponse;
import com.gamjamubwatna.visit.domain.UserVisit;
import com.gamjamubwatna.visit.domain.UserVisitRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class VisitVerificationService {

    private final UserRepository userRepository;
    private final TouristSpotRepository touristSpotRepository;
    private final UserVisitRepository userVisitRepository;
    private final VisitDistancePolicy visitDistancePolicy;
    private final VisitStampIssuanceService visitStampIssuanceService;
    private final VisitPotatoAcquisitionService visitPotatoAcquisitionService;
    private final MissionRepository missionRepository;
    private final UserMissionRepository userMissionRepository;
    private final LocationUsageLogService locationUsageLogService;
    private final PushEventPublisher pushEventPublisher;
    private final Clock clock;

    @Autowired
    public VisitVerificationService(
        UserRepository userRepository,
        TouristSpotRepository touristSpotRepository,
        UserVisitRepository userVisitRepository,
        VisitDistancePolicy visitDistancePolicy,
        VisitStampIssuanceService visitStampIssuanceService,
        VisitPotatoAcquisitionService visitPotatoAcquisitionService,
        MissionRepository missionRepository,
        UserMissionRepository userMissionRepository,
        LocationUsageLogService locationUsageLogService,
        PushEventPublisher pushEventPublisher
    ) {
        this(
            userRepository,
            touristSpotRepository,
            userVisitRepository,
            visitDistancePolicy,
            visitStampIssuanceService,
            visitPotatoAcquisitionService,
            missionRepository,
            userMissionRepository,
            locationUsageLogService,
            pushEventPublisher,
            Clock.systemUTC()
        );
    }

    VisitVerificationService(
        UserRepository userRepository,
        TouristSpotRepository touristSpotRepository,
        UserVisitRepository userVisitRepository,
        VisitDistancePolicy visitDistancePolicy,
        VisitStampIssuanceService visitStampIssuanceService,
        VisitPotatoAcquisitionService visitPotatoAcquisitionService,
        MissionRepository missionRepository,
        UserMissionRepository userMissionRepository,
        LocationUsageLogService locationUsageLogService,
        Clock clock
    ) {
        this(
            userRepository,
            touristSpotRepository,
            userVisitRepository,
            visitDistancePolicy,
            visitStampIssuanceService,
            visitPotatoAcquisitionService,
            missionRepository,
            userMissionRepository,
            locationUsageLogService,
            PushEventPublisher.noop(),
            clock
        );
    }

    VisitVerificationService(
        UserRepository userRepository,
        TouristSpotRepository touristSpotRepository,
        UserVisitRepository userVisitRepository,
        VisitDistancePolicy visitDistancePolicy,
        VisitStampIssuanceService visitStampIssuanceService,
        VisitPotatoAcquisitionService visitPotatoAcquisitionService,
        MissionRepository missionRepository,
        UserMissionRepository userMissionRepository,
        LocationUsageLogService locationUsageLogService,
        PushEventPublisher pushEventPublisher,
        Clock clock
    ) {
        this.userRepository = userRepository;
        this.touristSpotRepository = touristSpotRepository;
        this.userVisitRepository = userVisitRepository;
        this.visitDistancePolicy = visitDistancePolicy;
        this.visitStampIssuanceService = visitStampIssuanceService;
        this.visitPotatoAcquisitionService = visitPotatoAcquisitionService;
        this.missionRepository = missionRepository;
        this.userMissionRepository = userMissionRepository;
        this.locationUsageLogService = locationUsageLogService;
        this.pushEventPublisher = pushEventPublisher;
        this.clock = clock;
    }

    @Transactional
    public VisitVerifyResponse verifyVisit(Long userId, VisitVerifyRequest request) {
        validateRequest(request);
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new VisitAuthenticationException("인증 정보를 확인할 수 없습니다."));
        TouristSpot spot = touristSpotRepository.findByIdAndActiveTrue(request.spotId())
            .orElseThrow(() -> new VisitNotFoundException("감자 스팟을 찾을 수 없습니다."));
        Optional<UserVisit> existingVisit = userVisitRepository.findByUserIdAndSpotIdForUpdate(
            userId, spot.getId()
        );
        if (existingVisit.filter(UserVisit::isVisitRewardsProcessed).isPresent()) {
            throw new VisitDuplicateException("이미 방문 인증한 감자 스팟입니다.");
        }

        BigDecimal distanceMeters = visitDistancePolicy.distanceMeters(
            spot.getLatitude(),
            spot.getLongitude(),
            request.latitude(),
            request.longitude()
        );
        boolean isWithinRadius = visitDistancePolicy.isWithinRadius(
            distanceMeters,
            spot.getVerificationRadiusMeter()
        );
        Instant verifiedAt = Instant.now(clock);
        locationUsageLogService.recordVisitVerification(userId, verifiedAt, isWithinRadius);
        if (!isWithinRadius) {
            throw new VisitVerificationException("방문 인증 가능 범위를 벗어났습니다.");
        }

        UserVisit visit = existingVisit.orElseGet(() ->
            userVisitRepository.save(new UserVisit(user, spot, distanceMeters, verifiedAt))
        );
        boolean stampIssued = visitStampIssuanceService.issueStamp(user, spot, verifiedAt);
        PotatoAcquisitionResult potatoAcquisition =
            visitPotatoAcquisitionService.acquireForVisit(user, spot, verifiedAt);
        // 보상 지급과 같은 트랜잭션에서 확정한다. 실패하면 사진 기록은 재시도 가능 상태로 남는다.
        visit.markVisitRewardsProcessed();
        UnlockedMissionResponse unlockedMission = unlockedMission(userId, spot)
            .map(UnlockedMissionResponse::from)
            .orElse(null);

        pushEventPublisher.publish(
            userId,
            visitCompletedMessage(
                spot,
                stampIssued,
                potatoAcquisition.newlyAcquired(),
                unlockedMission != null
            )
        );

        return new VisitVerifyResponse(
            spot.getId(),
            true,
            distanceMeters,
            spot.getVerificationRadiusMeter(),
            stampIssued,
            potatoAcquisition.newlyAcquired(),
            potatoAcquisition.potato(),
            unlockedMission != null,
            unlockedMission
        );
    }

    private PushNotificationMessage visitCompletedMessage(
        TouristSpot spot,
        boolean stampIssued,
        boolean potatoAcquired,
        boolean missionUnlocked
    ) {
        StringBuilder body = new StringBuilder(spot.getName())
            .append(" 방문 인증이 완료됐어요.");
        List<String> results = new ArrayList<>();
        List<String> acquisitions = new ArrayList<>();
        if (stampIssued) {
            acquisitions.add("스탬프");
        }
        if (potatoAcquired) {
            acquisitions.add("감자");
        }
        if (!acquisitions.isEmpty()) {
            results.add(String.join("·", acquisitions) + " 획득");
        }
        if (missionUnlocked) {
            results.add("새 미션");
        }
        if (!results.isEmpty()) {
            body.append(' ')
                .append(String.join(", ", results))
                .append("도 확인해 보세요.");
        }
        return new PushNotificationMessage(
            "방문 인증 완료",
            body.toString(),
            PushDestination.SPOT,
            spot.getId()
        );
    }

    private Optional<Mission> unlockedMission(Long userId, TouristSpot spot) {
        Optional<Mission> mission = missionBySpot(spot);
        if (mission.isEmpty()) {
            return Optional.empty();
        }
        Mission unlocked = mission.get();
        if (userMissionRepository.existsByUserIdAndMissionId(userId, unlocked.getId())) {
            return Optional.empty();
        }
        return mission;
    }

    private Optional<Mission> missionBySpot(TouristSpot spot) {
        if (hasText(spot.getCityName())) {
            Optional<Mission> mission = missionRepository
                .findFirstBySpotNameAndCityNameAndActiveTrueOrderByDisplayOrderAsc(
                    spot.getName(),
                    spot.getCityName()
                );
            if (mission.isPresent()) {
                return mission;
            }
        }
        return missionRepository.findFirstBySpotNameAndActiveTrueOrderByDisplayOrderAsc(spot.getName());
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }

    private void validateRequest(VisitVerifyRequest request) {
        if (request == null || request.spotId() == null || request.spotId() < 1) {
            throw new VisitVerificationException("방문 인증할 감자 스팟을 확인할 수 없습니다.");
        }
        if (!isValidLatitude(request.latitude()) || !isValidLongitude(request.longitude())) {
            throw new VisitVerificationException("방문 인증 위치를 확인할 수 없습니다.");
        }
    }

    private boolean isValidLatitude(BigDecimal latitude) {
        return latitude != null
            && latitude.compareTo(BigDecimal.valueOf(-90)) >= 0
            && latitude.compareTo(BigDecimal.valueOf(90)) <= 0;
    }

    private boolean isValidLongitude(BigDecimal longitude) {
        return longitude != null
            && longitude.compareTo(BigDecimal.valueOf(-180)) >= 0
            && longitude.compareTo(BigDecimal.valueOf(180)) <= 0;
    }
}
