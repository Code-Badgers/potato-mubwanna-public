package com.gamjamubwatna.mission.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.AuthProvider;
import com.gamjamubwatna.auth.domain.User;
import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.coupon.domain.Coupon;
import com.gamjamubwatna.coupon.domain.CouponDisplayStatus;
import com.gamjamubwatna.coupon.domain.CouponRepository;
import com.gamjamubwatna.coupon.domain.UserCoupon;
import com.gamjamubwatna.coupon.domain.UserCouponRepository;
import com.gamjamubwatna.mission.api.MissionCompleteResponse;
import com.gamjamubwatna.mission.api.MissionItemResponse;
import com.gamjamubwatna.mission.api.MissionListResponse;
import com.gamjamubwatna.mission.api.MissionVerifyRequest;
import com.gamjamubwatna.mission.api.MissionVerifyResponse;
import com.gamjamubwatna.mission.domain.Mission;
import com.gamjamubwatna.mission.domain.MissionGroup;
import com.gamjamubwatna.mission.domain.MissionRepository;
import com.gamjamubwatna.mission.domain.MissionRewardType;
import com.gamjamubwatna.mission.domain.MissionStatus;
import com.gamjamubwatna.mission.domain.MissionType;
import com.gamjamubwatna.mission.domain.MissionVerificationPolicy;
import com.gamjamubwatna.mission.domain.MissionVerificationPolicyRepository;
import com.gamjamubwatna.mission.domain.UserMission;
import com.gamjamubwatna.mission.domain.UserMissionRepository;
import com.gamjamubwatna.reward.domain.RewardHistory;
import com.gamjamubwatna.reward.domain.RewardHistoryRepository;
import com.gamjamubwatna.reward.domain.RewardSourceType;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import org.mockito.ArgumentCaptor;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

@ExtendWith(MockitoExtension.class)
class MissionServiceTest {

    @Mock
    private MissionRepository missionRepository;

    @Mock
    private MissionVerificationPolicyRepository missionVerificationPolicyRepository;

    @Mock
    private UserMissionRepository userMissionRepository;

    @Mock
    private RewardHistoryRepository rewardHistoryRepository;

    @Mock
    private CouponRepository couponRepository;

    @Mock
    private UserCouponRepository userCouponRepository;

    @Mock
    private UserRepository userRepository;

    private FakeMissionPhotoStorage missionPhotoStorage;
    private MissionPhotoTextReader missionPhotoTextReader;
    private MissionService missionService;

    @BeforeEach
    void setUp() {
        missionPhotoStorage = new FakeMissionPhotoStorage();
        missionPhotoTextReader = photoFile -> new String(photoFile.bytes());
        missionService = new MissionService(
            missionRepository,
            missionVerificationPolicyRepository,
            userMissionRepository,
            rewardHistoryRepository,
            couponRepository,
            userCouponRepository,
            userRepository,
            missionPhotoStorage,
            missionPhotoTextReader,
            Clock.fixed(Instant.parse("2026-07-01T00:00:00Z"), ZoneOffset.UTC)
        );
    }

    @Test
    void returnsMissionsWithUserCompletionState() {
        Mission first = mission(1L, "MISSION_FIRST", MissionStatus.READY, true);
        Mission second = mission(2L, "MISSION_SECOND", MissionStatus.IN_PROGRESS, true);
        UserMission completed = new UserMission(
            user(1L),
            first,
            Instant.parse("2026-07-01T00:00:00Z")
        );
        when(userRepository.existsById(1L)).thenReturn(true);
        when(missionRepository.findAllByOrderByDisplayOrderAsc()).thenReturn(List.of(first, second));
        when(userMissionRepository.findByUserId(1L)).thenReturn(List.of(completed));

        MissionListResponse result = missionService.getMissions(1L);

        assertThat(result.totalCount()).isEqualTo(2);
        assertThat(result.completedCount()).isEqualTo(1);
        assertThat(result.missions().getFirst().completed()).isTrue();
        assertThat(result.missions().getFirst().status()).isEqualTo(MissionStatus.COMPLETED);
        assertThat(result.missions().get(1).completed()).isFalse();
        assertThat(result.missions().get(1).status()).isEqualTo(MissionStatus.IN_PROGRESS);
    }

    @Test
    void returnsMissionDetail() {
        Mission mission = mission(1L, "MISSION_FIRST", MissionStatus.READY, true);
        when(userRepository.existsById(1L)).thenReturn(true);
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.findByUserIdAndMissionId(1L, 1L)).thenReturn(Optional.empty());

