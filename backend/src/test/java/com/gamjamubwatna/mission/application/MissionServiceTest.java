package com.gamjamubwatna.mission.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.times;
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
import com.gamjamubwatna.legal.application.LocationUsageLogService;
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
import com.gamjamubwatna.mission.domain.MissionType;
import com.gamjamubwatna.mission.domain.MissionVerificationPolicy;
import com.gamjamubwatna.mission.domain.MissionVerificationPolicyRepository;
import com.gamjamubwatna.mission.domain.UserMission;
import com.gamjamubwatna.mission.domain.UserMissionRepository;
import com.gamjamubwatna.reward.domain.RewardHistory;
import com.gamjamubwatna.reward.domain.RewardHistoryRepository;
import com.gamjamubwatna.reward.domain.RewardSourceType;
import com.gamjamubwatna.push.application.PushEventPublisher;
import com.gamjamubwatna.push.application.PushNotificationMessage;
import com.gamjamubwatna.push.domain.PushDestination;
import com.gamjamubwatna.spot.domain.SpotCategory;
import com.gamjamubwatna.spot.domain.TouristSpot;
import com.gamjamubwatna.visit.application.VisitDistancePolicy;
import com.gamjamubwatna.visit.domain.UserVisit;
import com.gamjamubwatna.visit.domain.UserVisitRepository;
import java.math.BigDecimal;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
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

    @Mock
    private MissionEvidenceValidator missionEvidenceValidator;


    @Mock
    private UserVisitRepository userVisitRepository;

    @Mock
    private LocationUsageLogService locationUsageLogService;

    @Mock
    private PushEventPublisher pushEventPublisher;

    private FakeMissionPhotoStorage missionPhotoStorage;
    private MissionService missionService;

    @BeforeEach
    void setUp() {
        missionPhotoStorage = new FakeMissionPhotoStorage();
        missionService = new MissionService(
            missionRepository,
            missionVerificationPolicyRepository,
            userMissionRepository,
            rewardHistoryRepository,
            couponRepository,
            userCouponRepository,
            userRepository,
            missionEvidenceValidator,
            missionPhotoStorage,
            userVisitRepository,
            new VisitDistancePolicy(),
            locationUsageLogService,
            pushEventPublisher,
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
        when(userMissionRepository.findByUserIdAndCompletionPeriodIn(
            1L,
            Set.of(MissionPeriod.ONE_TIME_KEY)
        )).thenReturn(List.of(completed));

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
    void returnsOnlyCurrentDailyPeriodCompletionAndProgress() {
        Mission mission = mission(
            1L,
            "MISSION_DAILY",
            MissionStatus.READY,
            true,
            MissionGroup.DAILY,
            MissionType.STAMP
        );
        UserMission previousCompletion = new UserMission(
            user(1L),
            mission,
            Instant.parse("2026-06-30T00:00:00Z"),
            "DAY:2026-06-30"
        );
        when(userRepository.existsById(1L)).thenReturn(true);
        when(missionRepository.findAllByOrderByDisplayOrderAsc()).thenReturn(List.of(mission));
        when(userMissionRepository.findByUserIdAndCompletionPeriodIn(
            1L,
            Set.of("DAY:2026-07-01")
        )).thenReturn(List.of(previousCompletion));
        when(missionEvidenceValidator.progress(eq(1L), eq(mission), any(MissionPeriod.class)))
            .thenReturn(1);

        MissionListResponse result = missionService.getMissions(1L);

        MissionItemResponse item = result.missions().getFirst();
        assertThat(result.completedCount()).isZero();
        assertThat(item.completed()).isFalse();
        assertThat(item.progress()).isEqualTo(1);
        assertThat(item.periodStartsAt()).isEqualTo(Instant.parse("2026-06-30T15:00:00Z"));
        assertThat(item.periodEndsAt()).isEqualTo(Instant.parse("2026-07-01T15:00:00Z"));
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
        ArgumentCaptor<PushNotificationMessage> pushCaptor =
            ArgumentCaptor.forClass(PushNotificationMessage.class);
        verify(pushEventPublisher).publish(eq(1L), pushCaptor.capture());
        assertThat(pushCaptor.getValue().destination()).isEqualTo(PushDestination.MISSIONS);
        assertThat(pushCaptor.getValue().body()).contains(mission.getTitle());
    }

    @Test
    void completesSameDailyMissionAgainInNextPeriod() {
        User user = user(1L);
        Mission mission = mission(
            1L,
            "MISSION_DAILY_QUIZ",
            MissionStatus.READY,
            true,
            MissionGroup.DAILY,
            MissionType.QUIZ
        );
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionIdAndCompletionPeriod(
            1L,
            1L,
            "DAY:2026-07-01"
        )).thenReturn(false);
        when(userMissionRepository.existsByUserIdAndMissionIdAndCompletionPeriod(
            1L,
            1L,
            "DAY:2026-07-02"
        )).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(quizPolicy(mission, "곤드레감자")));
        when(userMissionRepository.save(any(UserMission.class)))
            .thenAnswer(invocation -> invocation.getArgument(0));

        MissionService dayOneService = missionService(Instant.parse("2026-07-01T00:00:00Z"));
        MissionService dayTwoService = missionService(Instant.parse("2026-07-02T00:00:00Z"));
        MissionVerifyRequest request = new MissionVerifyRequest(
            MissionType.QUIZ,
            "곤드레감자",
            null,
            null,
            null
        );

        dayOneService.verifyMission(1L, 1L, request);
        dayTwoService.verifyMission(1L, 1L, request);

        ArgumentCaptor<UserMission> completionCaptor = ArgumentCaptor.forClass(UserMission.class);
        verify(userMissionRepository, times(2)).save(completionCaptor.capture());
        assertThat(completionCaptor.getAllValues())
            .extracting(UserMission::getCompletionPeriod)
            .containsExactly("DAY:2026-07-01", "DAY:2026-07-02");

        ArgumentCaptor<RewardHistory> rewardCaptor = ArgumentCaptor.forClass(RewardHistory.class);
        verify(rewardHistoryRepository, times(2)).save(rewardCaptor.capture());
        assertThat(rewardCaptor.getAllValues())
            .extracting(RewardHistory::getSourcePeriod)
            .containsExactly("DAY:2026-07-01", "DAY:2026-07-02");
    }

    @Test
    void rejectsDuplicateCompletionInCurrentDailyPeriod() {
        Mission mission = mission(
            1L,
            "MISSION_DAILY_QUIZ",
            MissionStatus.READY,
            true,
            MissionGroup.DAILY,
            MissionType.QUIZ
        );
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionIdAndCompletionPeriod(
            1L,
            1L,
            "DAY:2026-07-01"
        )).thenReturn(true);

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.QUIZ, "곤드레감자", null, null, null)
        ))
            .isInstanceOf(MissionAlreadyCompletedException.class);
        verifyNoInteractions(rewardHistoryRepository);
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
        Mission mission = mission(
            1L,
            "MISSION_STEP",
            MissionStatus.READY,
            true,
            MissionType.VISIT_AND_STEP
        );
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(stepPolicy(mission, 1000)));
        doThrow(new MissionVerificationException(
            "동기화된 걸음 수가 미션 목표에 도달하지 않았습니다."
        )).when(missionEvidenceValidator).validate(
            eq(1L),
            eq(mission),
            any(MissionVerificationPolicy.class),
            any(MissionPeriod.class)
        );

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.VISIT_AND_STEP, null, 100_000, null, null)
        ))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("동기화된 걸음 수가 미션 목표에 도달하지 않았습니다.");
    }

    @Test
    void verifiesQrMissionWithExpectedCode() {
        User user = user(1L);
        Mission mission = mission(1L, "MISSION_QR", MissionStatus.READY, true, MissionType.QR_SCAN);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(qrPolicy(mission, "gamjamubwatna://mission/qr/MISSION_QR")));
        when(userMissionRepository.save(any(UserMission.class))).thenAnswer(invocation -> invocation.getArgument(0));

        MissionVerifyResponse result = missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(
                MissionType.QR_SCAN,
                null,
                null,
                null,
                " gamjamubwatna://mission/qr/MISSION_QR "
            )
        );

        assertThat(result.verified()).isTrue();
        assertThat(result.completed()).isTrue();
        ArgumentCaptor<UserMission> completionCaptor = ArgumentCaptor.forClass(UserMission.class);
        verify(userMissionRepository).save(completionCaptor.capture());
        assertThat(completionCaptor.getValue().getEvidenceUploadKey()).isNull();
        assertThat(completionCaptor.getValue().getTouristSpot()).isNull();
    }

    @Test
    void rejectsMissingQrCode() {
        Mission mission = mission(1L, "MISSION_QR", MissionStatus.READY, true, MissionType.QR_SCAN);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(qrPolicy(mission, "gamjamubwatna://mission/qr/MISSION_QR")));

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.QR_SCAN, null, null, null, " ")
        ))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("QR 코드를 스캔한 뒤 다시 시도해주세요.");
    }

    @Test
    void rejectsMissingQrPolicy() {
        Mission mission = mission(1L, "MISSION_QR", MissionStatus.READY, true, MissionType.QR_SCAN);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(qrPolicy(mission, null)));

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.QR_SCAN, null, null, null, "gamjamubwatna://mission/qr/MISSION_QR")
        ))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("미션 QR 정책을 확인할 수 없습니다.");
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
    void rejectsPhotoMissionWithAnotherUsersUploadKey() {
        Mission mission = mission(1L, "MISSION_PHOTO", MissionStatus.READY, true, MissionType.PHOTO);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(uploadPolicy(mission)));

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(
                MissionType.PHOTO,
                null,
                null,
                "mission-uploads/2/1/other-users-photo.jpg",
                null
            )
        ))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("서버에서 발급한 업로드 키를 확인해주세요.");
    }

    @Test
    void rejectsPhotoMissionWithFabricatedOwnedUploadKey() {
        Mission mission = mission(1L, "MISSION_PHOTO", MissionStatus.READY, true, MissionType.PHOTO);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(uploadPolicy(mission)));

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(
                MissionType.PHOTO,
                null,
                null,
                "mission-uploads/1/1/missing.jpg",
                null
            )
        ))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("업로드된 이미지를 찾을 수 없습니다.");
    }

    @Test
    void linksVerifiedPhotoMissionEvidenceByIdAfterSpotRename() {
        User user = user(1L);
        Mission mission = mission(1L, "MISSION_PHOTO", MissionStatus.READY, true, MissionType.PHOTO);
        TouristSpot touristSpot = spot(20L, "변경된 관광지 이름", mission.getCityName());
        String uploadKey = "mission-uploads/1/1/test-photo.jpg";
        missionPhotoStorage.put(uploadKey, new byte[] {1, 2, 3});
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(uploadPolicy(mission)));
        mission.assignTargetSpot(touristSpot);
        when(userMissionRepository.save(any(UserMission.class))).thenAnswer(invocation -> invocation.getArgument(0));

        MissionVerifyResponse result = missionService.verifyMission(
            1L,
            1L,
            photoRequest(MissionType.PHOTO, uploadKey)
        );

        assertThat(result.verified()).isTrue();
        ArgumentCaptor<UserMission> completionCaptor = ArgumentCaptor.forClass(UserMission.class);
        verify(userMissionRepository).save(completionCaptor.capture());
        assertThat(completionCaptor.getValue().getEvidenceUploadKey()).isEqualTo(uploadKey);
        assertThat(completionCaptor.getValue().getTouristSpot()).isSameAs(touristSpot);
        ArgumentCaptor<UserVisit> visitCaptor = ArgumentCaptor.forClass(UserVisit.class);
        verify(userVisitRepository).save(visitCaptor.capture());
        assertThat(visitCaptor.getValue().getTouristSpot()).isSameAs(touristSpot);
        assertThat(visitCaptor.getValue().isVisitRewardsProcessed()).isFalse();
        assertThat(visitCaptor.getValue().getDistanceMeters()).isEqualByComparingTo(BigDecimal.ZERO);
        assertThat(visitCaptor.getValue().getVisitedAt())
            .isEqualTo(Instant.parse("2026-07-01T00:00:00Z"));
    }

    @Test
    void doesNotDuplicateTravelRecordWhenPhotoMissionSpotWasAlreadyVisited() {
        User user = user(1L);
        Mission mission = mission(1L, "MISSION_PHOTO", MissionStatus.READY, true, MissionType.PHOTO);
        TouristSpot touristSpot = spot(20L, mission.getSpotName(), mission.getCityName());
        String uploadKey = "mission-uploads/1/1/test-photo.jpg";
        missionPhotoStorage.put(uploadKey, new byte[] {1, 2, 3});
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(uploadPolicy(mission)));
        mission.assignTargetSpot(touristSpot);
        when(userVisitRepository.existsByUserIdAndTouristSpotId(1L, 20L)).thenReturn(true);
        when(userMissionRepository.save(any(UserMission.class))).thenAnswer(invocation -> invocation.getArgument(0));

        missionService.verifyMission(
            1L,
            1L,
            photoRequest(MissionType.PHOTO, uploadKey)
        );

        verify(userVisitRepository).existsByUserIdAndTouristSpotId(1L, 20L);
        verify(userVisitRepository, times(0)).save(any(UserVisit.class));
    }

    @Test
    void verifiesLegacyPhotoOcrMissionWithPhotoAndCurrentLocation() {
        User user = user(1L);
        Mission mission = mission(1L, "MISSION_PHOTO_OCR", MissionStatus.READY, true, MissionType.PHOTO_OCR);
        TouristSpot touristSpot = spot(20L, mission.getSpotName(), mission.getCityName());
        String uploadKey = "mission-uploads/1/1/test-photo.jpg";
        missionPhotoStorage.put(uploadKey, new byte[] {1, 2, 3});
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(uploadPolicy(mission, "하지감자")));
        mission.assignTargetSpot(touristSpot);
        when(userMissionRepository.save(any(UserMission.class))).thenAnswer(invocation -> invocation.getArgument(0));

        MissionVerifyResponse result = missionService.verifyMission(
            1L,
            1L,
            photoRequest(MissionType.PHOTO_OCR, uploadKey)
        );

        assertThat(result.verified()).isTrue();
        assertThat(result.completed()).isTrue();
        ArgumentCaptor<UserMission> completionCaptor = ArgumentCaptor.forClass(UserMission.class);
        verify(userMissionRepository).save(completionCaptor.capture());
        assertThat(completionCaptor.getValue().getEvidenceUploadKey()).isEqualTo(uploadKey);
        assertThat(completionCaptor.getValue().getTouristSpot()).isSameAs(touristSpot);
        verify(locationUsageLogService).recordVisitVerification(
            1L,
            Instant.parse("2026-07-01T00:00:00Z"),
            true
        );
    }

    @Test
    void rejectsPhotoMissionOutsideTouristSpotRadius() {
        Mission mission = mission(1L, "MISSION_PHOTO_OCR", MissionStatus.READY, true, MissionType.PHOTO_OCR);
        TouristSpot touristSpot = spot(20L, mission.getSpotName(), mission.getCityName());
        String uploadKey = "mission-uploads/1/1/test-photo.jpg";
        missionPhotoStorage.put(uploadKey, new byte[] {1, 2, 3});
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(uploadPolicy(mission, "하지감자")));
        mission.assignTargetSpot(touristSpot);

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(
                MissionType.PHOTO_OCR,
                null,
                null,
                uploadKey,
                null,
                new BigDecimal("38.3801000"),
                new BigDecimal("128.6609000")
            )
        ))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("사진 미션 인증 가능 범위를 벗어났습니다.");
        verify(locationUsageLogService).recordVisitVerification(
            1L,
            Instant.parse("2026-07-01T00:00:00Z"),
            false
        );
        verifyNoInteractions(rewardHistoryRepository);
        verify(userMissionRepository, times(0)).save(any(UserMission.class));
    }

    @Test
    void rejectsPhotoMissionWithoutCurrentLocation() {
        Mission mission = mission(1L, "MISSION_PHOTO", MissionStatus.READY, true, MissionType.PHOTO);
        String uploadKey = "mission-uploads/1/1/test-photo.jpg";
        missionPhotoStorage.put(uploadKey, new byte[] {1, 2, 3});
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(uploadPolicy(mission)));

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.PHOTO, null, null, uploadKey, null)
        ))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("사진 미션 인증 위치를 확인할 수 없습니다.");
        verifyNoInteractions(locationUsageLogService);
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

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.QUIZ, "곤드레감자", null, null, null)
        ))
            .isInstanceOf(MissionAlreadyCompletedException.class);
        verifyNoInteractions(rewardHistoryRepository);
        verifyNoInteractions(userCouponRepository);
    }

    @Test
    void issuesCouponForCouponRewardMission() {
        User user = user(1L);
        Mission mission = mission(
            1L,
            "MISSION_COUPON",
            MissionStatus.READY,
            true,
            MissionType.QR_SCAN
        );
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
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(qrPolicy(mission, "expected-qr")));

        missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.QR_SCAN, null, null, null, "expected-qr")
        );

        ArgumentCaptor<UserCoupon> couponCaptor = ArgumentCaptor.forClass(UserCoupon.class);
        verify(userCouponRepository).save(couponCaptor.capture());
        UserCoupon issuedCoupon = couponCaptor.getValue();
        assertThat(issuedCoupon.getCoupon()).isSameAs(coupon);
        assertThat(issuedCoupon.getIssuedAt()).isEqualTo(Instant.parse("2026-07-01T00:00:00Z"));
        assertThat(issuedCoupon.getExpiresAt()).isEqualTo(Instant.parse("2026-07-31T00:00:00Z"));
        assertThat(issuedCoupon.displayStatus(Instant.parse("2026-07-01T00:00:00Z")))
            .isEqualTo(CouponDisplayStatus.AVAILABLE);
        verifyNoInteractions(pushEventPublisher);
    }

    @Test
    void rejectsCouponRewardWithoutCouponMapping() {
        User user = user(1L);
        Mission mission = mission(
            1L,
            "MISSION_COUPON",
            MissionStatus.READY,
            true,
            MissionType.QR_SCAN
        );
        ReflectionTestUtils.setField(mission, "rewardType", MissionRewardType.COUPON);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));
        when(userMissionRepository.existsByUserIdAndMissionId(1L, 1L)).thenReturn(false);
        when(userMissionRepository.save(any(UserMission.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(missionVerificationPolicyRepository.findByMissionId(1L))
            .thenReturn(Optional.of(qrPolicy(mission, "expected-qr")));

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.QR_SCAN, null, null, null, "expected-qr")
        ))
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

        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.QUIZ, "곤드레감자", null, null, null)
        ))
            .isInstanceOf(MissionCompletionException.class);
    }

    @Test
    void locksUnscheduledEventAndRejectsCompletion() {
        Mission mission = mission(
            1L,
            "MISSION_EVENT",
            MissionStatus.READY,
            true,
            MissionGroup.EVENT,
            MissionType.VISIT
        );
        when(userRepository.existsById(1L)).thenReturn(true);
        when(missionRepository.findById(1L)).thenReturn(Optional.of(mission));

        MissionItemResponse item = missionService.getMission(1L, 1L);

        assertThat(item.active()).isFalse();
        assertThat(item.status()).isEqualTo(MissionStatus.LOCKED);
        assertThat(item.progress()).isZero();
        assertThat(item.periodStartsAt()).isNull();
        assertThat(item.periodEndsAt()).isNull();

        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        assertThatThrownBy(() -> missionService.verifyMission(
            1L,
            1L,
            new MissionVerifyRequest(MissionType.VISIT, null, null, null, null)
        ))
            .isInstanceOf(MissionCompletionException.class)
            .hasMessage("아직 완료할 수 없는 미션입니다.");
        verifyNoInteractions(rewardHistoryRepository);
    }

    @Test
    void rejectsDeletedUser() {
        when(userRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> missionService.getMissions(99L))
            .isInstanceOf(MissionAuthenticationException.class);
    }

    @Test
    void hidesUnlinkedPhotoMissionAndRejectsDirectVerification() {
        Mission photo = mission(1L, "UNLINKED_PHOTO", MissionStatus.READY, true, MissionType.PHOTO);
        ReflectionTestUtils.setField(photo, "targetSpot", null);
        when(userRepository.existsById(1L)).thenReturn(true);
        when(missionRepository.findAllByOrderByDisplayOrderAsc()).thenReturn(List.of(photo));
        assertThat(missionService.getMissions(1L).missions()).isEmpty();
        when(missionRepository.findById(1L)).thenReturn(Optional.of(photo));
        assertThat(missionService.getMission(1L, 1L).active()).isFalse();
        assertThat(missionService.getMission(1L, 1L).status()).isEqualTo(MissionStatus.LOCKED);
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        assertThatThrownBy(() -> missionService.verifyMission(1L, 1L,
            photoRequest(MissionType.PHOTO, "mission-uploads/1/1/photo.jpg")))
            .isInstanceOf(MissionVerificationException.class)
            .hasMessage("사진 미션 관광지 정보를 확인할 수 없습니다.");
        verifyNoInteractions(rewardHistoryRepository);
        verify(userMissionRepository, times(0)).save(any(UserMission.class));
    }

    @Test
    void hidesPhotoMissionWhenItsTargetIsDeactivated() {
        Mission photo = mission(1L, "INACTIVE_TARGET", MissionStatus.READY, true, MissionType.PHOTO);
        ReflectionTestUtils.setField(photo.getTargetSpot(), "active", false);
        when(userRepository.existsById(1L)).thenReturn(true);
        when(missionRepository.findAllByOrderByDisplayOrderAsc()).thenReturn(List.of(photo));
        assertThat(missionService.getMissions(1L).missions()).isEmpty();
        when(userRepository.findById(1L)).thenReturn(Optional.of(user(1L)));
        when(missionRepository.findById(1L)).thenReturn(Optional.of(photo));
        assertThatThrownBy(() -> missionService.verifyMission(1L, 1L,
            photoRequest(MissionType.PHOTO, "mission-uploads/1/1/photo.jpg")))
            .isInstanceOf(MissionVerificationException.class);
        verifyNoInteractions(rewardHistoryRepository);
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
        return mission(id, code, status, active, MissionGroup.JUMSOONI, type);
    }

    private Mission mission(
        Long id,
        String code,
        MissionStatus status,
        boolean active,
        MissionGroup group,
        MissionType type
    ) {
        Mission mission = new Mission(
            code,
            group,
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
        if (mission.requiresPhotoTarget()) {
            mission.assignTargetSpot(spot(20L, mission.getSpotName(), mission.getCityName()));
        }
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
        assertThat(rewardHistory.getSourcePeriod()).isEqualTo(MissionPeriod.ONE_TIME_KEY);
        assertThat(rewardHistory.getCreatedAt()).isEqualTo(Instant.parse("2026-07-01T00:00:00Z"));
    }

    private MissionService missionService(Instant now) {
        return new MissionService(
            missionRepository,
            missionVerificationPolicyRepository,
            userMissionRepository,
            rewardHistoryRepository,
            couponRepository,
            userCouponRepository,
            userRepository,
            missionEvidenceValidator,
            missionPhotoStorage,
            userVisitRepository,
            new VisitDistancePolicy(),
            locationUsageLogService,
            Clock.fixed(now, ZoneOffset.UTC)
        );
    }

    private MissionVerifyRequest photoRequest(MissionType type, String uploadKey) {
        return new MissionVerifyRequest(
            type,
            null,
            null,
            uploadKey,
            null,
            new BigDecimal("37.3801000"),
            new BigDecimal("128.6609000")
        );
    }

    private TouristSpot spot(Long id, String name, String cityName) {
        TouristSpot spot = new TouristSpot(
            "spot-" + id,
            12,
            name,
            SpotCategory.POTATO_TOUR,
            new BigDecimal("37.3801000"),
            new BigDecimal("128.6609000"),
            "강원특별자치도 " + cityName,
            cityName,
            null,
            "감자",
            Instant.parse("2026-07-01T00:00:00Z")
        );
        ReflectionTestUtils.setField(spot, "id", id);
        return spot;
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

        @Override
        public void deleteAllByUserId(Long userId) {
            files.keySet().removeIf(key -> key.startsWith("mission-uploads/" + userId + "/"));
        }
    }
}
