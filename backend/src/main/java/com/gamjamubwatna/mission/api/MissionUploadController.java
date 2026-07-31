package com.gamjamubwatna.mission.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.mission.application.MissionAuthenticationException;
import com.gamjamubwatna.mission.application.MissionNotFoundException;
import com.gamjamubwatna.mission.application.MissionUploadException;
import com.gamjamubwatna.mission.application.MissionUploadService;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/mission-uploads")
public class MissionUploadController {

    private static final Pattern USER_PRINCIPAL_PATTERN = Pattern.compile("^user:([1-9]\\d*)$");

    private final MissionUploadService missionUploadService;

    public MissionUploadController(MissionUploadService missionUploadService) {
        this.missionUploadService = missionUploadService;
    }

    // 사진/OCR 미션에서 검증 요청에 사용할 서버 발급 uploadKey를 만든다.
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<AuthApiResponse<MissionUploadResponse>> uploadMissionPhoto(
        Authentication authentication,
        @RequestParam Long missionId,
        @RequestParam MultipartFile file
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                missionUploadService.issueUploadKey(userId(authentication), missionId, file)
            ));
        } catch (MissionAuthenticationException exception) {
            return unauthorized();
        } catch (MissionNotFoundException exception) {
            return notFound(exception.getMessage());
        } catch (MissionUploadException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(AuthApiResponse.failure(exception.getMessage()));
        }
    }

    private Long userId(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            throw invalidPrincipal();
        }

        Matcher matcher = USER_PRINCIPAL_PATTERN.matcher(authentication.getName());
        if (!matcher.matches()) {
            throw invalidPrincipal();
        }

        try {
            return Long.parseLong(matcher.group(1));
        } catch (NumberFormatException exception) {
            throw invalidPrincipal();
        }
    }

    private MissionAuthenticationException invalidPrincipal() {
        return new MissionAuthenticationException("유효하지 않은 인증 사용자입니다.");
    }

    private <T> ResponseEntity<AuthApiResponse<T>> unauthorized() {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
            .body(AuthApiResponse.failure("인증 정보를 확인할 수 없습니다."));
    }

    private <T> ResponseEntity<AuthApiResponse<T>> notFound(String message) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(AuthApiResponse.failure(message));
    }
}
