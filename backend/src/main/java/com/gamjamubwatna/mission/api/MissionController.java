package com.gamjamubwatna.mission.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.mission.application.MissionAlreadyCompletedException;
import com.gamjamubwatna.mission.application.MissionAuthenticationException;
import com.gamjamubwatna.mission.application.MissionCompletionException;
import com.gamjamubwatna.mission.application.MissionNotFoundException;
import com.gamjamubwatna.mission.application.MissionService;
import com.gamjamubwatna.mission.application.MissionVerificationException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/missions")
public class MissionController {

    private static final Pattern USER_PRINCIPAL_PATTERN = Pattern.compile("^user:([1-9]\\d*)$");

    private final MissionService missionService;

    public MissionController(MissionService missionService) {
        this.missionService = missionService;
    }

    // 미션 탭 진입 시 로그인 사용자의 미션 목록과 완료 상태를 함께 내려준다.
    @GetMapping
    public ResponseEntity<AuthApiResponse<MissionListResponse>> getMissions(
        Authentication authentication
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                missionService.getMissions(userId(authentication))
            ));
        } catch (MissionAuthenticationException exception) {
            return unauthorized();
        }
    }

    // 미션 카드 선택 시 상세 모달에 필요한 설명, 대사, 보상 정보를 조회한다.
    @GetMapping("/{missionId}")
    public ResponseEntity<AuthApiResponse<MissionItemResponse>> getMission(
        Authentication authentication,
        @PathVariable Long missionId
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                missionService.getMission(userId(authentication), missionId)
            ));
        } catch (MissionAuthenticationException exception) {
            return unauthorized();
        } catch (MissionNotFoundException exception) {
            return notFound(exception.getMessage());
        }
    }

    // MVP에서는 센서 검증 전까지 활성 미션의 중복 완료 여부만 서버에서 확정한다.
    @PostMapping("/{missionId}/complete")
    public ResponseEntity<AuthApiResponse<MissionCompleteResponse>> completeMission(
        Authentication authentication,
        @PathVariable Long missionId
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                missionService.completeMission(userId(authentication), missionId)
            ));
        } catch (MissionAuthenticationException exception) {
            return unauthorized();
        } catch (MissionNotFoundException exception) {
            return notFound(exception.getMessage());
        } catch (MissionAlreadyCompletedException exception) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(AuthApiResponse.failure(exception.getMessage()));
        } catch (MissionCompletionException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(AuthApiResponse.failure(exception.getMessage()));
        } catch (org.springframework.dao.DataIntegrityViolationException exception) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(AuthApiResponse.failure("이미 완료한 미션입니다."));
        }
    }

    // 타입별 입력값을 서버에서 검증한 뒤 성공한 경우에만 미션 완료와 보상 지급을 확정한다.
    @PostMapping("/{missionId}/verify")
    public ResponseEntity<AuthApiResponse<MissionVerifyResponse>> verifyMission(
        Authentication authentication,
        @PathVariable Long missionId,
        @RequestBody MissionVerifyRequest request
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                missionService.verifyMission(userId(authentication), missionId, request)
            ));
        } catch (MissionAuthenticationException exception) {
            return unauthorized();
        } catch (MissionNotFoundException exception) {
            return notFound(exception.getMessage());
        } catch (MissionAlreadyCompletedException exception) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(AuthApiResponse.failure(exception.getMessage()));
        } catch (MissionVerificationException | MissionCompletionException exception) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                .body(AuthApiResponse.failure(exception.getMessage()));
        } catch (org.springframework.dao.DataIntegrityViolationException exception) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(AuthApiResponse.failure("이미 완료한 미션입니다."));
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
