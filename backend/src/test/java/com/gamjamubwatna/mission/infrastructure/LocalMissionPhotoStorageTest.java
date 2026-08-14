package com.gamjamubwatna.mission.infrastructure;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.gamjamubwatna.mission.application.MissionUploadException;
import com.gamjamubwatna.mission.application.StoredMissionPhoto;
import java.nio.file.Files;
import java.nio.file.Path;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.io.TempDir;
import org.springframework.mock.web.MockMultipartFile;

class LocalMissionPhotoStorageTest {

    @TempDir
    private Path tempDirectory;

    @Test
    void storesMissionPhotoInLocalDirectory() throws Exception {
        LocalMissionPhotoStorage storage = new LocalMissionPhotoStorage(tempDirectory.toString());
        MockMultipartFile file = new MockMultipartFile(
            "file",
            "receipt.jpg",
            "image/jpeg",
            new byte[] {1, 2, 3}
        );

        StoredMissionPhoto storedPhoto = storage.store(
            "mission-uploads/1/1002/test-receipt.jpg",
            "receipt.jpg",
            "image/jpeg",
            file
        );

        Path savedFile = tempDirectory.resolve(storedPhoto.uploadKey());
        assertThat(Files.exists(savedFile)).isTrue();
        assertThat(Files.readAllBytes(savedFile)).containsExactly(1, 2, 3);
        assertThat(storedPhoto.fileName()).isEqualTo("receipt.jpg");
        assertThat(storedPhoto.contentType()).isEqualTo("image/jpeg");
        assertThat(storedPhoto.size()).isEqualTo(3);

        assertThat(storage.read(storedPhoto.uploadKey()).bytes()).containsExactly(1, 2, 3);
    }

    @Test
    void rejectsEscapedStoragePath() {
        LocalMissionPhotoStorage storage = new LocalMissionPhotoStorage(tempDirectory.toString());
        MockMultipartFile file = new MockMultipartFile(
            "file",
            "receipt.jpg",
            "image/jpeg",
            new byte[] {1}
        );

        assertThatThrownBy(() -> storage.store(
            "../escaped.jpg",
            "receipt.jpg",
            "image/jpeg",
            file
        ))
            .isInstanceOf(MissionUploadException.class)
            .hasMessage("이미지 저장 경로를 확인할 수 없습니다.");
    }

    @Test
    void deletesOnlyTheWithdrawnUsersMissionPhotos() throws Exception {
        LocalMissionPhotoStorage storage = new LocalMissionPhotoStorage(tempDirectory.toString());
        MockMultipartFile file = new MockMultipartFile(
            "file",
            "receipt.jpg",
            "image/jpeg",
            new byte[] {1, 2, 3}
        );
        storage.store("mission-uploads/1/1002/first.jpg", "first.jpg", "image/jpeg", file);
        storage.store("mission-uploads/1/1003/second.jpg", "second.jpg", "image/jpeg", file);
        storage.store("mission-uploads/2/1002/other.jpg", "other.jpg", "image/jpeg", file);

        storage.deleteAllByUserId(1L);

        assertThat(Files.exists(tempDirectory.resolve("mission-uploads/1"))).isFalse();
        assertThat(Files.exists(tempDirectory.resolve("mission-uploads/2/1002/other.jpg"))).isTrue();
        storage.deleteAllByUserId(1L);
    }
}
