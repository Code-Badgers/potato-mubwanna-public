package com.gamjamubwatna.mission.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.mission.domain.MissionPeriod;
import com.gamjamubwatna.mission.domain.UserMission;
import com.gamjamubwatna.mission.domain.UserMissionRepository;
import java.time.Instant;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class MissionPhotoQueryServiceTest {

    private UserMissionRepository userMissionRepository;
    private MissionPhotoStorage missionPhotoStorage;
    private MissionPhotoQueryService missionPhotoQueryService;

    @BeforeEach
    void setUp() {
        userMissionRepository = mock(UserMissionRepository.class);
        missionPhotoStorage = mock(MissionPhotoStorage.class);
        missionPhotoQueryService = new MissionPhotoQueryService(
            userMissionRepository,
            missionPhotoStorage
        );
    }

    @Test
    void returnsOnlyOwnedCompletionEvidence() {
        String uploadKey = "mission-uploads/1/20/photo.jpg";
        UserMission completion = completion(uploadKey);
        when(userMissionRepository.findOwnedEvidenceCompletion(31L, 1L))
            .thenReturn(Optional.of(completion));
        when(missionPhotoStorage.read(uploadKey))
            .thenReturn(new StoredMissionPhotoFile(uploadKey, new byte[] {1, 2, 3}));

        StoredMissionPhotoFile result = missionPhotoQueryService
            .getCompletedMissionPhoto(1L, 31L);

        assertThat(result.bytes()).containsExactly(1, 2, 3);
    }

    @Test
    void hidesMissingOrOtherUsersCompletionAsNotFound() {
        when(userMissionRepository.findOwnedEvidenceCompletion(31L, 2L))
            .thenReturn(Optional.empty());

        assertThatThrownBy(() -> missionPhotoQueryService.getCompletedMissionPhoto(2L, 31L))
            .isInstanceOf(MissionPhotoNotFoundException.class);
    }

    @Test
    void hidesMissingStorageFileAsNotFound() {
        String uploadKey = "mission-uploads/1/20/missing.jpg";
        when(userMissionRepository.findOwnedEvidenceCompletion(31L, 1L))
            .thenReturn(Optional.of(completion(uploadKey)));
        when(missionPhotoStorage.read(uploadKey))
            .thenThrow(new MissionUploadException("업로드된 이미지를 찾을 수 없습니다."));

        assertThatThrownBy(() -> missionPhotoQueryService.getCompletedMissionPhoto(1L, 31L))
            .isInstanceOf(MissionPhotoNotFoundException.class);
    }

    private UserMission completion(String uploadKey) {
        return new UserMission(
            null,
            null,
            Instant.parse("2026-08-04T00:00:00Z"),
            MissionPeriod.ONE_TIME_KEY,
            uploadKey,
            null
        );
    }
}
