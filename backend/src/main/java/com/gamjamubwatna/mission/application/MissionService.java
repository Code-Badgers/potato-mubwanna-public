package com.gamjamubwatna.mission.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.coupon.domain.Coupon;
import com.gamjamubwatna.coupon.domain.CouponRepository;
import com.gamjamubwatna.coupon.domain.UserCoupon;
import com.gamjamubwatna.coupon.domain.UserCouponRepository;
import com.gamjamubwatna.coupon.domain.UserCouponStatus;
import com.gamjamubwatna.mission.api.MissionItemResponse;
import com.gamjamubwatna.mission.api.MissionListResponse;
import com.gamjamubwatna.mission.api.MissionVerifyRequest;
import com.gamjamubwatna.mission.api.MissionVerifyResponse;
import com.gamjamubwatna.mission.domain.Mission;
import com.gamjamubwatna.mission.domain.MissionGroup;
import com.gamjamubwatna.mission.domain.MissionPeriod;
import com.gamjamubwatna.mission.domain.MissionRepository;
import com.gamjamubwatna.mission.domain.MissionRewardType;
import com.gamjamubwatna.mission.domain.MissionStatus;
import com.gamjamubwatna.mission.domain.MissionVerificationPolicy;
import com.gamjamubwatna.mission.domain.MissionVerificationPolicyRepository;
import com.gamjamubwatna.mission.domain.UserMission;
import com.gamjamubwatna.mission.domain.UserMissionRepository;
import com.gamjamubwatna.reward.domain.RewardHistory;
import com.gamjamubwatna.reward.domain.RewardHistoryRepository;
import com.gamjamubwatna.reward.domain.RewardSourceType;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.spot.domain.TouristSpotRepository;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class MissionService {

    private static final String MISSION_UPLOAD_KEY_PREFIX = "mission-uploads/";

    private final MissionRepository missionRepository;
    private final MissionVerificationPolicyRepository missionVerificationPolicyRepository;
    private final UserMissionRepository userMissionRepository;
    private final RewardHistoryRepository rewardHistoryRepository;
    private final CouponRepository couponRepository;
    private final UserCouponRepository userCouponRepository;
    private final UserRepository userRepository;
    private final MissionEvidenceValidator missionEvidenceValidator;
    private final MissionPhotoStorage missionPhotoStorage;
    private final MissionPhotoTextReader missionPhotoTextReader;
    private final TouristSpotRepository touristSpotRepository;
    private final Clock clock;

    @Autowired
    public MissionService(
        MissionRepository missionRepository,
        MissionVerificationPolicyRepository missionVerificationPolicyRepository,
        UserMissionRepository userMissionRepository,
        RewardHistoryRepository rewardHistoryRepository,
        CouponRepository couponRepository,
        UserCouponRepository userCouponRepository,
        UserRepository userRepository,
        MissionEvidenceValidator missionEvidenceValidator,
        MissionPhotoStorage missionPhotoStorage,
        MissionPhotoTextReader missionPhotoTextReader,
        TouristSpotRepository touristSpotRepository
    ) {
        this(
            missionRepository,
            missionVerificationPolicyRepository,
            userMissionRepository,
            rewardHistoryRepository,
            couponRepository,
            userCouponRepository,
            userRepository,
            missionEvidenceValidator,
            missionPhotoStorage,
            missionPhotoTextReader,
            touristSpotRepository,
            Clock.systemUTC()
        );
    }

    MissionService(
        MissionRepository missionRepository,
        MissionVerificationPolicyRepository missionVerificationPolicyRepository,
        UserMissionRepository userMissionRepository,
        RewardHistoryRepository rewardHistoryRepository,
        CouponRepository couponRepository,
        UserCouponRepository userCouponRepository,
        UserRepository userRepository,
        MissionEvidenceValidator missionEvidenceValidator,
        MissionPhotoStorage missionPhotoStorage,
        MissionPhotoTextReader missionPhotoTextReader,
        TouristSpotRepository touristSpotRepository,
        Clock clock
    ) {
        this.missionRepository = missionRepository;
        this.missionVerificationPolicyRepository = missionVerificationPolicyRepository;
        this.userMissionRepository = userMissionRepository;
        this.rewardHistoryRepository = rewardHistoryRepository;
        this.couponRepository = couponRepository;
        this.userCouponRepository = userCouponRepository;
        this.userRepository = userRepository;
        this.missionEvidenceValidator = missionEvidenceValidator;
        this.missionPhotoStorage = missionPhotoStorage;
        this.missionPhotoTextReader = missionPhotoTextReader;
        this.touristSpotRepository = touristSpotRepository;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public MissionListResponse getMissions(Long userId) {
        validateUser(userId);

        Instant now = Instant.now(clock);
        List<Mission> missions = missionRepository.findAllByOrderByDisplayOrderAsc();
        Map<Long, MissionPeriod> periodsByMissionId = missions.stream()
            .collect(Collectors.toMap(
                Mission::getId,
                mission -> MissionPeriod.current(mission, now)
            ));
        Set<String> currentPeriodKeys = periodsByMissionId.values()
            .stream()
            .filter(MissionPeriod::available)
            .map(MissionPeriod::key)
            .collect(Collectors.toSet());
        List<UserMission> currentCompletions = currentPeriodKeys.isEmpty()
            ? List.of()
            : userMissionRepository.findByUserIdAndCompletionPeriodIn(
                userId,
                currentPeriodKeys
            );
        Map<CompletionKey, UserMission> completions = currentCompletions.stream()
            .collect(Collectors.toMap(
                userMission -> new CompletionKey(
                    userMission.getMission().getId(),
                    userMission.getCompletionPeriod()
                ),
                userMission -> userMission
            ));
        List<MissionItemResponse> items = missions.stream()
            .map(mission -> missionItem(
                userId,
                mission,
                periodsByMissionId.get(mission.getId()),
                completions
            ))
            .toList();

        return new MissionListResponse(
            items.size(),
            (int) items.stream().filter(MissionItemResponse::completed).count(),
            items
        );
    }

    @Transactional(readOnly = true)
    public MissionItemResponse getMission(Long userId, Long missionId) {
        validateUser(userId);
        Mission mission = mission(missionId);
        Instant now = Instant.now(clock);
        MissionPeriod period = MissionPeriod.current(mission, now);
        UserMission userMission = findCompletion(userId, mission, period);
        return missionItem(userId, mission, period, userMission);
    }

    @Transactional
    public MissionVerifyResponse verifyMission(
        Long userId,
        Long missionId,
        MissionVerifyRequest request
    ) {
        User user = user(userId);
        Mission mission = mission(missionId);
        Instant completedAt = Instant.now(clock);
        MissionPeriod period = MissionPeriod.current(mission, completedAt);
        validateCompletionTarget(userId, mission, period);
        String evidenceUploadKey = validateMissionInput(userId, mission, request, period);
        TouristSpot evidenceSpot = evidenceUploadKey == null
            ? null
            : touristSpotRepository.findFirstByNameAndCityNameAndActiveTrueOrderByIdAsc(
                mission.getSpotName(),
                mission.getCityName()
            ).orElse(null);

        UserMission userMission = userMissionRepository.save(new UserMission(
            user,
            mission,
            completedAt,
            period.key(),
            evidenceUploadKey,
            evidenceSpot
        ));
        saveMissionRewardHistory(user, mission, period, completedAt);

        return new MissionVerifyResponse(
            mission.getId(),
            true,
            true,
            userMission.getCompletedAt(),
            mission.getRewardType(),
            mission.getRewardLabel()
        );
    }

    private void saveMissionRewardHistory(
        User user,
        Mission mission,
        MissionPeriod period,
        Instant completedAt
    ) {
        // 완료 기록, 보상 이력, 쿠폰 발급을 한 트랜잭션에 묶어 일부만 남는 상태를 막는다.
        rewardHistoryRepository.save(new RewardHistory(
            user,
            mission.getRewardType(),
            mission.getRewardLabel(),
            RewardSourceType.MISSION,
            mission.getId(),
            period.key(),
            completedAt
        ));
        issueCouponReward(user, mission, completedAt);
    }

    private void issueCouponReward(User user, Mission mission, Instant completedAt) {
        if (mission.getRewardType() != MissionRewardType.COUPON) {
            return;
        }
        Long rewardCouponId = mission.getRewardCouponId();
        if (rewardCouponId == null) {
            throw new MissionCompletionException("미션 쿠폰 보상 매핑을 찾을 수 없습니다.");
        }
        Coupon coupon = couponRepository.findById(rewardCouponId)
            .orElseThrow(() -> new MissionCompletionException("미션 쿠폰 정보를 찾을 수 없습니다."));
        Instant expiresAt = completedAt.plus(Duration.ofDays(coupon.getValidDays()));
        userCouponRepository.save(new UserCoupon(
            user,
            coupon,
            UserCouponStatus.AVAILABLE,
            completedAt,
            expiresAt,
            null
        ));
    }

    private void validateCompletionTarget(
        Long userId,
        Mission mission,
        MissionPeriod period
    ) {
        if (!isAvailable(mission, period)) {
            throw new MissionCompletionException("아직 완료할 수 없는 미션입니다.");
        }
        if (completionExists(userId, mission, period)) {
            throw new MissionAlreadyCompletedException("이미 완료한 미션입니다.");
        }
    }

    private String validateMissionInput(
        Long userId,
        Mission mission,
        MissionVerifyRequest request,
        MissionPeriod period
    ) {
        if (request == null || request.type() == null) {
            throw new MissionVerificationException("미션 인증 정보를 확인해주세요.");
        }
        if (request.type() != mission.getType()) {
            throw new MissionVerificationException("미션 타입이 일치하지 않습니다.");
        }

        return switch (mission.getType()) {
            case QUIZ -> {
                validateQuiz(verificationPolicy(mission), request.answer());
                yield null;
            }
            case VISIT_AND_STEP -> {
                missionEvidenceValidator.validate(
                    userId,
                    mission,
                    verificationPolicy(mission),
                    period
                );
                yield null;
            }
            case PHOTO -> {
                StoredMissionPhotoFile photoFile = validatePhoto(
                    userId,
                    mission,
                    verificationPolicy(mission),
                    request.uploadKey()
                );
                yield photoFile == null ? null : photoFile.uploadKey();
            }
            case PHOTO_OCR -> validatePhotoOcr(
                userId,
                mission,
                verificationPolicy(mission),
                request.uploadKey()
            ).uploadKey();
            case QR_SCAN -> {
                validateQrCode(verificationPolicy(mission), request.qrCode());
                yield null;
            }
            case VISIT, STAMP, COLLECTION -> {
                missionEvidenceValidator.validate(userId, mission, null, period);
                yield null;
            }
        };
    }

    private MissionItemResponse missionItem(
        Long userId,
        Mission mission,
        MissionPeriod period,
        Map<CompletionKey, UserMission> completions
    ) {
        UserMission userMission = period.available()
            ? completions.get(new CompletionKey(mission.getId(), period.key()))
            : null;
        return missionItem(userId, mission, period, userMission);
    }

    private MissionItemResponse missionItem(
        Long userId,
        Mission mission,
        MissionPeriod period,
        UserMission userMission
    ) {
        boolean available = isAvailable(mission, period);
        int progress = currentProgress(userId, mission, period, userMission, available);
        return MissionItemResponse.from(
            mission,
            userMission,
            period,
            progress,
            available
        );
    }

    private int currentProgress(
        Long userId,
        Mission mission,
        MissionPeriod period,
        UserMission userMission,
        boolean available
    ) {
        if (userMission != null) {
            return mission.getTarget();
        }
        if (!available) {
            return 0;
        }
        if (mission.getGroup() == MissionGroup.JUMSOONI) {
            return mission.getProgress();
        }
        return missionEvidenceValidator.progress(userId, mission, period);
    }

    private boolean isAvailable(Mission mission, MissionPeriod period) {
        return mission.isActive()
            && mission.getDefaultStatus() != MissionStatus.LOCKED
            && period.available();
    }

    private boolean completionExists(
        Long userId,
        Mission mission,
        MissionPeriod period
    ) {
        if (period.isOneTime()) {
            return userMissionRepository.existsByUserIdAndMissionId(userId, mission.getId());
        }
        return userMissionRepository.existsByUserIdAndMissionIdAndCompletionPeriod(
            userId,
            mission.getId(),
            period.key()
        );
    }

    private UserMission findCompletion(
        Long userId,
        Mission mission,
        MissionPeriod period
    ) {
        if (!period.available()) {
            return null;
        }
        if (period.isOneTime()) {
            return userMissionRepository.findByUserIdAndMissionId(userId, mission.getId())
                .orElse(null);
        }
        return userMissionRepository.findByUserIdAndMissionIdAndCompletionPeriod(
            userId,
            mission.getId(),
            period.key()
        ).orElse(null);
    }

    private MissionVerificationPolicy verificationPolicy(Mission mission) {
        MissionVerificationPolicy policy = missionVerificationPolicyRepository.findByMissionId(mission.getId())
            .orElseThrow(() -> new MissionVerificationException("미션 검증 정책을 찾을 수 없습니다."));
        if (policy.getVerificationType() != mission.getType()) {
            throw new MissionVerificationException("미션 검증 정책이 일치하지 않습니다.");
        }
        return policy;
    }

    private void validateQuiz(MissionVerificationPolicy policy, String answer) {
        String expectedAnswer = policy.getExpectedAnswer();
        if (expectedAnswer == null || expectedAnswer.isBlank()) {
            throw new MissionVerificationException("미션 정답 정책을 확인할 수 없습니다.");
        }
        if (!expectedAnswer.equals(answer)) {
            throw new MissionVerificationException("정답이 틀렸습니다. 다시 풀어주세요.");
        }
    }

    private StoredMissionPhotoFile validatePhoto(
        Long userId,
        Mission mission,
        MissionVerificationPolicy policy,
        String uploadKey
    ) {
        if (policy.isRequiredUpload()) {
            validateRequiredText(uploadKey, "이미지를 업로드한 뒤 다시 시도해주세요.");
            String ownedUploadPrefix = MISSION_UPLOAD_KEY_PREFIX
                + userId
                + "/"
                + mission.getId()
                + "/";
            if (!uploadKey.startsWith(ownedUploadPrefix)) {
                throw new MissionVerificationException("서버에서 발급한 업로드 키를 확인해주세요.");
            }
            try {
                return missionPhotoStorage.read(uploadKey);
            } catch (MissionUploadException exception) {
                throw new MissionVerificationException(exception.getMessage());
            }
        }
        return null;
    }

    private StoredMissionPhotoFile validatePhotoOcr(
        Long userId,
        Mission mission,
        MissionVerificationPolicy policy,
        String uploadKey
    ) {
        StoredMissionPhotoFile photoFile = validatePhoto(userId, mission, policy, uploadKey);
        String expectedKeyword = policy.getExpectedAnswer();
        if (expectedKeyword == null || expectedKeyword.isBlank()) {
            throw new MissionVerificationException("미션 OCR 정책을 확인할 수 없습니다.");
        }
        if (photoFile == null) {
            throw new MissionVerificationException("업로드된 이미지를 찾을 수 없습니다.");
        }
        String recognizedText = missionPhotoTextReader.readText(photoFile);
        if (recognizedText == null || !recognizedText.contains(expectedKeyword)) {
            throw new MissionVerificationException("인증 이미지에서 미션 키워드를 찾지 못했습니다.");
        }
        return photoFile;
    }

    private void validateQrCode(MissionVerificationPolicy policy, String qrCode) {
        validateRequiredText(qrCode, "QR 코드를 스캔한 뒤 다시 시도해주세요.");
        String expectedQrCode = policy.getExpectedQrCode();
        if (expectedQrCode == null || expectedQrCode.isBlank()) {
            throw new MissionVerificationException("미션 QR 정책을 확인할 수 없습니다.");
        }
        if (!expectedQrCode.trim().equals(qrCode.trim())) {
            throw new MissionVerificationException("올바르지 않은 QR 코드입니다.");
        }
    }

    private void validateRequiredText(String value, String message) {
        if (value == null || value.isBlank()) {
            throw new MissionVerificationException(message);
        }
    }

    private void validateUser(Long userId) {
        if (!userRepository.existsById(userId)) {
            throw new MissionAuthenticationException("사용자를 찾을 수 없습니다.");
        }
    }

    private User user(Long userId) {
        return userRepository.findById(userId)
            .orElseThrow(() -> new MissionAuthenticationException("사용자를 찾을 수 없습니다."));
    }

    private Mission mission(Long missionId) {
        return missionRepository.findById(missionId)
            .orElseThrow(() -> new MissionNotFoundException("미션을 찾을 수 없습니다."));
    }

    private record CompletionKey(Long missionId, String completionPeriod) {
    }
}
