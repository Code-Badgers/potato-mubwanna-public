package com.gamjamubwatna.mission.application;

import com.gamjamubwatna.auth.domain.UserRepository;
import com.gamjamubwatna.mission.api.MissionUploadResponse;
import com.gamjamubwatna.mission.domain.MissionRepository;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class MissionUploadService {

    private static final long MAX_IMAGE_SIZE_BYTES = 5L * 1024L * 1024L;
    private static final Duration UPLOAD_KEY_TTL = Duration.ofHours(1);
    private static final Set<String> ALLOWED_CONTENT_TYPES = Set.of(
        "image/jpeg",
        "image/png",
        "image/webp"
    );
    private static final DateTimeFormatter KEY_TIMESTAMP_FORMATTER =
        DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss'Z'")
            .withLocale(Locale.ROOT)
            .withZone(ZoneOffset.UTC);

    private final UserRepository userRepository;
    private final MissionRepository missionRepository;
    private final Clock clock;

    @Autowired
    public MissionUploadService(
        UserRepository userRepository,
        MissionRepository missionRepository
    ) {
        this(userRepository, missionRepository, Clock.systemUTC());
    }

    MissionUploadService(
        UserRepository userRepository,
        MissionRepository missionRepository,
        Clock clock
    ) {
        this.userRepository = userRepository;
        this.missionRepository = missionRepository;
        this.clock = clock;
    }

    public MissionUploadResponse issueUploadKey(
        Long userId,
        Long missionId,
        MultipartFile file
    ) {
        validateUser(userId);
        validateMission(missionId);
        validateFile(file);

        Instant now = Instant.now(clock);
        String fileName = sanitizeFileName(file.getOriginalFilename());
        String contentType = file.getContentType();
        String uploadKey = uploadKey(userId, missionId, fileName, now);
        return new MissionUploadResponse(
            uploadKey,
            fileName,
            contentType,
            file.getSize(),
            now.plus(UPLOAD_KEY_TTL)
        );
    }

    private void validateUser(Long userId) {
        if (userId == null || !userRepository.existsById(userId)) {
            throw new MissionAuthenticationException("사용자를 찾을 수 없습니다.");
        }
    }

    private void validateMission(Long missionId) {
        if (missionId == null || !missionRepository.existsById(missionId)) {
            throw new MissionNotFoundException("미션을 찾을 수 없습니다.");
        }
    }

    private void validateFile(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new MissionUploadException("업로드할 이미지를 선택해주세요.");
        }
        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_CONTENT_TYPES.contains(contentType)) {
            throw new MissionUploadException("이미지 파일만 업로드할 수 있습니다.");
        }
        if (file.getSize() > MAX_IMAGE_SIZE_BYTES) {
            throw new MissionUploadException("이미지는 5MB 이하만 업로드할 수 있습니다.");
        }
    }

    private String sanitizeFileName(String originalFilename) {
        if (originalFilename == null || originalFilename.isBlank()) {
            return "mission-photo.jpg";
        }
        return originalFilename
            .replace("\\", "/")
            .substring(originalFilename.replace("\\", "/").lastIndexOf('/') + 1)
            .replaceAll("[^A-Za-z0-9._-]", "_");
    }

    private String uploadKey(
        Long userId,
        Long missionId,
        String fileName,
        Instant now
    ) {
        return "mission-uploads/%d/%d/%s-%s-%s".formatted(
            userId,
            missionId,
            KEY_TIMESTAMP_FORMATTER.format(now),
            UUID.randomUUID().toString().substring(0, 8),
            fileName
        );
    }
}
