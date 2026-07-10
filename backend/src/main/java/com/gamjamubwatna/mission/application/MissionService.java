package com.gamjamubwatna.mission.application;

import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.mission.api.MissionCompleteResponse;
import com.gamjamubwatna.mission.api.MissionItemResponse;
import com.gamjamubwatna.mission.api.MissionListResponse;
import com.gamjamubwatna.mission.api.MissionVerifyRequest;
import com.gamjamubwatna.mission.api.MissionVerifyResponse;
import com.gamjamubwatna.mission.domain.Mission;
import com.gamjamubwatna.mission.domain.MissionRepository;
import com.gamjamubwatna.mission.domain.MissionStatus;
import com.gamjamubwatna.mission.domain.MissionVerificationPolicy;
import com.gamjamubwatna.mission.domain.MissionVerificationPolicyRepository;
import com.gamjamubwatna.mission.domain.UserMission;
import com.gamjamubwatna.mission.domain.UserMissionRepository;
import java.time.Clock;
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

    private final MissionRepository missionRepository;
    private final MissionVerificationPolicyRepository missionVerificationPolicyRepository;
    private final UserMissionRepository userMissionRepository;
    private final UserRepository userRepository;
    private final Clock clock;

    @Autowired
    public MissionService(
        MissionRepository missionRepository,
        MissionVerificationPolicyRepository missionVerificationPolicyRepository,
        UserMissionRepository userMissionRepository,
        UserRepository userRepository
    ) {
        this(
            missionRepository,
            missionVerificationPolicyRepository,
            userMissionRepository,
            userRepository,
            Clock.systemUTC()
        );
    }

    MissionService(
        MissionRepository missionRepository,
        MissionVerificationPolicyRepository missionVerificationPolicyRepository,
        UserMissionRepository userMissionRepository,
        UserRepository userRepository,
        Clock clock
    ) {
        this.missionRepository = missionRepository;
        this.missionVerificationPolicyRepository = missionVerificationPolicyRepository;
        this.userMissionRepository = userMissionRepository;
        this.userRepository = userRepository;
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
    public MissionCompleteResponse completeMission(Long userId, Long missionId) {
        User user = user(userId);
        Mission mission = mission(missionId);
        if (!mission.isActive() || mission.getDefaultStatus() == MissionStatus.LOCKED) {
            throw new MissionCompletionException("아직 완료할 수 없는 미션입니다.");
        }
        if (userMissionRepository.existsByUserIdAndMissionId(userId, missionId)) {
            throw new MissionAlreadyCompletedException("이미 완료한 미션입니다.");
        }

        Instant completedAt = Instant.now(clock);
        UserMission userMission = userMissionRepository.save(new UserMission(
            user,
            mission,
            completedAt
        ));

        return new MissionCompleteResponse(
            mission.getId(),
            true,
            userMission.getCompletedAt(),
            mission.getRewardType(),
            mission.getRewardLabel()
        );
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
        validateMissionInput(mission, request);

        Instant completedAt = Instant.now(clock);
        UserMission userMission = userMissionRepository.save(new UserMission(
            user,
            mission,
            completedAt
        ));

        return new MissionVerifyResponse(
            mission.getId(),
            true,
            true,
            userMission.getCompletedAt(),
            mission.getRewardType(),
            mission.getRewardLabel()
        );
    }

    private void validateCompletionTarget(Long userId, Mission mission) {
        if (!mission.isActive() || mission.getDefaultStatus() == MissionStatus.LOCKED) {
            throw new MissionCompletionException("아직 완료할 수 없는 미션입니다.");
        }
        if (userMissionRepository.existsByUserIdAndMissionId(userId, mission.getId())) {
            throw new MissionAlreadyCompletedException("이미 완료한 미션입니다.");
        }
    }

    private void validateMissionInput(Mission mission, MissionVerifyRequest request) {
        if (request == null || request.type() == null) {
            throw new MissionVerificationException("미션 인증 정보를 확인해주세요.");
        }
        if (request.type() != mission.getType()) {
            throw new MissionVerificationException("미션 타입이 일치하지 않습니다.");
        }

        switch (mission.getType()) {
            case QUIZ -> validateQuiz(verificationPolicy(mission), request.answer());
            case VISIT_AND_STEP -> validateStep(verificationPolicy(mission), request.stepCount());
            case PHOTO, PHOTO_OCR -> validatePhoto(verificationPolicy(mission), request.uploadKey());
            case QR_SCAN -> validateQrCode(verificationPolicy(mission), request.qrCode());
            default -> {
                // 위치/스탬프/수집형은 외부 센서 연동 전까지 활성 상태와 중복 완료 여부만 서버에서 확인한다.
            }
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

    private void validateStep(MissionVerificationPolicy policy, Integer stepCount) {
        Integer minStepCount = policy.getMinStepCount();
        if (minStepCount == null) {
            throw new MissionVerificationException("미션 걸음 수 정책을 확인할 수 없습니다.");
        }
        if (stepCount == null || stepCount < minStepCount) {
            throw new MissionVerificationException("걸음을 다 채우고 재시도해주세요.");
        }
    }

    private void validatePhoto(MissionVerificationPolicy policy, String uploadKey) {
        if (policy.isRequiredUpload()) {
            validateRequiredText(uploadKey, "이미지를 업로드한 뒤 다시 시도해주세요.");
        }
    }

    private void validateQrCode(MissionVerificationPolicy policy, String qrCode) {
        validateRequiredText(qrCode, "QR 코드를 스캔한 뒤 다시 시도해주세요.");
        String expectedQrCode = policy.getExpectedQrCode();
        if (expectedQrCode == null || expectedQrCode.isBlank()) {
            throw new MissionVerificationException("미션 QR 정책을 확인할 수 없습니다.");
        }
        if (!expectedQrCode.equals(qrCode)) {
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
