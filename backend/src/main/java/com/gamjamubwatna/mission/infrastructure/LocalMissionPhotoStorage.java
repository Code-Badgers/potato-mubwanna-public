package com.gamjamubwatna.mission.infrastructure;

import com.gamjamubwatna.mission.application.MissionPhotoStorage;
import com.gamjamubwatna.mission.application.MissionUploadException;
import com.gamjamubwatna.mission.application.StoredMissionPhoto;
import com.gamjamubwatna.mission.application.StoredMissionPhotoFile;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

@Component
public class LocalMissionPhotoStorage implements MissionPhotoStorage {

    private final Path rootDirectory;

    public LocalMissionPhotoStorage(
        @Value("${mission.upload.local-dir}") String localDirectory
    ) {
        this.rootDirectory = Path.of(localDirectory).toAbsolutePath().normalize();
    }

    @Override
    public StoredMissionPhoto store(
        String uploadKey,
        String fileName,
        String contentType,
        MultipartFile file
    ) {
        Path target = targetPath(uploadKey);

        try {
            Files.createDirectories(target.getParent());
            try (InputStream inputStream = file.getInputStream()) {
                Files.copy(inputStream, target, StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (IOException exception) {
            throw new MissionUploadException("이미지 저장에 실패했습니다.");
        }

        return new StoredMissionPhoto(
            uploadKey,
            fileName,
            contentType,
            file.getSize()
        );
    }

    @Override
    public StoredMissionPhotoFile read(String uploadKey) {
        Path target = targetPath(uploadKey);
        if (!Files.exists(target) || !Files.isRegularFile(target)) {
            throw new MissionUploadException("업로드된 이미지를 찾을 수 없습니다.");
        }
        try {
            return new StoredMissionPhotoFile(uploadKey, Files.readAllBytes(target));
        } catch (IOException exception) {
            throw new MissionUploadException("이미지 파일을 읽지 못했습니다.");
        }
    }

    private Path targetPath(String uploadKey) {
        Path target = rootDirectory.resolve(uploadKey).normalize();
        if (!target.startsWith(rootDirectory)) {
            throw new MissionUploadException("이미지 저장 경로를 확인할 수 없습니다.");
        }
        return target;
    }
}
