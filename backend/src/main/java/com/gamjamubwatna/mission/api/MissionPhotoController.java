package com.gamjamubwatna.mission.api;

import com.gamjamubwatna.mission.application.MissionPhotoNotFoundException;
import com.gamjamubwatna.mission.application.MissionPhotoQueryService;
import com.gamjamubwatna.mission.application.StoredMissionPhotoFile;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/mission-uploads/completions")
public class MissionPhotoController {

    private static final Pattern USER_PRINCIPAL_PATTERN = Pattern.compile("^user:([1-9]\\d*)$");

    private final MissionPhotoQueryService missionPhotoQueryService;

    public MissionPhotoController(MissionPhotoQueryService missionPhotoQueryService) {
        this.missionPhotoQueryService = missionPhotoQueryService;
    }

    // 여행기록에 연결된 사진을 완료 기록 소유자에게만 반환한다.
    @GetMapping("/{userMissionId}/image")
    public ResponseEntity<byte[]> getCompletedMissionPhoto(
        Authentication authentication,
        @PathVariable Long userMissionId
    ) {
        Long userId = userId(authentication);
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        try {
            StoredMissionPhotoFile photo = missionPhotoQueryService
                .getCompletedMissionPhoto(userId, userMissionId);
            return ResponseEntity.ok()
                .cacheControl(CacheControl.noStore())
                .contentType(MediaType.APPLICATION_OCTET_STREAM)
                .body(photo.bytes());
        } catch (MissionPhotoNotFoundException exception) {
            return ResponseEntity.notFound().build();
        }
    }

    private Long userId(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            return null;
        }
        Matcher matcher = USER_PRINCIPAL_PATTERN.matcher(authentication.getName());
        if (!matcher.matches()) {
            return null;
        }
        try {
            return Long.parseLong(matcher.group(1));
        } catch (NumberFormatException exception) {
            return null;
        }
    }
}