        MissionItemResponse result = missionService.getMission(1L, 1L);

        assertThat(result.missionId()).isEqualTo(1L);
        assertThat(result.code()).isEqualTo("MISSION_FIRST");
        assertThat(result.completed()).isFalse();
    }

    @Test
    void completesActiveMission() {
        User user = user(1L);
        Mission mission = mission(1L, "MISSION_FIRST", MissionStatus.READY, true);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(userMissionRepository.save(any(UserMission.class))).thenAnswer(invocation -> invocation.getArgument(0));

        MissionCompleteResponse result = missionService.completeMission(1L, 1L);

        assertThat(result.completed()).isTrue();
        assertThat(result.completedAt()).isEqualTo(Instant.parse("2026-07-01T00:00:00Z"));
        assertThat(result.rewardType()).isEqualTo(MissionRewardType.ITEM);
        verify(userMissionRepository).save(any(UserMission.class));
        ArgumentCaptor<RewardHistory> rewardCaptor = ArgumentCaptor.forClass(RewardHistory.class);
        verify(rewardHistoryRepository).save(rewardCaptor.capture());
        assertMissionRewardHistory(rewardCaptor.getValue(), mission);
    }

    @Test
    void verifiesQuizMissionBeforeCompletion() {
        User user = user(1L);
        Mission mission = mission(1L, "MISSION_FIRST", MissionStatus.READY, true);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(quizPolicy(mission, "곤드레감자")));
        when(userMissionRepository.save(any(UserMission.class))).thenAnswer(invocation -> invocation.getArgument(0));

        MissionVerifyResponse result = missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.QUIZ, "곤드레감자", null, null, null)
        );

        assertThat(result.verified()).isTrue();
        assertThat(result.completed()).isTrue();
        assertThat(result.rewardLabel()).isEqualTo("황금감자 성장 아이템");
        ArgumentCaptor<RewardHistory> rewardCaptor = ArgumentCaptor.forClass(RewardHistory.class);
        verify(rewardHistoryRepository).save(rewardCaptor.capture());
        assertMissionRewardHistory(rewardCaptor.getValue(), mission);
    }

    @Test
    void rejectsWrongQuizAnswer() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(
            mission(1L, "MISSION_FIRST", MissionStatus.READY, true)
        ));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(quizPolicy(
                mission(1L, "MISSION_FIRST", MissionStatus.READY, true),
                "곤드레감자"
            )));

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.QUIZ, "옥수수감자", null, null, null)
        ))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("정답이 틀렸습니다. 다시 풀어주세요.");
    }

    @Test
    void rejectsInsufficientStepCount() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(
            mission(1L, "MISSION_STEP", MissionStatus.READY, true, MissionType.VISIT_AND_STEP)
        ));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(stepPolicy(
                mission(1L, "MISSION_STEP", MissionStatus.READY, true, MissionType.VISIT_AND_STEP),
                1000
            )));

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.VISIT_AND_STEP, null, 0, null, null)
        ))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("걸음을 다 채우고 재시도해주세요.");
    }

    @Test
    void rejectsMissingStepPolicy() {
        Mission mission = mission(1L, "MISSION_STEP", MissionStatus.READY, true, MissionType.VISIT_AND_STEP);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(stepPolicy(mission, null)));

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.VISIT_AND_STEP, null, 1000, null, null)
        ))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("미션 걸음 수 정책을 확인할 수 없습니다.");
    }

    @Test
    void rejectsWrongQrCodeFromPolicy() {
        Mission mission = mission(1L, "MISSION_QR", MissionStatus.READY, true, MissionType.QR_SCAN);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(qrPolicy(mission, "expected-qr")));

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.QR_SCAN, null, null, null, "wrong-qr")
        ))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("올바르지 않은 QR 코드입니다.");
    }

    @Test
    void rejectsPhotoMissionWithoutRequiredUpload() {
        Mission mission = mission(1L, "MISSION_PHOTO", MissionStatus.READY, true, MissionType.PHOTO);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(uploadPolicy(mission)));

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.PHOTO, null, null, null, null)
        ))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("이미지를 업로드한 뒤 다시 시도해주세요.");
    }

    @Test
    void rejectsPhotoMissionWithLocalUploadKey() {
        Mission mission = mission(1L, "MISSION_PHOTO", MissionStatus.READY, true, MissionType.PHOTO);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(uploadPolicy(mission)));

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.PHOTO, null, null, "local:1:camera:image.jpg", null)
        ))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("서버에서 발급한 업로드 키를 확인해주세요.");
    }

    @Test
    void verifiesPhotoOcrMissionWhenRecognizedTextContainsExpectedKeyword() {
        User user = user(1L);
        Mission mission = mission(1L, "MISSION_PHOTO_OCR", MissionStatus.READY, true, MissionType.PHOTO_OCR);
        String uploadKey = "mission-uploads/1/1/test-receipt.jpg";
        missionPhotoStorage.put(uploadKey, "안목 커피거리 영수증 하지감자".getBytes());
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(uploadPolicy(mission, "하지감자")));
        when(userMissionRepository.save(any(UserMission.class))).thenAnswer(invocation -> invocation.getArgument(0));

        MissionVerifyResponse result = missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.PHOTO_OCR, null, null, uploadKey, null)
        );

        assertThat(result.verified()).isTrue();
        assertThat(result.completed()).isTrue();
    }

    @Test
    void rejectsPhotoOcrMissionWhenKeywordIsMissing() {
        Mission mission = mission(1L, "MISSION_PHOTO_OCR", MissionStatus.READY, true, MissionType.PHOTO_OCR);
        String uploadKey = "mission-uploads/1/1/test-receipt.jpg";
        missionPhotoStorage.put(uploadKey, "안목 커피거리 영수증".getBytes());
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(uploadPolicy(mission, "하지감자")));

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.PHOTO_OCR, null, null, uploadKey, null)
        ))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("인증 이미지에서 미션 키워드를 찾지 못했습니다.");
    }

    @Test
    void rejectsPhotoOcrMissionWhenUploadKeyDoesNotExist() {
        Mission mission = mission(1L, "MISSION_PHOTO_OCR", MissionStatus.READY, true, MissionType.PHOTO_OCR);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(uploadPolicy(mission, "하지감자")));

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.PHOTO_OCR, null, null, "mission-uploads/1/1/missing.jpg", null)
        ))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("업로드된 이미지를 찾을 수 없습니다.");
    }

    @Test
    void rejectsDuplicateCompletion() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(
            mission(1L, "MISSION_FIRST", MissionStatus.READY, true)
        ));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(true);

        assertThatThrownBy(() -> missionService.completeMission(1L, 1L))
            .isInstanceOf(MissionAlreadyCompletedException.class);
        verifyNoInteractions(rewardHistoryRepository);
        verifyNoInteractions(userCouponRepository);
    }

    @Test
    void issuesCouponForCouponRewardMission() {
        User user = user(1L);
        Mission mission = mission(1L, "MISSION_COUPON", MissionStatus.READY, true);
        ReflectionTestUtils.setField(mission, "rewardType", MissionRewardType.COUPON);
        ReflectionTestUtils.setField(mission, "rewardCouponId", 7L);
        Coupon coupon = new Coupon(
            "CP_TEST",
            "감자 쿠폰",
            "테스트 쿠폰",
            3000,
            "테스트 제휴점",
            30
        );
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(userMissionRepository.save(any(UserMission.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(couponRepository.findById(7L)).thenReturn(Optional.of(coupon));

        missionService.completeMission(1L, 1L);

        ArgumentCaptor<UserCoupon> couponCaptor = ArgumentCaptor.forClass(UserCoupon.class);
        verify(userCouponRepository).save(couponCaptor.capture());
        UserCoupon issuedCoupon = couponCaptor.getValue();
        assertThat(issuedCoupon.getCoupon()).isSameAs(coupon);
        assertThat(issuedCoupon.getIssuedAt()).isEqualTo(Instant.parse("2026-07-01T00:00:00Z"));
        assertThat(issuedCoupon.getExpiresAt()).isEqualTo(Instant.parse("2026-07-31T00:00:00Z"));
        assertThat(issuedCoupon.displayStatus(Instant.parse("2026-07-01T00:00:00Z")))
            .isEqualTo(CouponDisplayStatus.AVAILABLE);
    }

    @Test
    void rejectsCouponRewardWithoutCouponMapping() {
        User user = user(1L);
        Mission mission = mission(1L, "MISSION_COUPON", MissionStatus.READY, true);
        ReflectionTestUtils.setField(mission, "rewardType", MissionRewardType.COUPON);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(userMissionRepository.save(any(UserMission.class))).thenAnswer(invocation -> invocation.getArgument(0));

        assertThatThrownBy(() -> missionService.completeMission(1L, 1L))
            .isInstanceOf(MissionCompletionException.class)
            .hasMessage("미션 쿠폰 보상 매핑을 찾을 수 없습니다.");
        verifyNoInteractions(couponRepository, userCouponRepository);
    }

    @Test
    void rejectsInactiveMissionCompletion() {
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(
            mission(1L, "MISSION_LOCKED", MissionStatus.LOCKED, false)
        ));

        assertThatThrownBy(() -> missionService.completeMission(1L, 1L))
            .isInstanceOf(MissionCompletionException.class);
    }

    @Test
    void rejectsDeletedUser() {
        when(userRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> missionService.getMissions(99L))
            .isInstanceOf(MissionAuthenticationException.class);
    }

    private Mission mission(Long id, String code, MissionStatus status, boolean active) {
        return mission(id, code, status, active, MissionType.QUIZ);
    }

    private Mission mission(
        Long id,
        String code,
        MissionStatus status,
        boolean active,
        MissionType type
    ) {
        Mission mission = new Mission(
            code,
            MissionGroup.JUMSOONI,
            type,
            status,
            "정선 5일장 곤드레 퀴즈",
            "정선 5일장",
            "정선군",
            "정선 장터 퀴즈",
            "여까지 왔네?",
            "퀴즈 1개 정답",
            MissionRewardType.ITEM,
            "황금감자 성장 아이템",
            0,
            1,
            true,
            active,
            id.intValue(),
            Instant.parse("2026-07-01T00:00:00Z")
        );
        ReflectionTestUtils.setField(mission, "id", id);
        return mission;
    }

    private User user(Long id) {
        User user = new User(
            AuthProvider.KAKAO,
            "kakao-" + id,
            null,
            "감자러버",
            null,
            Instant.parse("2026-07-01T00:00:00Z")
        );
        ReflectionTestUtils.setField(user, "id", id);
        return user;
    }

    private void assertMissionRewardHistory(RewardHistory rewardHistory, Mission mission) {
        assertThat(rewardHistory.getRewardType()).isEqualTo(mission.getRewardType());
        assertThat(rewardHistory.getRewardName()).isEqualTo(mission.getRewardLabel());
        assertThat(rewardHistory.getSourceType()).isEqualTo(RewardSourceType.MISSION);
        assertThat(rewardHistory.getSourceId()).isEqualTo(mission.getId());
        assertThat(rewardHistory.getCreatedAt()).isEqualTo(Instant.parse("2026-07-01T00:00:00Z"));
    }

    private MissionVerificationPolicy quizPolicy(Mission mission, String expectedAnswer) {
        return new MissionVerificationPolicy(
            mission,
            MissionType.QUIZ,
            expectedAnswer,
            null,
            false,
            null,
            Instant.parse("2026-07-01T00:00:00Z")
        );
    }

    private MissionVerificationPolicy stepPolicy(Mission mission, Integer minStepCount) {
        return new MissionVerificationPolicy(
            mission,
            MissionType.VISIT_AND_STEP,
            null,
            null,
            false,
            minStepCount,
            Instant.parse("2026-07-01T00:00:00Z")
        );
    }

    private MissionVerificationPolicy qrPolicy(Mission mission, String expectedQrCode) {
        return new MissionVerificationPolicy(
            mission,
            MissionType.QR_SCAN,
            null,
            expectedQrCode,
            false,
            null,
            Instant.parse("2026-07-01T00:00:00Z")
        );
    }

    private MissionVerificationPolicy uploadPolicy(Mission mission) {
        return uploadPolicy(mission, null);
    }

    private MissionVerificationPolicy uploadPolicy(Mission mission, String expectedKeyword) {
        return new MissionVerificationPolicy(
            mission,
            mission.getType(),
            expectedKeyword,
            null,
            true,
            null,
            Instant.parse("2026-07-01T00:00:00Z")
        );
    }

    private static class FakeMissionPhotoStorage implements MissionPhotoStorage {

        private final Map<String, byte[]> files = new HashMap<>();

        void put(String uploadKey, byte[] bytes) {
            files.put(uploadKey, bytes);
        }

        @Override
        public StoredMissionPhoto store(String uploadKey, String fileName, String contentType, org.springframework.web.multipart.MultipartFile file) {
            throw new UnsupportedOperationException("MissionServiceTest does not store files");
        }

        @Override
        public StoredMissionPhotoFile read(String uploadKey) {
            byte[] bytes = files.get(uploadKey);
            if (bytes == null) {
                throw new MissionUploadException("업로드된 이미지를 찾을 수 없습니다.");
            }
            return new StoredMissionPhotoFile(uploadKey, bytes);
        }
    }
}
