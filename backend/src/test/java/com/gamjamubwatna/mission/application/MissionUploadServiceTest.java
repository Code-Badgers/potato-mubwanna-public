package com.gamjamubwatna.mission.application;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.mission.api.MissionUploadResponse;
import com.gamjamubwatna.mission.domain.MissionRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockMultipartFile;

class MissionUploadServiceTest {

    private UserRepository userRepository;
    private MissionRepository missionRepository;
    private MissionPhotoStorage missionPhotoStorage;
    private MissionUploadService missionUploadService;

    @BeforeEach
    void setUp() {
        userRepository = mock(UserRepository.class);
        missionRepository = mock(MissionRepository.class);
        missionPhotoStorage = (uploadKey, fileName, contentType, file) ->
            new StoredMissionPhoto(uploadKey, fileName, contentType, file.getSize());
        missionUploadService = new MissionUploadService(
            userRepository,
            missionRepository,
            missionPhotoStorage,
            Clock.fixed(Instant.parse("2026-07-29T07:30:00Z"), ZoneOffset.UTC)
        );
    }

    @Test
    void issuesUploadKeyForImageFile() {
        when(userRepository.existsById(1L)).thenReturn(true);
        when(missionRepository.existsById(1002L)).thenReturn(true);

        MissionUploadResponse response = missionUploadService.issueUploadKey(
            1L,
            1002L,
            image("receipt.jpg", "image/jpeg", 1024)
        );

        assertThat(response.uploadKey())
            .startsWith("mission-uploads/1/1002/20260729T073000Z-")
            .endsWith("-receipt.jpg");
        assertThat(response.fileName()).isEqualTo("receipt.jpg");
        assertThat(response.contentType()).isEqualTo("image/jpeg");
        assertThat(response.size()).isEqualTo(1024);
        assertThat(response.expiresAt()).isEqualTo(Instant.parse("2026-07-29T08:30:00Z"));
    }

    @Test
    void rejectsNonImageFile() {
        when(userRepository.existsById(1L)).thenReturn(true);
        when(missionRepository.existsById(1002L)).thenReturn(true);

        assertThatThrownBy(() -> missionUploadService.issueUploadKey(
            1L,
            1002L,
            image("memo.txt", "text/plain", 100)
        ))
            .isInstanceOf(MissionUploadException.class)
            .hasMessage("이미지 파일만 업로드할 수 있습니다.");
    }

    @Test
    void rejectsOversizedFile() {
        when(userRepository.existsById(1L)).thenReturn(true);
        when(missionRepository.existsById(1002L)).thenReturn(true);

        assertThatThrownBy(() -> missionUploadService.issueUploadKey(
            1L,
            1002L,
            image("large.png", "image/png", 5 * 1024 * 1024 + 1)
        ))
            .isInstanceOf(MissionUploadException.class)
            .hasMessage("이미지는 5MB 이하만 업로드할 수 있습니다.");
    }

    @Test
    void rejectsMissingMission() {
        when(userRepository.existsById(1L)).thenReturn(true);
        when(missionRepository.existsById(404L)).thenReturn(false);

        assertThatThrownBy(() -> missionUploadService.issueUploadKey(
            1L,
            404L,
            image("receipt.jpg", "image/jpeg", 1024)
        ))
            .isInstanceOf(MissionNotFoundException.class)
            .hasMessage("미션을 찾을 수 없습니다.");
    }

    private MockMultipartFile image(String name, String contentType, int size) {
        return new MockMultipartFile(
            "file",
            name,
            contentType,
            new byte[size]
        );
    }
}
