package com.gamjamubwatna.user.api;

import com.gamjamubwatna.auth.api.AuthApiResponse;
import com.gamjamubwatna.user.application.UserActivitySummaryService;
import com.gamjamubwatna.user.application.UserProfileAuthenticationException;
import com.gamjamubwatna.user.application.UserProfileService;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/users")
public class UserController {

    private static final Pattern USER_PRINCIPAL_PATTERN = Pattern.compile("^user:([1-9]\\d*)$");

    private final UserProfileService userProfileService;
    private final UserActivitySummaryService userActivitySummaryService;

    public UserController(
        UserProfileService userProfileService,
        UserActivitySummaryService userActivitySummaryService
    ) {
        this.userProfileService = userProfileService;
        this.userActivitySummaryService = userActivitySummaryService;
    }

    // 로그인 세션을 복원한 사용자가 마이페이지에서 자신의 저장된 계정 정보를 조회한다.
    @GetMapping("/me")
    public ResponseEntity<AuthApiResponse<UserProfileResponse>> getMyProfile(Authentication authentication) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                userProfileService.getProfile(userId(authentication))
            ));
        } catch (UserProfileAuthenticationException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(AuthApiResponse.failure("인증 정보를 확인할 수 없습니다."));
        }
    }

    // 로그인 사용자가 마이페이지에서 누적 걸음, 스탬프, 감자 수집 결과를 확인한다.
    @GetMapping("/me/activity-summary")
    public ResponseEntity<AuthApiResponse<UserActivitySummaryResponse>> getMyActivitySummary(
        Authentication authentication
    ) {
        try {
            return ResponseEntity.ok(AuthApiResponse.success(
                userActivitySummaryService.getActivitySummary(userId(authentication))
            ));
        } catch (UserProfileAuthenticationException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(AuthApiResponse.failure("인증 정보를 확인할 수 없습니다."));
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

    private UserProfileAuthenticationException invalidPrincipal() {
        return new UserProfileAuthenticationException("유효하지 않은 인증 사용자입니다.");
    }
}
