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
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
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
        MissionPhotoTextReader missionPhotoTextReader
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
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public MissionListResponse getMissions(Long userId) {
        validateUser(userId);

        List<Mission> missions = missionRepository.findAllByOrderByDisplayOrderAsc();
        Map<Long, UserMission> completedByMissionId = userMissionRepository.findByUserId(userId)
            .stream()
            .collect(Collectors.toMap(
                userMission -> userMission.getMission().getId(),
                Function.identity()
            ));
        List<MissionItemResponse> items = missions.stream()
            .map(mission -> MissionItemResponse.from(
                mission,
                completedByMissionId.get(mission.getId())
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
        UserMission userMission = userMissionRepository.findByUserIdAndMissionId(userId, missionId)
            .orElse(null);
        return MissionItemResponse.from(mission, userMission);
    }

    @Transactional
    public MissionVerifyResponse verifyMission(
        Long userId,
        Long missionId,
        MissionVerifyRequest request
    ) {
        User user = user(userId);
        Mission mission = mission(missionId);
        validateCompletionTarget(userId, mission);
        validateMissionInput(userId, mission, request);

        Instant completedAt = Instant.now(clock);
        UserMission userMission = userMissionRepository.save(new UserMission(
            user,
            mission,
            completedAt
        ));
        saveMissionRewardHistory(user, mission, completedAt);

        return new MissionVerifyResponse(
            mission.getId(),
            true,
            true,
            userMission.getCompletedAt(),
            mission.getRewardType(),
            mission.getRewardLabel()
        );
    }

    private void saveMissionRewardHistory(User user, Mission mission, Instant completedAt) {
        // 완료 기록, 보상 이력, 쿠폰 발급을 한 트랜잭션에 묶어 일부만 남는 상태를 막는다.
        rewardHistoryRepository.save(new RewardHistory(
            user,
            mission.getRewardType(),
            mission.getRewardLabel(),
            RewardSourceType.MISSION,
            mission.getId(),
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

    private void validateCompletionTarget(Long userId, Mission mission) {
        if (!mission.isActive() || mission.getDefaultStatus() == MissionStatus.LOCKED) {
            throw new MissionCompletionException("아직 완료할 수 없는 미션입니다.");
        }
        if (userMissionRepository.existsByUserIdAndMissionId(userId, mission.getId())) {
            throw new MissionAlreadyCompletedException("이미 완료한 미션입니다.");
        }
    }

    private void validateMissionInput(
        Long userId,
        Mission mission,
        MissionVerifyRequest request
    ) {
        if (request == null || request.type() == null) {
            throw new MissionVerificationException("미션 인증 정보를 확인해주세요.");
        }
        if (request.type() != mission.getType()) {
            throw new MissionVerificationException("미션 타입이 일치하지 않습니다.");
        }

        switch (mission.getType()) {
            case QUIZ -> validateQuiz(verificationPolicy(mission), request.answer());
            case VISIT_AND_STEP -> missionEvidenceValidator.validate(
                userId,
                mission,
                verificationPolicy(mission)
            );
            case PHOTO -> validatePhoto(
                userId,
                mission,
                verificationPolicy(mission),
                request.uploadKey()
            );
            case PHOTO_OCR -> validatePhotoOcr(
                userId,
                mission,
                verificationPolicy(mission),
                request.uploadKey()
            );
            case QR_SCAN -> validateQrCode(verificationPolicy(mission), request.qrCode());
            case VISIT, STAMP, COLLECTION ->
                missionEvidenceValidator.validate(userId, mission, null);
        }
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

    private void validatePhotoOcr(
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
}
