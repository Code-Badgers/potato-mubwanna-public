package com.gamjamubwatna.visit.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.legal.application.LocationUsageLogService;
import com.gamjamubwatna.mission.domain.Mission;
import com.gamjamubwatna.mission.domain.MissionRepository;
import com.gamjamubwatna.mission.domain.UserMissionRepository;
import com.gamjamubwatna.potato.application.VisitPotatoAcquisitionService;
import com.gamjamubwatna.potato.application.VisitPotatoAcquisitionService.PotatoAcquisitionResult;
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
        LocationUsageLogService locationUsageLogService
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
        this.userRepository = userRepository;
        this.touristSpotRepository = touristSpotRepository;
        this.userVisitRepository = userVisitRepository;
        this.visitDistancePolicy = visitDistancePolicy;
        this.visitStampIssuanceService = visitStampIssuanceService;
        this.visitPotatoAcquisitionService = visitPotatoAcquisitionService;
        this.missionRepository = missionRepository;
        this.userMissionRepository = userMissionRepository;
        this.locationUsageLogService = locationUsageLogService;
        this.clock = clock;
    }

    @Transactional
    public VisitVerifyResponse verifyVisit(Long userId, VisitVerifyRequest request) {
        validateRequest(request);
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new VisitAuthenticationException("인증 정보를 확인할 수 없습니다."));
        TouristSpot spot = touristSpotRepository.findByIdAndActiveTrue(request.spotId())
            .orElseThrow(() -> new VisitNotFoundException("감자 스팟을 찾을 수 없습니다."));
        if (userVisitRepository.existsByUserIdAndTouristSpotId(userId, spot.getId())) {
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

        userVisitRepository.save(new UserVisit(user, spot, distanceMeters, verifiedAt));
        boolean stampIssued = visitStampIssuanceService.issueStamp(user, spot, verifiedAt);
        PotatoAcquisitionResult potatoAcquisition =
            visitPotatoAcquisitionService.acquireForVisit(user, spot, verifiedAt);
        UnlockedMissionResponse unlockedMission = unlockedMission(userId, spot)
            .map(UnlockedMissionResponse::from)
            .orElse(null);

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
